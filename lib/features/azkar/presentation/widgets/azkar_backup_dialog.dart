import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/repositories/azkar_repository.dart';
import '../../data/services/azkar_backup_service.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';

class AzkarBackupDialog extends StatefulWidget {
  const AzkarBackupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AzkarBloc>(),
        child: const AzkarBackupDialog(),
      ),
    );
  }

  @override
  State<AzkarBackupDialog> createState() => _AzkarBackupDialogState();
}

class _AzkarBackupDialogState extends State<AzkarBackupDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pasteController = TextEditingController();
  bool _replaceExisting = false;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  List<AzkarItem> _getCustomItems() {
    final repo = context.read<AzkarRepository>();
    return repo.getCustomAzkarItems();
  }

  void _setStatus(String message, {bool isSuccess = false}) {
    setState(() {
      _statusMessage = message;
      _isSuccess = isSuccess;
    });
  }

  Future<void> _exportToFile(List<AzkarItem> items) async {
    if (items.isEmpty) {
      _setStatus('لا توجد أذكار مخصصة لحفظها. أضف بعض الأذكار أولاً!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final savedPath = await AzkarBackupService.saveBackupToStorage(items);
      if (savedPath != null) {
        _setStatus('تم حفظ النسخة الاحتياطية بنجاح في:\n$savedPath', isSuccess: true);
      } else {
        _setStatus('تم إلغاء عملية الحفظ');
      }
    } catch (e) {
      _setStatus('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareBackup(List<AzkarItem> items) async {
    if (items.isEmpty) {
      _setStatus('لا توجد أذكار مخصصة للمشاركة. أضف بعض الأذكار أولاً!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ok = await AzkarBackupService.shareBackupFile(items);
      if (ok) {
        _setStatus('تم فتح نافذة المشاركة بنجاح. يمكنك حفظ الملف على Google Drive أو واتساب.', isSuccess: true);
      }
    } catch (e) {
      _setStatus('حدث خطأ أثناء المشاركة: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyJsonToClipboard(List<AzkarItem> items) async {
    if (items.isEmpty) {
      _setStatus('لا توجد أذكار مخصصة لنسخها.');
      return;
    }

    final json = AzkarBackupService.generateBackupJson(items);
    await Clipboard.setData(ClipboardData(text: json));
    _setStatus('تم نسخ كود JSON (${items.length} أذكار) إلى الحافظة بنجاح!', isSuccess: true);
  }

  Future<void> _pickAndImportFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final items = await AzkarBackupService.pickAndImportFile();
      if (items == null) {
        _setStatus('تم إلغاء اختيار الملف');
        return;
      }
      if (items.isEmpty) {
        _setStatus('لم يتم العثور على أذكار صالحة داخل الملف المحدد.');
        return;
      }

      if (mounted) {
        _showConfirmationDialog(items);
      }
    } catch (e) {
      _setStatus('فشل قراءة الملف: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _importFromPastedText() {
    final text = _pasteController.text.trim();
    if (text.isEmpty) {
      _setStatus('يرجى لصق كود JSON أولاً.');
      return;
    }

    try {
      final items = AzkarBackupService.parseBackupJson(text);
      if (items.isEmpty) {
        _setStatus('لم يتم العثور على أذكار صالحة داخل النص.');
        return;
      }
      _showConfirmationDialog(items);
    } catch (e) {
      _setStatus('كود JSON غير صالح: $e');
    }
  }

  void _showConfirmationDialog(List<AzkarItem> items) {
    showDialog(
      context: context,
      builder: (dlgCtx) {
        final p = dlgCtx.palette;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: p.accent),
              const SizedBox(width: 8),
              Text('تأكيد استرجاع الأذكار (${items.length})', style: AppTypography.rowTitle(p.textPrimary)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replaceExisting
                      ? 'سيتم استبدال جميع الأذكار المخصصة الحالية بالأذكار التالية:'
                      : 'سيتم دمج الأذكار التالية مع أذكارك المخصصة الحالية:',
                  style: AppTypography.meta(p.textPrimary, weight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: p.cardElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(height: 8, color: p.hairline),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: p.primaryContainer,
                            child: Text(
                              '${i + 1}',
                              style: AppTypography.badge(p.accentText),
                            ),
                          ),
                          title: Text(
                            item.title.isNotEmpty ? item.title : item.arabicText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700),
                          ),
                          trailing: Text(
                            '${item.targetCount}x',
                            style: AppTypography.badge(p.accentText),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dlgCtx);
                context.read<AzkarBloc>().add(
                      ImportCustomAzkarEvent(
                        items: items,
                        replaceExisting: _replaceExisting,
                      ),
                    );
                _setStatus(
                  'تم استرجاع ${items.length} أذكار مخصصة بنجاح!',
                  isSuccess: true,
                );
                _pasteController.clear();
              },
              child: Text(
                'تأكيد وحفظ',
                style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final customItems = _getCustomItems();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sync_alt_rounded, color: p.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('النسخ الاحتياطي للأذكار المخصصة', style: AppTypography.sectionHeader(p.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        'حفظ واسترجاع أذكارك الخاصة بصيغة JSON بأمان',
                        style: AppTypography.label(p.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: p.textSecondary),
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: p.cardElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: p.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: p.onPrimary,
              unselectedLabelColor: p.textSecondary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  text: 'تصدير وحفظ (${customItems.length})',
                ),
                const Tab(
                  icon: Icon(Icons.download_rounded, size: 18),
                  text: 'استرجاع واستيراد',
                ),
              ],
            ),
          ),

          // Feedback Status Banner
          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSuccess ? p.primaryContainer : p.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: _isSuccess ? p.success : p.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: AppTypography.label(
                        _isSuccess ? p.success : p.error,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: p.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _statusMessage = null),
                  ),
                ],
              ),
            ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(color: p.primary),
              ),
            ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExportTab(context, customItems, p.isDark),
                _buildImportTab(context, p.isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab(BuildContext context, List<AzkarItem> customItems, bool isDark) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark_added_rounded, color: p.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أذكارك المخصصة المسجلة: ${customItems.length} أذكار',
                      style: AppTypography.rowTitle(p.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'احفظ نسختك في ملف أو سحابياً لتتمكن من استرجاعها بضغطة زر عند إعادة تثبيت التطبيق.',
                      style: AppTypography.label(p.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildActionTile(
          icon: Icons.save_alt_rounded,
          iconColor: p.accent,
          title: 'حفظ كملف في الذاكرة (JSON)',
          subtitle: 'تحديد مكان الحفظ بنفسك (الذاكرة الداخلية، كارت SD، أو التنزيلات)',
          onTap: () => _exportToFile(customItems),
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: Icons.share_rounded,
          iconColor: p.primary,
          title: 'مشاركة وحفظ سحابي',
          subtitle: 'إرسال الملف مباشرة إلى Google Drive، واتساب، أو تطبيق الملفات',
          onTap: () => _shareBackup(customItems),
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        _buildActionTile(
          icon: Icons.copy_rounded,
          iconColor: p.accentText,
          title: 'نسخ كود JSON إلى الحافظة',
          subtitle: 'نسخ نصوص وبيانات الأذكار ككود خام للملاحظات أو الحافظة',
          onTap: () => _copyJsonToClipboard(customItems),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildImportTab(BuildContext context, bool isDark) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.cardElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('طريقة استرجاع الأذكار:', style: AppTypography.rowTitle(p.textPrimary)),
              const SizedBox(height: 6),
              RadioGroup<bool>(
                groupValue: _replaceExisting,
                onChanged: (val) => setState(() => _replaceExisting = val ?? false),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Text('دمج مع الأذكار الحالية (موصى به)', style: AppTypography.meta(p.textPrimary)),
                      subtitle: Text('يحتفظ بأذكارك الحالية ويضيف الأذكار الجديدة إليها دون تكرار', style: AppTypography.label(p.textSecondary)),
                      value: false,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: p.primary,
                    ),
                    RadioListTile<bool>(
                      title: Text('استبدال كامل للأذكار المخصصة', style: AppTypography.meta(p.textPrimary)),
                      subtitle: Text('حذف الأذكار المخصصة الحالية ووضع أذكار النسخة الاحتياطية فقط', style: AppTypography.label(p.textSecondary)),
                      value: true,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: p.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildActionTile(
          icon: Icons.file_open_rounded,
          iconColor: p.accent,
          title: 'اختيار ملف النسخة الاحتياطية (.json)',
          subtitle: 'استرجاع فوري من ملف JSON محفوظ على الهاتف أو Google Drive',
          onTap: _pickAndImportFile,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.cardElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_rounded, size: 18, color: p.primary),
                      const SizedBox(width: 8),
                      Text('أو لصق كود JSON مباشرة', style: AppTypography.rowTitle(p.textPrimary)),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.paste_rounded, size: 16),
                    label: Text('لصق من الحافظة', style: AppTypography.label(p.accentText)),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        setState(() {
                          _pasteController.text = data.text!;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pasteController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'ألصق محتوى ملف JSON هنا...',
                  hintStyle: AppTypography.label(p.textSecondary),
                  filled: true,
                  fillColor: p.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_done_rounded, size: 18),
                  label: Text(
                    'استيراد الكود الملصق',
                    style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _importFromPastedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.hairline, width: 0.75),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.rowTitle(p.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTypography.label(p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}
