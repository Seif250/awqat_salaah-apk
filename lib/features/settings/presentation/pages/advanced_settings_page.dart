import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/notification_service.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  Future<void> _showDiagnosticsDialog(BuildContext context) async {
    final ns = NotificationService();
    final notifsEnabled = await ns.areNotificationsEnabled();
    final exactAllowed = await ns.canScheduleExactAlarms();
    final batteryExempt = await ns.isBatteryOptimizationExempted();
    final pending = await ns.getPendingNotifications();
    final log = ns.diagnosticLog;

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13231B) : Colors.grey.shade100,
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
                const SizedBox(height: 16),
                Text('عدد التنبيهات المجدولة حالياً: ${pending.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...pending.take(5).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• [${p.id}] ${p.title ?? "—"}',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                if (log.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
            label: const Text('نسخ التقرير'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
            onPressed: () {
              final text = 'Status: notifs=$notifsEnabled, exact=$exactAllowed, battery=$batteryExempt\n'
                  'Pending: ${pending.length}\nLog:\n${log.join("\n")}';
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ تقرير التشخيص للحافظة')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات متقدمة'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. التشخيص
          SettingsSectionCard(
            title: 'التشخيص والفحص الفني',
            children: [
              SettingsTile(
                icon: Icons.assignment_outlined,
                title: 'حالة الإشعارات والمنبهات',
                subtitle: 'فحص التنبيهات المجدولة وأذونات النظام',
                showDivider: true,
                onTap: () => _showDiagnosticsDialog(context),
              ),
              SettingsTile(
                icon: Icons.notification_important_outlined,
                title: 'اختبار إشعار فوري',
                subtitle: 'إظهار إشعار تجريبي بالصوت الافتراضي للنظام',
                showDivider: true,
                onTap: () async {
                  final result = await NotificationService().showSimpleTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result == 'success' ? 'تم إرسال الإشعار التجريبي بنجاح' : 'تعذر إرسال الإشعار: $result'),
                        backgroundColor: result == 'success' ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              SettingsTile(
                icon: Icons.volume_up_outlined,
                title: 'اختبار صوت التكبير',
                subtitle: 'تشغيل تنبيه بصوت التكبير فوراً للتأكد من مكبر الصوت',
                showDivider: true,
                onTap: () async {
                  final result = await NotificationService().showTakbeerTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result == 'success' ? 'تم تشغيل التكبير بنجاح' : 'تعذر تشغيل الصوت: $result'),
                        backgroundColor: result == 'success' ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              SettingsTile(
                icon: Icons.alarm_on_outlined,
                title: 'اختبار منبه الأذان المجدول (بعد 10 ثوانٍ)',
                subtitle: 'أغلق التطبيق واقفل الشاشة للتأكد من الاستيقاظ التلقائي',
                showDivider: false,
                onTap: () async {
                  final result = await NotificationService().scheduleTestAlarmInSeconds(
                    seconds: 10,
                    isSoundEnabled: true,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.startsWith('failed')
                            ? 'فشل الجدولة: $result'
                            : 'تمت جدولة الأذان بعد 10 ثوانٍ. اقفل الشاشة للتجربة'),
                        duration: const Duration(seconds: 5),
                        backgroundColor: result.startsWith('failed') ? Colors.red : Colors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. النظام
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
}
