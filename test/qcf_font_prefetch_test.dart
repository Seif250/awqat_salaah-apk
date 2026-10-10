import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/data/models/quran_display_mode.dart';
import 'package:awqat_salaah/features/quran/services/qcf_font_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory docs;

  setUpAll(() async {
    docs = await Directory.systemTemp.createTemp('qcf_fonts_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docs.path,
    );

    // Any valid font file stands in for the per-page QCF fonts on disk.
    final fontBytes =
        File('assets/fonts/AmiriQuran-Regular.ttf').readAsBytesSync();
    final dir = Directory('${docs.path}/fonts/qcf_v4')
      ..createSync(recursive: true);
    for (final page in [97, 98, 99, 100, 101, 102, 103, 500]) {
      File('${dir.path}/p$page.ttf').writeAsBytesSync(fontBytes);
    }
  });

  tearDownAll(() => docs.deleteSync(recursive: true));

  testWidgets('page font loads from disk and prefetches only ±radius pages',
      (tester) async {
    final service = QcfFontService.instance;
    const mode = QuranDisplayMode.tajweed;
    const radius = QcfFontService.prefetchRadius;

    await tester.runAsync(() async {
      final ok = await service.ensurePageFont(100, mode: mode);
      expect(ok, isTrue);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    for (var p = 100 - radius; p <= 100 + radius; p++) {
      expect(service.isFontLoaded(p, mode: mode), isTrue, reason: 'page $p');
    }
    // Fonts exist on disk for these, so they would load if the prefetch chained.
    expect(service.isFontLoaded(100 - radius - 1, mode: mode), isFalse);
    expect(service.isFontLoaded(100 + radius + 1, mode: mode), isFalse);
    // Tajweed reading no longer pulls the unused V2 fonts.
    expect(service.isFontLoaded(100), isFalse);
  });

  testWidgets('counts the page fonts already saved on the device',
      (tester) async {
    final count = await tester.runAsync(() => QcfFontService.instance
        .countDownloadedFonts(mode: QuranDisplayMode.tajweed));
    expect(count, 8);
  });
}
