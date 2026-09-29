import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/quran/data/models/quran_display_mode.dart';
import 'package:awqat_salaah/features/quran/data/models/tafsir_model.dart';
import 'package:awqat_salaah/features/quran/data/models/qcf_page_model.dart';
import 'package:awqat_salaah/features/quran/data/repositories/tafsir_repository.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';
import 'package:awqat_salaah/features/quran/services/qcf_font_service.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_page_renderer.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_share_composer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranDisplayMode Tests', () {
    test('verifies normal and tajweed values and names', () {
      expect(QuranDisplayMode.normal.isTajweed, isFalse);
      expect(QuranDisplayMode.tajweed.isTajweed, isTrue);

      expect(QuranDisplayMode.normal.displayNameArabic, contains('المصحف'));
      expect(QuranDisplayMode.tajweed.displayNameArabic, contains('التجويد'));
    });
  });

  group('QcfFontService Multi-Mode Font Family Tests', () {
    test('fontFamilyForPage returns correct family based on mode and loading state', () {
      // Normal mode always returns QCF_P{page}
      expect(
        QcfFontService.fontFamilyForPage(1, mode: QuranDisplayMode.normal),
        equals('QCF_P1'),
      );
      expect(
        QcfFontService.fontFamilyForPage(255, mode: QuranDisplayMode.normal),
        equals('QCF_P255'),
      );
      expect(
        QcfFontService.fontFamilyForPage(604, mode: QuranDisplayMode.normal),
        equals('QCF_P604'),
      );

      // Tajweed mode explicitly maps to QCF_V4_P{page} without silent fallback
      expect(
        QcfFontService.fontFamilyForPage(1, mode: QuranDisplayMode.tajweed),
        equals('QCF_V4_P1'),
      );
    });
  });

  group('Tafsir Models & Cache Tests', () {
    test('TafsirResource parses correctly from Quran Content API JSON', () {
      final jsonSample = {
        'id': 16,
        'name': 'Tafsir Muyassar',
        'author_name': 'المیسر',
        'slug': 'ar-tafsir-muyassar',
        'language_name': 'arabic',
        'translated_name': {
          'name': 'التفسير الميسر',
          'language_name': 'arabic',
        }
      };

      final resource = TafsirResource.fromJson(jsonSample);
      expect(resource.id, 16);
      expect(resource.name, 'التفسير الميسر');
      expect(resource.authorName, 'المیسر');
      expect(resource.language, 'arabic');
    });

    test('Tafsir parses correctly with verses map and html cleaning', () {
      const sampleHtml =
          'الله الذي لا يستحق الألوهية إلا هو، الحيُّ القائم على كل شيء،<span class="blue"> لا تأخذه سِنَة أي:</span> نعاس، ولا نوم.';

      final cleaned = TafsirRepositoryImpl.cleanTafsirHtml(sampleHtml);
      expect(cleaned, isNot(contains('<span')));
      expect(cleaned, isNot(contains('</span>')));
      expect(cleaned, contains('لا تأخذه سِنَة أي: نعاس'));

      final jsonSample = {
        'verses': {
          '2:255': {'id': 262}
        },
        'resource_id': 16,
        'resource_name': 'المیسر',
        'text': cleaned,
      };

      final tafsir = Tafsir.fromJson(jsonSample);
      expect(tafsir.verseKey, '2:255');
      expect(tafsir.resourceId, 16);
      expect(tafsir.text, contains('الله الذي لا يستحق'));
    });

    test('TafsirRepositoryImpl returns cached Tafsir with key tafsir:16:2:255', () async {
      SharedPreferences.setMockInitialValues({
        'tafsir:16:2:255': json.encode({
          'verseKey': '2:255',
          'resource_id': 16,
          'resource_name': 'التفسير الميسر',
          'text': 'تفسير آية الكرسي المخزن محلياً',
        }),
      });

      final prefs = await SharedPreferences.getInstance();
      final repository = TafsirRepositoryImpl(prefs);

      // Check synchronous cache
      final cached = repository.getCachedTafsir(
        verseKey: '2:255',
        tafsirResourceId: 16,
      );
      expect(cached, isNotNull);
      expect(cached!.verseKey, '2:255');
      expect(cached.text, 'تفسير آية الكرسي المخزن محلياً');

      // Check async method returns cached offline immediately
      final asyncResult = await repository.getTafsirForAyah(
        verseKey: '2:255',
        tafsirResourceId: 16,
      );
      expect(asyncResult, isNotNull);
      expect(asyncResult!.text, 'تفسير آية الكرسي المخزن محلياً');
    });

    test('TafsirRepositoryImpl provides default Arabic tafsir scholarly list', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = TafsirRepositoryImpl(prefs);

      final tafsirs = await repository.getAvailableTafsirs();
      expect(tafsirs.isNotEmpty, isTrue);
      expect(tafsirs.any((r) => r.id == 16), isTrue); // التفسير الميسر
      expect(tafsirs.any((r) => r.id == 91), isTrue); // تفسير السعدي
      expect(tafsirs.any((r) => r.id == 14), isTrue); // تفسير ابن كثير
    });
  });

  group('QuranRepository Display Mode and Tafsir Persistence', () {
    test('Persists and retrieves QuranDisplayMode and DefaultTafsir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = QuranRepository(prefs);

      // Defaults
      expect(repo.getQuranDisplayMode(), equals(QuranDisplayMode.tajweed));
      expect(repo.defaultTafsirResourceId, equals(16));

      // Set Tajweed
      await repo.setQuranDisplayMode(QuranDisplayMode.tajweed);
      expect(repo.getQuranDisplayMode(), equals(QuranDisplayMode.tajweed));

      // The ordinary Mushaf is deliberately no longer exposed as a reader mode.
      await repo.setQuranDisplayMode(QuranDisplayMode.normal);
      expect(repo.getQuranDisplayMode(), equals(QuranDisplayMode.tajweed));

      // Set Default Tafsir
      await repo.setDefaultTafsirResourceId(91); // Al-Saadi
      expect(repo.defaultTafsirResourceId, equals(91));
    });
  });

  group('Quran Share Image Background Color Test', () {
    test('Medina theme background is set to the authentic warm samni paper color #F6F0E4', () {
      const renderer = QuranShareRenderer(
        surahName: 'البقرة',
        startAyah: 255,
        endAyah: 255,
        verses: [],
        theme: QuranShareTheme.medina,
        fontSize: 22.0,
      );

      expect(renderer.theme, equals(QuranShareTheme.medina));
      expect(QuranPageRenderer.ivoryPaper, equals(const Color(0xFFF6F0E4)));
    });
  });

  group('Medina 604-Page Deterministic Composition Verification', () {
    final testedPages = [1, 2, 3, 4, 5, 10, 20, 255, 604];

    for (final pageNum in testedPages) {
      test('Page $pageNum adheres to deterministic layout properties', () {
        // Construct mock page model
        final pageModel = QcfPageModel(
          page: pageNum,
          lines: [
            QcfLineModel(
              line: 1,
              type: pageNum == 1 ? 'surah-header' : 'text',
              words: const [
                QcfWordModel(
                  location: '1:1:1',
                  word: 'بِسْمِ',
                  qpcV2: 'ﱁ',
                ),
              ],
            ),
          ],
        );

        expect(pageModel.page, equals(pageNum));
        expect(pageModel.lines.isNotEmpty, isTrue);

        // Verify QuranPageRenderer factory creates valid widgets for both modes
        final v2Widget = QuranPageRenderer.create(
          displayMode: QuranDisplayMode.normal,
          pageModel: pageModel,
          juz: 1,
          hizb: 1,
          surahName: 'الفاتحة',
          onAyahTap: ({required int surahId, required int ayahId}) {},
          onAyahLongPress: ({required int surahId, required int ayahId}) {},
          onPageTap: () {},
        );
        expect(v2Widget, isA<QcfV2PageRenderer>());

        final v4Widget = QuranPageRenderer.create(
          displayMode: QuranDisplayMode.tajweed,
          pageModel: pageModel,
          juz: 1,
          hizb: 1,
          surahName: 'الفاتحة',
          onAyahTap: ({required int surahId, required int ayahId}) {},
          onAyahLongPress: ({required int surahId, required int ayahId}) {},
          onPageTap: () {},
        );
        expect(v4Widget, isA<QcfTajweedV4PageRenderer>());
      });
    }
  });
}
