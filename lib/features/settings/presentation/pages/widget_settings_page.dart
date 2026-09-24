import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/widget_service.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class WidgetSettingsPage extends StatefulWidget {
  const WidgetSettingsPage({super.key});

  @override
  State<WidgetSettingsPage> createState() => _WidgetSettingsPageState();
}

class _WidgetSettingsPageState extends State<WidgetSettingsPage> {
  bool _isRefreshing = false;

  Future<void> _refreshWidget() async {
    setState(() => _isRefreshing = true);
    try {
      await WidgetService.forceRefreshWidget();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال إشارة تحديث الودجت بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديث الودجت: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ودجت الشاشة الرئيسية'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Widget Live Preview Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceAlt : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('القاهرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      'أوقات الصلاة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? AppColors.accentGold : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSelected : AppColors.lightSurfaceSelected,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الصلاة القادمة: المغرب (06:15 م)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '01:24:35',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.accentGold : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الإقامة: 06:25 م (+10 د)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('الفجر 04:30', style: TextStyle(fontSize: 11)),
                    Text('الظهر 12:05', style: TextStyle(fontSize: 11)),
                    Text('العصر 03:30', style: TextStyle(fontSize: 11)),
                    Text('العشاء 07:45', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          SettingsSectionCard(
            title: 'إدارة الودجت',
            children: [
              SettingsTile(
                icon: Icons.refresh_rounded,
                title: 'تحديث بيانات الودجت الآن',
                subtitle: 'إعادة مزامنة المواقيت والعد التنازلي فورياً',
                trailing: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                showDivider: false,
                onTap: _isRefreshing ? null : _refreshWidget,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 18, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text(
                      'كيفية إضافة الودجت لشاشة هاتفك:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '1. انتقل إلى الشاشة الرئيسية لهاتفك.\n'
                  '2. اضغط مطولاً على أي مساحة فارغة.\n'
                  '3. اختر "الأدوات" أو "الودجت" (Widgets).\n'
                  '4. ابحث عن تطبيق "أوقات الصلاة" واختر الودجت.\n'
                  '5. اسحب الودجت وضعه في المكان المناسب على شاشتك.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.7,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
