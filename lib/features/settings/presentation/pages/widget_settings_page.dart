import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
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
        AppSnackBar.showSuccess(context, 'تم إرسال إشارة تحديث الودجت بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'تعذر تحديث الودجت: $e');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('ودجت الشاشة الرئيسية', style: AppTypography.pageTitle(p.textPrimary)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Single-surface Widget Live Preview matching OS Day/Night widget
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Location & Wird Wordmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: p.accentText),
                        const SizedBox(width: 4),
                        Text('القاهرة', style: AppTypography.meta(p.textPrimary, weight: FontWeight.w600)),
                      ],
                    ),
                    Text('وِرد', style: AppTypography.label(p.accentText, weight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),

                // Open Hero Section (no inner boxed card)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الصلاة القادمة', style: AppTypography.badge(p.accentText)),
                          const SizedBox(height: 2),
                          Text('المغرب • ٠٦:١٥ م', style: AppTypography.sectionHeader(p.textPrimary)),
                          const SizedBox(height: 2),
                          Text('الإقامة: ٠٦:٢٥ م', style: AppTypography.label(p.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('متبقي', style: AppTypography.label(p.textSecondary)),
                        Text(
                          '01:24:35',
                          style: AppTypography.heroCountdown(p.accentText)
                              .copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(height: 0.75, color: p.hairline),
                const SizedBox(height: 10),

                // Bottom 5-prayer row with subtle active pill
                Row(
                  children: [
                    for (final item in const [
                      ('الفجر', '04:30', false),
                      ('الظهر', '12:05', false),
                      ('العصر', '03:30', false),
                      ('المغرب', '06:15', true),
                      ('العشاء', '07:45', false),
                    ])
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: item.$3
                              ? BoxDecoration(
                                  color: p.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                )
                              : null,
                          child: Column(
                            children: [
                              Text(
                                item.$1,
                                style: AppTypography.badge(
                                  item.$3 ? p.accentText : p.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.$2,
                                style: AppTypography.badge(
                                  item.$3 ? p.accentText : p.textPrimary,
                                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ],
                          ),
                        ),
                      ),
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

          // Instructions Note (flat container, matches OS Day/Night automatically)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.cardElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 18, color: p.accent),
                    const SizedBox(width: 8),
                    Text('كيفية إضافة الودجت لشاشة هاتفك:', style: AppTypography.rowTitle(p.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '1. انتقل إلى الشاشة الرئيسية لهاتفك.\n'
                  '2. اضغط مطولاً على أي مساحة فارغة.\n'
                  '3. اختر "الأدوات" أو "الودجت" (Widgets).\n'
                  '4. ابحث عن تطبيق "وِرد" واختر الودجت.\n'
                  '5. اسحب الودجت وضعه في المكان المناسب على شاشتك.\n\n'
                  '• يتكيّف مظهر الودجت تلقائياً مع الوضع النهاري والليلي للنظام.',
                  style: AppTypography.meta(p.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
