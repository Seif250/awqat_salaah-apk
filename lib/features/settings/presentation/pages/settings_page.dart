import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';
import 'adjustments_settings_page.dart';
import 'advanced_settings_page.dart';
import 'appearance_settings_page.dart';
import 'azkar_settings_page.dart';
import 'battery_settings_page.dart';
import 'calculation_settings_page.dart';
import 'location_settings_page.dart';
import 'notification_settings_page.dart';
import 'widget_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('سياسة الخصوصية'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'تطبيق "وِرد" يحترم خصوصيتك بالكامل:\n\n'
            '• لا يتم جمع أو تخزين أو مشاركة أي بيانات شخصية أو موقعك الجغرافي مع أي جهة خارجية.\n'
            '• يتم استخدام موقعك الجغرافي حصرياً داخل جهازك لحساب أوقات الصلاة فلكياً دون الحاجة للاتصال بالإنترنت.\n'
            '• جميع الأذكار والتفضيلات والإعدادات يتم حفظها محلياً على جهازك فقط.',
            style: TextStyle(height: 1.6, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return BlocBuilder<PrayerBloc, PrayerState>(
            builder: (context, prayerState) {
              String locationSubtitle = 'تحديد الموقع الجغرافي';
              if (prayerState is PrayerLoaded) {
                locationSubtitle = prayerState.countryName.isNotEmpty
                    ? '${prayerState.cityName}، ${prayerState.countryName}'
                    : prayerState.cityName;
              }

              final calculationSubtitle = settingsState.calculationMethod.displayNameArabic;
              final notificationSubtitle = settingsState.notificationsEnabled
                  ? (settingsState.notificationSoundEnabled ? 'مفعّلة (مع صوت الأذان)' : 'مفعّلة (بدون صوت)')
                  : 'معطّلة';
              final themeSubtitle = settingsState.themeMode == ThemeMode.dark
                  ? 'داكن'
                  : (settingsState.themeMode == ThemeMode.light ? 'فاتح' : 'حسب النظام');

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  // 1. أساسي
                  SettingsSectionCard(
                    title: 'أساسي',
                    children: [
                      SettingsTile(
                        icon: Icons.location_on_outlined,
                        title: 'الموقع الجغرافي',
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
                        title: 'مواقيت الصلاة',
                        subtitle: calculationSubtitle,
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const CalculationSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'تنبيهات الصلاة',
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
                        title: 'الأذكار والورد',
                        subtitle: 'التنبيهات، الورد اليومي، والأذكار المخصصة',
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

                  // 2. التفضيلات
                  SettingsSectionCard(
                    title: 'التفضيلات',
                    children: [
                      SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'المظهر والوقت',
                        subtitle: '$themeSubtitle • ${settingsState.is24HourFormat ? "24 ساعة" : "12 ساعة"}',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const AppearanceSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.tune_outlined,
                        title: 'تعديل المواقيت',
                        subtitle: 'تقديم أو تأخير أوقات الصلاة بالدقائق',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const AdjustmentsSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // 3. الجهاز
                  SettingsSectionCard(
                    title: 'الجهاز والتشغيل',
                    children: [
                      SettingsTile(
                        icon: Icons.widgets_outlined,
                        title: 'ودجت الشاشة الرئيسية',
                        subtitle: 'معاينة وتحديث الودجت المصغر',
                        showDivider: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const WidgetSettingsPage()),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.battery_saver_outlined,
                        title: 'البطارية والتشغيل',
                        subtitle: 'تحسين البطارية والتشغيل التلقائي بالأجهزة',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const BatterySettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  // 4. متقدم
                  SettingsSectionCard(
                    title: 'متقدم',
                    children: [
                      SettingsTile(
                        icon: Icons.settings_outlined,
                        title: 'إعدادات متقدمة',
                        subtitle: 'التشخيص، فحص التنبيهات، ومعلومات النظام',
                        showDivider: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            FadeSlidePageRoute(page: const AdvancedSettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Footer: About & Privacy
                  Center(
                    child: Column(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                          label: const Text('سياسة الخصوصية'),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white60 : Colors.black54,
                          ),
                          onPressed: () => _showPrivacyPolicy(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppConstants.appName} • ${AppConstants.appSubtitle} • الإصدار ${AppConstants.appVersion}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38,
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
