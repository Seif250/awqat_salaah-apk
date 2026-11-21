import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/core/constants/app_constants.dart';
import 'package:awqat_salaah/core/theme/app_color_palette.dart';
import 'package:awqat_salaah/core/theme/app_theme.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_bloc.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_state.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_event.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_state.dart';
import 'package:awqat_salaah/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:awqat_salaah/services/storage_service.dart';

class _FakePrayerBloc extends Cubit<PrayerState> implements PrayerBloc {
  _FakePrayerBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Color Palette & Theme System Tests', () {
    test('StorageService defaults to royalEmerald and roundtrips all 3 palettes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService.withPrefs(prefs);

      expect(storage.colorPalette, AppColorPalette.royalEmerald);

      for (final palette in AppColorPalette.values) {
        await storage.setColorPalette(palette);
        expect(storage.colorPalette, palette);
        expect(prefs.getString(AppConstants.keyColorPalette), palette.storageKey);
      }

      expect(
        AppColorPaletteExtension.fromStorageKey('non_existent_key'),
        AppColorPalette.royalEmerald,
      );
      expect(
        AppColorPaletteExtension.fromStorageKey(null),
        AppColorPalette.royalEmerald,
      );
      expect(
        AppColorPaletteExtension.fromStorageKey('sepiaParchment'),
        AppColorPalette.goldenMushaf,
      );
    });

    test('SettingsBloc loads persisted palette and updates on ChangeColorPaletteEvent', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyColorPalette: AppColorPalette.goldenMushaf.storageKey,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService.withPrefs(prefs);
      final bloc = SettingsBloc(storageService: storage);
      addTearDown(bloc.close);

      expect(bloc.state.colorPalette, AppColorPalette.royalEmerald);

      bloc.add(const LoadSettingsEvent());
      await expectLater(
        bloc.stream,
        emits(
          isA<SettingsState>().having(
            (s) => s.colorPalette,
            'colorPalette',
            AppColorPalette.goldenMushaf,
          ),
        ),
      );

      bloc.add(const ChangeColorPaletteEvent(AppColorPalette.amoledGold));
      await expectLater(
        bloc.stream,
        emits(
          isA<SettingsState>().having(
            (s) => s.colorPalette,
            'colorPalette',
            AppColorPalette.amoledGold,
          ),
        ),
      );
      expect(storage.colorPalette, AppColorPalette.amoledGold);
    });

    testWidgets('AppTheme.buildTheme attaches WirdPalette for all 3 palettes in light & dark',
        (tester) async {
      for (final palette in AppColorPalette.values) {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.buildTheme(palette, brightness);
          final ext = theme.extension<WirdPalette>();

          expect(ext, isNotNull);
          expect(ext!.id, palette);

          if (palette == AppColorPalette.amoledGold) {
            expect(ext.isDark, isTrue);
            expect(theme.brightness, Brightness.dark);
            expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
          } else {
            expect(ext.isDark, brightness == Brightness.dark);
          }

          if (palette == AppColorPalette.royalEmerald &&
              brightness == Brightness.light) {
            expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
          }
          if (palette == AppColorPalette.goldenMushaf &&
              brightness == Brightness.light) {
            expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF4E4));
          }
        }
      }
    });

    testWidgets('AppearanceSettingsPage renders all 3 palettes and dispatches ChangeColorPaletteEvent',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService.withPrefs(prefs);
      final settingsBloc = SettingsBloc(storageService: storage);
      final prayerBloc = _FakePrayerBloc(const PrayerInitial());
      addTearDown(() async {
        await settingsBloc.close();
        await prayerBloc.close();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: settingsBloc),
            BlocProvider<PrayerBloc>.value(value: prayerBloc),
          ],
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return MaterialApp(
                theme: AppTheme.buildTheme(state.colorPalette, Brightness.light),
                darkTheme: AppTheme.buildTheme(state.colorPalette, Brightness.dark),
                themeMode: state.colorPalette.forcesDarkMode
                    ? ThemeMode.dark
                    : state.themeMode,
                home: const Directionality(
                  textDirection: TextDirection.rtl,
                  child: AppearanceSettingsPage(),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('تلقائي'), findsOneWidget);
      expect(find.text('نهاري'), findsOneWidget);
      expect(find.text('ليلي'), findsOneWidget);

      for (final palette in AppColorPalette.values) {
        await tester.ensureVisible(find.text(palette.titleArabic));
        await tester.pumpAndSettle();
        expect(find.text(palette.titleArabic), findsOneWidget);
      }

      expect(AppColorPalette.values.length, 3);

      // Select Golden Mushaf
      await tester.ensureVisible(
        find.text(AppColorPalette.goldenMushaf.titleArabic),
      );
      await tester.tap(find.text(AppColorPalette.goldenMushaf.titleArabic));
      await tester.pumpAndSettle();
      expect(settingsBloc.state.colorPalette, AppColorPalette.goldenMushaf);
      expect(storage.colorPalette, AppColorPalette.goldenMushaf);

      // Select AMOLED Gold and confirm forced-dark explanation appears
      await tester.ensureVisible(
        find.text(AppColorPalette.amoledGold.titleArabic),
      );
      await tester.tap(find.text(AppColorPalette.amoledGold.titleArabic));
      await tester.pumpAndSettle();
      expect(settingsBloc.state.colorPalette, AppColorPalette.amoledGold);
      await tester.scrollUntilVisible(
        find.text('وضع الليلي الخالص (AMOLED) يعمل بالثيم الداكن دائماً لراحة العين'),
        -200,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('وضع الليلي الخالص (AMOLED) يعمل بالثيم الداكن دائماً لراحة العين'),
        findsOneWidget,
      );
    });
  });
}
