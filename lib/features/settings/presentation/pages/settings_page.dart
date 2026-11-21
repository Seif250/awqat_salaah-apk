import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';
import 'advanced_settings_page.dart';
import 'appearance_settings_page.dart';
import 'azkar_settings_page.dart';
import 'calculation_settings_page.dart';
import 'location_settings_page.dart';
import 'notification_settings_page.dart';
import 'widget_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _devTapCount = 0;

  void _onVersionTap() {
    _devTapCount++;
    if (_devTapCount == 7) {
      _devTapCount = 0;
      AppSnackBar.showSuccess(context, 'تم تفعيل أدوات التشخيص المتقدمة');
      Navigator.push(
        context,
        FadeSlidePageRoute(page: const AdvancedSettingsPage()),
      );
    } else if (_devTapCount >= 4) {
      AppSnackBar.showInfo(
        context,
        'اضغط ${7 - _devTapCount} مرات إضافية لفتح أدوات التشخيص',
      );
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: p.accent),
            const SizedBox(width: 8),
            Text('سياسة الخصوصية', style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'تطبيق "وِرد" يحترم خصوصيتك بالكامل:\n\n'
            '• لا يتم جمع أو تخزين أو مشاركة أي بيانات شخصية أو موقعك الجغرافي مع أي جهة خارجية.\n'
            '• يتم استخدام موقعك الجغرافي حصرياً داخل جهازك لحساب أوقات الصلاة فلكياً دون الحاجة للاتصال بالإنترنت.\n'
            '• جميع الأذكار والتفضيلات والإعدادات يتم حفظها محلياً على جهازك فقط.',
            style: AppTypography.body(p.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: AppTypography.meta(p.accentText, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات', style: AppTypography.pageTitle(p.textPrimary)),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<PrayerBloc, PrayerState>(
            builder: (context, prayerState) {
              String locationSubtitle = 'اختر مدينتك لحساب المواقيت بدقة';
              if (prayerState is PrayerLoaded) {
                locationSubtitle = prayerState.countryName.isNotEmpty
                    ? '${prayerState.cityName}، ${prayerState.countryName}'
                    : prayerState.cityName;
              }

              final hasMinuteAdjustments = settingsState.adjustFajr != 0 ||
                  settingsState.adjustSunrise != 0 ||
                  settingsState.adjustDhuhr != 0 ||
                  settingsState.adjustAsr != 0 ||
                  settingsState.adjustMaghrib != 0 ||
                  settingsState.adjustIsha != 0;
              final calculationSubtitle = hasMinuteAdjustments
                  ? '${settingsState.calculationMethod.displayNameArabic} • مع تعديل يدوي'
                  : settingsState.calculationMethod.displayNameArabic;

              final notificationSubtitle = settingsState.notificationsEnabled
                  ? (settingsState.notificationSoundEnabled
                      ? 'مفعّلة مع صوت الأذان والإقامة'
                      : 'مفعّلة (إشعار صامت)')
                  : 'معطّلة حالياً';

              final themeSubtitle = settingsState.colorPalette.forcesDarkMode
                  ? 'داكن دائماً'
                  : (settingsState.themeMode == ThemeMode.dark
                      ? 'داكن'
                      : (settingsState.themeMode == ThemeMode.light
                          ? 'نهاري'
                          : 'حسب النظام'));

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. الصلاة والمواقيت (مدمجة بوضوح)
                  SettingsSectionCard(
                    title: 'الصلاة والمواقيت',
                    children: [
                      SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'المدينة والموقع الجغرافي',
                        subtitle: locationSubtitle,
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const LocationSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.calculate_outlined,
                        title: 'طريقة الحساب والمذهب والتعديل',
                        subtitle: calculationSubtitle,
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const CalculationSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // 2. التنبيهات والأذكار (تشمل البطارية تحت التنبيهات)
                  SettingsSectionCard(
                    title: 'التنبيهات والأذكار',
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'تنبيهات الأذان والإقامة والبطارية',
                        subtitle: notificationSubtitle,
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const NotificationSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.auto_stories_outlined,
                        title: 'الأذكار والتذكير اليومي',
                        subtitle: 'مواعيد تنبيه الورد والنسخ الاحتياطي',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const AzkarSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // 3. المظهر والودجت
                  SettingsSectionCard(
                    title: 'المظهر والودجت',
                    children: [
                      SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'الألوان وتنسيق الوقت',
                        subtitle:
                            '${settingsState.colorPalette.titleArabic} • $themeSubtitle • ${settingsState.is24HourFormat ? "24 ساعة" : "12 ساعة"}',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const AppearanceSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.widgets_outlined,
                        title: 'ودجت الشاشة الرئيسية',
                        subtitle: 'معاينة وتحديث الودجت على الشاشة الرئيسية',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const WidgetSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Footer: Privacy & Version Easter Egg
                  Center(
                    child: Column(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                          label: Text('سياسة الخصوصية', style: AppTypography.meta(p.textSecondary)),
                          style: TextButton.styleFrom(foregroundColor: p.textSecondary),
                          onPressed: () => _showPrivacyPolicy(context),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _onVersionTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              '${AppConstants.appName} • الإصدار ${AppConstants.appVersion}',
                              style: AppTypography.label(p.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
