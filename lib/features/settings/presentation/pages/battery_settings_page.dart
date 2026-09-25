import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../services/notification_service.dart';
import '../widgets/settings_section_card.dart';

class BatterySettingsPage extends StatefulWidget {
  const BatterySettingsPage({super.key});

  @override
  State<BatterySettingsPage> createState() => _BatterySettingsPageState();
}

class _BatterySettingsPageState extends State<BatterySettingsPage> {
  bool _isExempted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final exempted = await NotificationService().isBatteryOptimizationExempted();
    if (mounted) {
      setState(() {
        _isExempted = exempted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestBatteryExemption() async {
    final granted = await NotificationService().requestBatteryOptimizationExemption();
    await _checkStatus();
    if (mounted) {
      if (granted) {
        AppSnackBar.showSuccess(context, 'تم إعفاء التطبيق من قيود البطارية بنجاح');
      } else {
        AppSnackBar.showWarning(context, 'يرجى إعفاء التطبيق يدوياً من قائمة البطارية لضمان دقة الأذان');
      }
    }
  }

  void _showManufacturerGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_android_outlined, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('إرشادات حسب نوع الهاتف', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقوم بعض واجهات أندرويد بإغلاق التطبيقات في الخلفية لتوفير الطاقة. اضبط الإعدادات التالية حسب هاتفك:',
                style: TextStyle(height: 1.5, fontSize: 13),
              ),
              SizedBox(height: 14),
              Text('هواتف شاومي (Xiaomi / Redmi / POCO):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                '1. افتح الإعدادات ← التطبيقات ← إدارة التطبيقات.\n'
                '2. اختر "وِرد".\n'
                '3. فعّل "التشغيل التلقائي" (Autostart).\n'
                '4. في "موفر البطارية" اختر "بلا قيود" (No restrictions).',
                style: TextStyle(height: 1.6, fontSize: 12.5),
              ),
              SizedBox(height: 14),
              Text('هواتف ريلمي وأوبو (Realme / Oppo):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                '1. افتح الإعدادات ← إدارة التطبيقات.\n'
                '2. اختر "وِرد".\n'
                '3. فعّل "السماح بالتشغيل التلقائي".\n'
                '4. في استخدام البطارية فعّل "السماح بالنشاط في الخلفية".',
                style: TextStyle(height: 1.6, fontSize: 12.5),
              ),
              SizedBox(height: 14),
              Text('هواتف سامسونج (Samsung):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              SizedBox(height: 4),
              Text(
                '1. افتح الإعدادات ← العناية بالجهاز ← البطارية.\n'
                '2. اختر "حدود استخدام الخلفية".\n'
                '3. تأكد أن تطبيق وِرد في "تطبيقات لا تسكن أبداً".',
                style: TextStyle(height: 1.6, fontSize: 12.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('فهمت'),
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
        title: const Text('البطارية والتشغيل'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Battery Status Card
          SettingsSectionCard(
            title: 'حالة تحسين البطارية',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isLoading
                                ? Colors.grey.withValues(alpha: 0.2)
                                : (_isExempted
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLoading
                                    ? Icons.hourglass_empty_rounded
                                    : (_isExempted
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.warning_amber_rounded),
                                size: 16,
                                color: _isLoading
                                    ? Colors.grey
                                    : (_isExempted ? Colors.green : Colors.orange),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isLoading
                                    ? 'جاري الفحص...'
                                    : (_isExempted
                                        ? 'غير مقيّد (يعمل بكفاءة)'
                                        : 'مقيّد — يحتاج إلى تعديل'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isLoading
                                      ? Colors.grey
                                      : (_isExempted ? Colors.green : Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isExempted
                          ? 'التطبيق معفى من قيود توفير الطاقة، مما يضمن انطلاق صوت الأذان والإشعارات في موعدها الدقيق حتى عند إغلاق الشاشة.'
                          : 'قد يقوم نظام التشغيل بتأخير أو منع صوت الأذان عند تفعيل وضع توفير الطاقة. يرجى الضغط على الزر أدناه لإعفاء التطبيق.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.battery_saver_outlined, size: 18),
                        label: const Text('فتح إعدادات البطارية'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _isExempted ? AppColors.primary : AppColors.accentGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _requestBatteryExemption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AutoStart Card
          SettingsSectionCard(
            title: 'التشغيل التلقائي والعمل بالخلفية',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التشغيل التلقائي (AutoStart):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ضروري لأجهزة شاومي، ريلمي، أوبو، وهواوي للسماح للتطبيق بالاستيقاظ الذاتي عند حلول موعد الأذان.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('إعدادات التطبيق'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => openAppSettings(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.help_outline_rounded, size: 18),
                            label: const Text('دليل الهواتف'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showManufacturerGuide(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
