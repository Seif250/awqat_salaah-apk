import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/app_snackbar.dart';
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
      AppSnackBar.showSuccess(context, 'تم تفعيل خيارات التشخيص والمطور');
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('سياسة الخصوصية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'تطبيق "وِرد" يحترم خصوصيتك بالكامل:\n\n'
            '• لا يتم جمع أو تخزين أو مشاركة أي بيانات شخصية أو موقعك الجغرافي مع أي جهة خارجية.\n'
            '• يتم استخدام موقعك الجغرافي حصرياً داخل جهازك لحساب أوقات الصلاة فلكياً دون الحاجة للاتصال بالإنترنت.\n'
            '• جميع الأذكار والتفضيلات والإعدادات يتم حفظها محلياً على جهازك فقط.',
            style: TextStyle(fontFamily: 'Cairo', height: 1.6, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
        title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // 1. الصلاة والمواقيت
                  SettingsSectionCard(
                    title: 'الصلاة والمواقيت',
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
                        title: 'طريقة الحساب والمذهب',
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
                        icon: Icons.tune_outlined,
                        title: 'تعديل المواقيت بالدقائق',
                        subtitle: 'تقديم أو تأخير أوقات الصلوات',
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

                  // 2. التنبيهات والأذكار
                  SettingsSectionCard(
                    title: 'التنبيهات والأذكار',
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'تنبيهات الصلاة والأذان',
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
                        title: 'الأذكار والورد اليومي',
                        subtitle: 'التنبيهات، الورد، والنسخ الاحتياطي للأذكار',
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

                  // 3. المظهر والتشغيل
                  SettingsSectionCard(
                    title: 'المظهر والتشغيل',
                    children: [
                      SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'المظهر وتنسيق الوقت',
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
                        icon: Icons.widgets_outlined,
                        title: 'ودجت الشاشة الرئيسية',
                        subtitle: 'تخصيص وتحديث الويدجت المصغر',
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
                        title: 'استقرار الأذان والبطارية',
                        subtitle: 'إرشادات استثناء البطارية والتشغيل بالخلفية',
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

                  const SizedBox(height: 20),

                  // Footer: About, Privacy & Developer Easter Egg
                  Center(
                    child: Column(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.privacy_tip_outlined, size: 16),
                          label: const Text(
                            'سياسة الخصوصية',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          ),
                          onPressed: () => _showPrivacyPolicy(context),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _onVersionTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Text(
                              '${AppConstants.appName} • ${AppConstants.appSubtitle} • الإصدار ${AppConstants.appVersion}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
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
