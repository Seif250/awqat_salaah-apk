import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';
import '../../../quran/presentation/bloc/quran_bloc.dart';
import '../../../quran/presentation/bloc/quran_event.dart';
import '../../../quran/presentation/bloc/quran_state.dart';
import '../../../quran/data/repositories/tafsir_repository.dart';
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

  void _showDefaultTafsirDialog(BuildContext context, int currentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final list = TafsirRepositoryImpl.defaultArabicTafsirs;

        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B201D) : const Color(0xFFFAF6EE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'اختر التفسير الافتراضي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: (isDark ? Colors.white12 : Colors.black12),
                  ),
                  itemBuilder: (ctx, index) {
                    final res = list[index];
                    final isSelected = res.id == currentId;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.accentGold
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      title: Text(
                        res.name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppColors.accentGold
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: res.authorName.isNotEmpty
                          ? Text(
                              res.authorName,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            )
                          : null,
                      onTap: () {
                        context
                            .read<QuranBloc>()
                            .add(SetDefaultTafsirEvent(res.id));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMushafFontWeightDialog(BuildContext context, int currentWeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final options = [
          (
            weight: 400,
            title: 'عادي (٤٠٠)',
            subtitle: 'السُّمك القياسي للخط العثماني لمصحف المدينة',
            fontWeight: FontWeight.w400,
          ),
          (
            weight: 500,
            title: 'متوسط (٥٠٠) - موصى به',
            subtitle: 'سُمْك متوازن ومريح لقراءة واضحة للشاشات الحديثة',
            fontWeight: FontWeight.w500,
          ),
          (
            weight: 700,
            title: 'عريض (٧٠٠)',
            subtitle: 'سُمْك بارز وواضح جداً لأفضل قراءة وتحديد',
            fontWeight: FontWeight.w700,
          ),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B201D) : const Color(0xFFFAF6EE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'اختر سُمْك الرسم القرآني',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'يتحكم في درجة وضوح وسُمْك الخط داخل صفحات المصحف الشريف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 14),
              ...options.map((opt) {
                final isSelected = opt.weight == currentWeight;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold.withValues(alpha: isDark ? 0.18 : 0.12)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.accentGold
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      title: Text(
                        opt.title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppColors.accentGold
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: Text(
                        opt.subtitle,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'القرآن',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            fontWeight: opt.fontWeight,
                            color: isSelected
                                ? AppColors.accentGold
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      onTap: () {
                        context
                            .read<QuranBloc>()
                            .add(ChangeMushafFontWeightEvent(opt.weight));
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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

                  // 3. القرآن الكريم والمصحف
                  BlocBuilder<QuranBloc, QuranState>(
                    builder: (context, qState) {
                      final isLoaded = qState is QuranLoaded;
                      final defaultTafsirId =
                          isLoaded ? qState.defaultTafsirResourceId : 16;
                      final tafsirMatch = TafsirRepositoryImpl.defaultArabicTafsirs
                          .where((r) => r.id == defaultTafsirId);
                      final tafsirName = tafsirMatch.isNotEmpty
                          ? tafsirMatch.first.name
                          : 'التفسير الميسر';
                      final currentWeight =
                          isLoaded ? qState.mushafFontWeight : 500;
                      final weightLabel = currentWeight == 400
                          ? 'عادي (٤٠٠)'
                          : (currentWeight == 700
                              ? 'عريض (٧٠٠)'
                              : 'متوسط (٥٠٠)');

                      return SettingsSectionCard(
                        title: 'القرآن الكريم والمصحف',
                        children: [
                          SettingsTile(
                            icon: Icons.palette_outlined,
                            title: 'ألوان التجويد',
                            subtitle: 'مصحف التجويد الملون هو نمط العرض المعتمد',
                            showDivider: true,
                            trailing: const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentGold),
                          ),
                          SettingsTile(
                            icon: Icons.format_paint_outlined,
                            title: 'سُمْك الرسم القرآني',
                            subtitle: weightLabel,
                            showDivider: true,
                            onTap: () => _showMushafFontWeightDialog(
                                context, currentWeight),
                          ),
                          SettingsTile(
                            icon: Icons.menu_book_outlined,
                            title: 'التفسير الافتراضي',
                            subtitle: tafsirName,
                            showDivider: false,
                            onTap: () =>
                                _showDefaultTafsirDialog(context, defaultTafsirId),
                          ),
                        ],
                      );
                    },
                  ),

                  // 4. المظهر والتشغيل
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
