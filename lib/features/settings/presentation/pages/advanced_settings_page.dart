import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/widget_service.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  String _getSoundDisplayName(String soundType) {
    switch (soundType) {
      case AppConstants.soundTypeFull:
        return 'الأذان كامل';
      case AppConstants.soundTypeTakbeer:
        return 'الله أكبر الله أكبر (تكبيرات)';
      case AppConstants.soundTypeHayya:
      default:
        return 'حي على الصلاة (مختصر)';
    }
  }

  Future<void> _showDiagnosticsDialog(BuildContext context) async {
    final ns = NotificationService();
    final storage = StorageService();
    final currentSoundType = storage.notificationSoundType;
    final soundCfg = ns.getSoundConfig(currentSoundType);
    final notifsEnabled = await ns.areNotificationsEnabled();
    final exactAllowed = await ns.canScheduleExactAlarms();
    final batteryExempt = await ns.isBatteryOptimizationExempted();
    final pending = await ns.getPendingNotifications();
    final log = ns.diagnosticLog;

    String widgetDiag = '';
    try {
      widgetDiag = await WidgetService.getWidgetDiagnostics();
    } catch (e) {
      widgetDiag = 'تعذر قراءة سجل الويدجيت: $e';
    }

    if (!context.mounted) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('تقرير التشخيص الشامل'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. حالة صوت الأذان
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded, color: AppColors.accentGold, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('صوت الأذان النشط حالياً:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(
                              '${soundCfg["displayName"]} (${soundCfg["channelId"]})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. حالة أذونات النظام
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceAlt : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            notifsEnabled ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: notifsEnabled ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notifsEnabled ? 'إذن الإشعارات: مفعّل' : 'إذن الإشعارات: معطل بالنظام',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: notifsEnabled ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            exactAllowed ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            color: exactAllowed ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exactAllowed ? 'المنبهات الدقيقة: مسموحة' : 'المنبهات الدقيقة: مقيدة بالنظام',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: exactAllowed ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            batteryExempt ? Icons.check_circle_outline : Icons.info_outline,
                            color: batteryExempt ? Colors.green : Colors.blueGrey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              batteryExempt ? 'إعفاء البطارية: غير مقيّد' : 'إعفاء البطارية: وضع عادي',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: batteryExempt ? Colors.green : Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. التنبيهات المجدولة
                Text('التنبيهات المجدولة في النظام (${pending.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (pending.isEmpty)
                  const Text('لا توجد تنبيهات مجدولة حالياً', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...pending.take(6).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• [${p.id}] ${p.title ?? "—"}',
                          style: const TextStyle(fontSize: 11.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),

                // 4. سجل تشخيص الويدجيت
                if (widgetDiag.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('سجل تشخيص الويدجيت (Widget):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widgetDiag,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ],

                // 5. سجل عمليات التطبيق
                if (log.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('سجل العمليات الأخير:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black54 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.take(15).join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('نسخ تقرير التشخيص الشامل'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
            onPressed: () {
              final pendingSummary = pending.map((p) => '[${p.id}] ${p.title}').join('\n');
              final report = StringBuffer()
                ..writeln('═══ تقرير تشخيص تطبيق أوقات الصلاة ═══')
                ..writeln('تاريخ التقرير: ${DateTime.now().toIso8601String()}')
                ..writeln('الإصدار: ${AppConstants.appVersion}')
                ..writeln('صوت الأذان النشط: ${soundCfg["displayName"]} (${soundCfg["channelId"]})')
                ..writeln('إذن الإشعارات: $notifsEnabled')
                ..writeln('المنبهات الدقيقة Exact Alarms: $exactAllowed')
                ..writeln('إعفاء توفير البطارية: $batteryExempt')
                ..writeln('\n── التنبيهات المجدولة (${pending.length}) ──')
                ..writeln(pendingSummary.isEmpty ? 'لا توجد تنبيهات مجدولة' : pendingSummary)
                ..writeln('\n── سجل تشخيص الويدجيت ──')
                ..writeln(widgetDiag)
                ..writeln('\n── سجل عمليات الإشعارات ──')
                ..writeln(log.join('\n'));

              Clipboard.setData(ClipboardData(text: report.toString()));
              Navigator.pop(ctx);
              AppSnackBar.showSuccess(context, 'تم نسخ تقرير التشخيص الشامل للحافظة، يمكنك مشاركته مع المطور');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final activeSoundType = storage.notificationSoundType;
    final activeSoundName = _getSoundDisplayName(activeSoundType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات متقدمة'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. التشخيص والفحص الفني
          SettingsSectionCard(
            title: 'التشخيص والفحص الفني',
            children: [
              SettingsTile(
                icon: Icons.assignment_outlined,
                title: 'تقرير التشخيص الشامل وحالة الويدجيت',
                subtitle: 'فحص التنبيهات المجدولة والويدجيت وأذونات النظام ونسخ التقرير',
                showDivider: true,
                onTap: () => _showDiagnosticsDialog(context),
              ),
              SettingsTile(
                icon: Icons.volume_up_rounded,
                title: 'اختبار فوري لصوت الأذان المختار',
                subtitle: 'تشغيل إشعار فوري بصوت ($activeSoundName)',
                showDivider: true,
                onTap: () async {
                  final result = await NotificationService().showCurrentSoundTestNotification();
                  if (context.mounted) {
                    if (result == 'success') {
                      AppSnackBar.showSuccess(context, 'تم إرسال إشعار الأذان بصوت ($activeSoundName) بنجاح');
                    } else {
                      AppSnackBar.showError(context, 'تعذر تشغيل الصوت: $result');
                    }
                  }
                },
              ),
              SettingsTile(
                icon: Icons.alarm_on_outlined,
                title: 'اختبار منبه الأذان المجدول (بعد 10 ثوانٍ)',
                subtitle: 'يطلق منبه ($activeSoundName) بعد 10 ثوانٍ لتجربة الشاشة المقفلة',
                showDivider: true,
                onTap: () async {
                  final result = await NotificationService().scheduleTestAlarmInSeconds(
                    seconds: 10,
                    isSoundEnabled: true,
                    soundType: activeSoundType,
                  );
                  if (context.mounted) {
                    if (result.startsWith('failed')) {
                      AppSnackBar.showError(context, 'فشل الجدولة: $result');
                    } else {
                      AppSnackBar.showSuccess(context, 'تمت جدولة منبه ($activeSoundName) بعد 10 ثوانٍ. اقفل الشاشة للتجربة');
                    }
                  }
                },
              ),
              SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'تجربة كافة أصوات الأذان مباشرة',
                subtitle: 'استماع وتجربة إشعار لكل من (الأذان كامل - حي على الصلاة - الله أكبر)',
                showDivider: false,
                onTap: () => _showAllSoundsTestSheet(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. النظام ومعلومات التطبيق
          SettingsSectionCard(
            title: 'النظام ومعلومات التطبيق',
            children: [
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'إصدار التطبيق',
                subtitle: AppConstants.appVersion,
                trailing: const SizedBox.shrink(),
                showDivider: true,
              ),
              SettingsTile(
                icon: Icons.system_update_outlined,
                title: 'منظومة الجدولة',
                subtitle: 'محرك الجدولة المتقدم (Exact Alarms & Doze Fallback)',
                trailing: const SizedBox.shrink(),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAllSoundsTestSheet(BuildContext context) {
    final sounds = [
      {'key': AppConstants.soundTypeFull, 'name': 'الأذان كامل', 'desc': 'الأذان كاملاً مع الترديد والدعاء'},
      {'key': AppConstants.soundTypeHayya, 'name': 'حي على الصلاة', 'desc': 'صوت الأذان المختصر المعتاد'},
      {'key': AppConstants.soundTypeTakbeer, 'name': 'الله أكبر الله أكبر', 'desc': 'تكبيرات دخول وقت الصلاة'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.playlist_play_rounded, color: AppColors.accentGold),
                SizedBox(width: 8),
                Text('تجربة أصوات الأذان كإشعار منبه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...sounds.map((s) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.accentGold, size: 20),
                  ),
                  title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s['desc']!, style: const TextStyle(fontSize: 12)),
                  trailing: FilledButton.tonal(
                    onPressed: () async {
                      final res = await NotificationService().showSoundTestNotification(s['key']!);
                      if (context.mounted) {
                        if (res == 'success') {
                          AppSnackBar.showSuccess(context, 'تم تشغيل إشعار (${s["name"]}) بنجاح');
                        } else {
                          AppSnackBar.showError(context, 'تعذر إرسال الإشعار: $res');
                        }
                      }
                    },
                    child: const Text('تجربة'),
                  ),
                )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
