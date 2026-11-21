import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/skeleton_loading.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/repositories/azkar_repository.dart';
import '../../data/services/backup_service.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../widgets/azkar_card.dart';
import '../widgets/azkar_category_bar.dart';
import '../widgets/azkar_empty_view.dart';
import '../widgets/azkar_settings_sheet.dart';
import '../widgets/digital_tasbih_sheet.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../widgets/import_backup_preview_dialog.dart';
import 'azkar_focus_mode_page.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  bool _isHeroVisible = true;
  bool _isSearchExpanded = false;
  bool _hideCompleted = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  List<AzkarItem> _applyFilters(List<AzkarItem> items) {
    final normalizedQuery = _normalizeArabic(_searchQuery.trim());
    return items.where((item) {
      if (_hideCompleted && item.isCompleted) return false;
      if (normalizedQuery.isNotEmpty) {
        final haystack = _normalizeArabic(
          '${item.title} ${item.arabicText} ${item.reward ?? ''} ${item.reference ?? ''}',
        );
        if (!haystack.contains(normalizedQuery)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _shareZikr(BuildContext context, AzkarItem item) async {
    final buffer = StringBuffer()
      ..writeln(item.title)
      ..writeln()
      ..writeln(item.arabicText);
    if (item.reward != null && item.reward!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('من فضلها: ${item.reward}');
    }
    if (item.reference != null && item.reference!.isNotEmpty) {
      buffer.writeln('المصدر: ${item.reference}');
    }
    final text = buffer.toString().trim();
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: item.title),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        AppSnackBar.showInfo(context, 'تم نسخ نص الذكر للمشاركة بنجاح');
      }
    }
  }

  void _openDigitalTasbih(BuildContext context, AzkarLoaded state) {
    final azkarBloc = context.read<AzkarBloc>();
    DigitalTasbihSheet.show(
      context,
      initialCount: state.dailyProgress.freeTasbihCount,
      onCountChanged: (delta) => azkarBloc.add(UpdateFreeTasbihEvent(delta)),
      onReset: () => azkarBloc.add(const ResetFreeTasbihEvent()),
    );
  }

  void _openFocusMode(BuildContext context) {
    final azkarBloc = context.read<AzkarBloc>();
    Navigator.of(context).push(
      FadeSlidePageRoute(
        page: BlocProvider<AzkarBloc>.value(
          value: azkarBloc,
          child: const AzkarFocusModePage(),
        ),
      ),
    );
  }

  void _openAddDhikr(BuildContext context, AzkarCategory currentCat) {
    EditZikrDialog.showAdd(
      context,
      initialCategory: currentCat,
      onAdd: (item) {
        context.read<AzkarBloc>().add(AddNewZikrItemEvent(item));
        AppSnackBar.showSuccess(context, 'تمت إضافة الذكر بنجاح');
      },
    );
  }

  void _openEditDhikr(BuildContext context, AzkarItem item) {
    EditZikrDialog.show(
      context,
      item: item,
      onSave: (updated) {
        context.read<AzkarBloc>().add(UpdateZikrItemEvent(updated));
        AppSnackBar.showSuccess(context, 'تم تعديل الذكر بنجاح');
      },
      onDelete: () {
        context.read<AzkarBloc>().add(DeleteZikrItemEvent(item.id));
        AppSnackBar.showInfo(context, 'تم حذف الذكر');
      },
    );
  }

  void _confirmDeleteDhikr(BuildContext context, AzkarItem item) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: p.error),
            const SizedBox(width: 8),
            Text('حذف الذكر', style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${item.title}" من أذكارك المخصصة؟',
          style: AppTypography.body(p.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AzkarBloc>().add(DeleteZikrItemEvent(item.id));
              AppSnackBar.showInfo(context, 'تم حذف الذكر من القائمة المخصصة');
            },
            child: Text(
              'حذف',
              style: AppTypography.meta(Colors.white, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleImportFromEmptyState(BuildContext context) async {
    final repo = context.read<AzkarRepository>();
    final existingItems = repo.getCustomAzkarItems();

    try {
      final analysis = await BackupService.pickAndValidateBackup(existingItems: existingItems);
      if (analysis == null) return;

      if (!context.mounted) return;
      await ImportBackupPreviewDialog.show(
        context,
        analysis: analysis,
        onConfirm: (replaceExisting) async {
          final count = await BackupService.executeImport(
            context: context,
            analysis: analysis,
            replaceExisting: replaceExisting,
          );

          if (!context.mounted) return;
          context.read<AzkarBloc>().add(const LoadAzkarEvent());

          if (replaceExisting) {
            AppSnackBar.showSuccess(context, 'تم استبدال واستيراد $count أذكار بنجاح');
          } else {
            final skipped = analysis.duplicateItems.length;
            final message = skipped > 0
                ? 'تمت إضافة $count أذكار (تم تجاهل $skipped مكرر)'
                : 'تمت إضافة $count أذكار بنجاح';
            AppSnackBar.showSuccess(context, message);
          }
        },
      );
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          'تعذر استيراد النسخة الاحتياطية. الملف غير صالح أو غير متوافق.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        // Right side (in RTL): Add button
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 14),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final state = context.read<AzkarBloc>().state;
                  final cat = state is AzkarLoaded ? state.selectedCategory : AzkarCategory.custom;
                  _openAddDhikr(context, cat);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 22, color: p.accentText),
                ),
              ),
            ),
          ),
        ),
        // Center: Title + Subtitle
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الأذكار والورد اليومي',
              style: AppTypography.pageTitle(p.isDark ? p.textPrimary : p.primary),
            ),
            const SizedBox(height: 1),
            Text(
              'قربًا من الله .. في كل وقت',
              style: AppTypography.meta(p.textSecondary),
            ),
          ],
        ),
        // Left side (in RTL): 3 dots Menu button
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final state = context.read<AzkarBloc>().state;
                    final cat = state is AzkarLoaded ? state.selectedCategory : AzkarCategory.morning;
                    AzkarSettingsSheet.show(context, currentCategory: cat);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: p.cardElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AzkarBloc, AzkarState>(
        builder: (context, state) {
          if (state is AzkarLoading || state is AzkarInitial) {
            return const AzkarSkeleton();
          }

          if (state is AzkarError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTypography.body(p.textPrimary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AzkarBloc>().add(const LoadAzkarEvent()),
                    child: Text('إعادة المحاولة', style: AppTypography.meta(p.onPrimary)),
                  ),
                ],
              ),
            );
          }

          if (state is AzkarLoaded) {
            final isCustomTab = state.selectedCategory == AzkarCategory.custom;
            final filteredItems = _applyFilters(state.currentItems);
            final isFiltered = _searchQuery.trim().isNotEmpty || _hideCompleted;

            return Column(
              children: [
                // Top Horizontally Scrollable Segmented Category Tabs
                AzkarCategoryBar(
                  selectedCategory: state.selectedCategory,
                  completedCategories: state.completedCategories,
                  onSelectCategory: (category) {
                    setState(() => _isHeroVisible = true);
                    context.read<AzkarBloc>().add(SelectCategoryEvent(category));
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                  isDark: isDark,
                ),

                // Hero Islamic Progress Banner with smooth slide and fade animation
                AnimatedCrossFade(
                  firstChild: _buildAzkarHeroHeader(context, state, isDark),
                  secondChild: const SizedBox(width: double.infinity, height: 0),
                  crossFadeState: _isHeroVisible
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 350),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeInCubic,
                  sizeCurve: Curves.easeInOutCubic,
                ),

                // Compact Utility Bar (Search, Remaining filter, Font size, Focus Mode, Tasbih)
                if (state.currentItems.isNotEmpty)
                  _buildUtilityBar(context, state, isDark),

                // Expandable Search Field
                if (_isSearchExpanded && state.currentItems.isNotEmpty)
                  _buildSearchBar(isDark),

                // Content View: Adhkar List or Empty State
                Expanded(
                  child: state.currentItems.isEmpty
                      ? AzkarEmptyView(
                          category: state.selectedCategory,
                          onAdd: () => _openAddDhikr(context, state.selectedCategory),
                          onRestore: () {
                            context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
                            AppSnackBar.showSuccess(context, 'تمت استعادة الأذكار الافتراضية');
                          },
                          onRestoreBackup: isCustomTab
                              ? () => _handleImportFromEmptyState(context)
                              : null,
                        )
                      : filteredItems.isEmpty
                          ? _buildFilteredEmptyView(isDark)
                          : _buildAdhkarList(
                              context,
                              state,
                              filteredItems,
                              isFiltered,
                              isDark,
                            ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  ({IconData icon, Color iconColor, Color tintColor, String imageAsset}) _heroVisualForCategory(
      AzkarCategory category) {
    switch (category) {
      case AzkarCategory.morning:
        return (
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFFDE047),
          tintColor: const Color(0xFF0F3D2B),
          imageAsset: 'assets/images/azkar_header_card.jpg',
        );
      case AzkarCategory.evening:
        return (
          icon: Icons.wb_twilight_rounded,
          iconColor: const Color(0xFFFDBA74),
          tintColor: const Color(0xFF2D2538),
          imageAsset: 'assets/images/azkar_evening.jpg',
        );
      case AzkarCategory.postPrayer:
        return (
          icon: Icons.mosque_rounded,
          iconColor: const Color(0xFF4ADE80),
          tintColor: const Color(0xFF0A3622),
          imageAsset: 'assets/images/serene_mihrab.jpg',
        );
      case AzkarCategory.sleep:
        return (
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF93C5FD),
          tintColor: const Color(0xFF152238),
          imageAsset: 'assets/images/azkar_night.jpg',
        );
      case AzkarCategory.qiyam:
        return (
          icon: Icons.dark_mode_rounded,
          iconColor: const Color(0xFFC4B5FD),
          tintColor: const Color(0xFF1E1A33),
          imageAsset: 'assets/images/azkar_night.jpg',
        );
      case AzkarCategory.supplications:
        return (
          icon: Icons.auto_awesome_rounded,
          iconColor: const Color(0xFFFCD34D),
          tintColor: const Color(0xFF332612),
          imageAsset: 'assets/images/azkar_dua.jpg',
        );
      case AzkarCategory.general:
        return (
          icon: Icons.all_inclusive_rounded,
          iconColor: const Color(0xFF5EEAD4),
          tintColor: const Color(0xFF0F3834),
          imageAsset: 'assets/images/azkar_dua.jpg',
        );
      case AzkarCategory.custom:
        return (
          icon: Icons.bookmark_rounded,
          iconColor: const Color(0xFFFDE047),
          tintColor: const Color(0xFF165B44),
          imageAsset: 'assets/images/azkar_dua.jpg',
        );
    }
  }

  /// Compact & Elegant Section Hero Banner with category-aware image and identity
  Widget _buildAzkarHeroHeader(BuildContext context, AzkarLoaded state, bool isDark) {
    final p = context.palette;
    final isAllDone = state.totalCategoryCount > 0 &&
        state.completedCategoryCount >= state.totalCategoryCount;
    final visual = _heroVisualForCategory(state.selectedCategory);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: p.shadowColor.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Contextual atmospheric scene for the active Azkar category
            Image.asset(
              visual.imageAsset,
              fit: BoxFit.cover,
            ),

            // Soft directional palette-harmonized gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    visual.tintColor.withValues(alpha: isDark ? 0.78 : 0.72),
                    p.primaryDark.withValues(alpha: isDark ? 0.88 : 0.82),
                  ],
                ),
              ),
            ),

            // Content inside the compact hero banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: Category Title & Completion Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        opacity: _isHeroVisible ? 1.0 : 0.0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          offset: _isHeroVisible ? Offset.zero : const Offset(0.1, -0.2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                visual.icon,
                                size: 17,
                                color: visual.iconColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                state.selectedCategory.titleArabic,
                                style: AppTypography.rowTitle(Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: isAllDone ? const Color(0xFF4ADE80) : const Color(0xFF86EFAC),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAllDone
                                  ? 'مكتمل بحمد الله'
                                  : '${toArabicDigits(state.completedCategoryCount)} / ${toArabicDigits(state.totalCategoryCount)} مكتملة',
                              style: AppTypography.badge(Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Row 2: Subtitle time description + progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.selectedCategory.timeDescription,
                          style: AppTypography.label(
                            Colors.white.withValues(alpha: 0.88),
                            weight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: state.categoryCompletionRate,
                            minHeight: 4.5,
                            backgroundColor: Colors.white.withValues(alpha: 0.30),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityBar(
    BuildContext context,
    AzkarLoaded state,
    bool isDark,
  ) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Search toggle
          _buildUtilityChip(
            isDark: isDark,
            icon: _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
            label: 'بحث',
            isActive: _isSearchExpanded || _searchQuery.isNotEmpty,
            onTap: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 6),

          // Hide completed filter
          _buildUtilityChip(
            isDark: isDark,
            icon: _hideCompleted
                ? Icons.visibility_off_rounded
                : Icons.filter_list_rounded,
            label: 'المتبقي فقط',
            isActive: _hideCompleted,
            onTap: () {
              setState(() => _hideCompleted = !_hideCompleted);
            },
          ),
          const SizedBox(width: 6),

          // Font scale controls
          Builder(builder: (context) {
            final p = context.palette;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: p.cardElevated,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.read<AzkarBloc>().add(
                          ChangeAzkarFontScaleEvent(state.fontScale - 0.08),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      child: Text(
                        'أ-',
                        style: AppTypography.label(p.accentText, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 14,
                    color: p.hairline,
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.read<AzkarBloc>().add(
                          ChangeAzkarFontScaleEvent(state.fontScale + 0.08),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      child: Text(
                        'أ+',
                        style: AppTypography.label(p.accentText, weight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(width: 6),

          // Focus mode button
          _buildUtilityChip(
            isDark: isDark,
            icon: Icons.center_focus_strong_outlined,
            label: 'وضع التركيز',
            isActive: false,
            onTap: () => _openFocusMode(context),
          ),
          const SizedBox(width: 6),

          // Quick Digital Tasbih button
          _buildUtilityChip(
            isDark: isDark,
            icon: Icons.fingerprint_rounded,
            label: 'المسبحة',
            isActive: false,
            onTap: () => _openDigitalTasbih(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilityChip({
    required bool isDark,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final p = context.palette;
        final fgColor = isActive ? p.accentText : p.textSecondary;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? p.primaryContainer : p.cardElevated,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: fgColor),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTypography.label(
                      fgColor,
                      weight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: AppTypography.body(p.textPrimary),
        decoration: InputDecoration(
          hintText: 'ابحث في أذكار هذا القسم...',
          hintStyle: AppTypography.meta(p.textSecondary.withValues(alpha: 0.7)),
          prefixIcon: Icon(Icons.search_rounded, size: 19, color: p.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: p.textSecondary),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: p.cardElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.hairline, width: 0.75),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: p.hairline, width: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyView(bool isDark) {
    final p = context.palette;
    final isOnlyCompletedHidden = _hideCompleted && _searchQuery.trim().isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnlyCompletedHidden
                  ? Icons.check_circle_outline_rounded
                  : Icons.search_off_rounded,
              size: 46,
              color: p.accent,
            ),
            const SizedBox(height: 12),
            Text(
              isOnlyCompletedHidden
                  ? 'اكتملت جميع أذكار هذا القسم بحمد الله'
                  : 'لا توجد نتائج مطابقة للبحث',
              textAlign: TextAlign.center,
              style: AppTypography.rowTitle(p.textPrimary),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _hideCompleted = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: Text(
                'عرض كل الأذكار',
                style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reorderable interactive list for standard and custom Adhkar (plain ListView when filtered)
  Widget _buildAdhkarList(
    BuildContext context,
    AzkarLoaded state,
    List<AzkarItem> items,
    bool isFiltered,
    bool isDark,
  ) {
    final isCustomTab = state.selectedCategory == AzkarCategory.custom;

    Widget buildCard(AzkarItem item, int index) {
      final isItemCustom = isCustomTab || item.isCustom;
      return AzkarCard(
        key: ValueKey(item.id),
        item: item,
        itemIndex: index + 1,
        reorderIndex: isFiltered ? null : index,
        fontScale: state.fontScale,
        onIncrement: () {
          context.read<AzkarBloc>().add(IncrementZikrCountEvent(
                id: item.id,
                targetCount: item.targetCount,
                category: state.selectedCategory,
              ));
        },
        onDecrement: () {
          context.read<AzkarBloc>().add(DecrementZikrCountEvent(
                id: item.id,
                targetCount: item.targetCount,
                category: state.selectedCategory,
              ));
        },
        onToggleComplete: () {
          context.read<AzkarBloc>().add(ToggleZikrCompletionEvent(
                id: item.id,
                targetCount: item.targetCount,
                category: state.selectedCategory,
              ));
        },
        onBookmark: () {
          Clipboard.setData(ClipboardData(
            text: '${item.title}\n\n${item.arabicText}\n\n${item.reward ?? ""}',
          ));
          AppSnackBar.showSuccess(context, 'تم حفظ الذكر ونسخه إلى الحافظة');
        },
        onShare: () => _shareZikr(context, item),
        onEdit: () => _openEditDhikr(context, item),
        onDelete: isItemCustom ? () => _confirmDeleteDhikr(context, item) : null,
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isHeroVisible) {
              setState(() => _isHeroVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isHeroVisible) {
              setState(() => _isHeroVisible = true);
            }
          }
        }
        return false;
      },
      child: RefreshIndicator(
        color: context.palette.primary,
        onRefresh: () async {
          context.read<AzkarBloc>().add(const LoadAzkarEvent());
        },
        child: isFiltered
            ? ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: items.length,
                itemBuilder: (context, index) => buildCard(items[index], index),
              )
            : ReorderableListView.builder(
                scrollController: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                autoScrollerVelocityScalar: 140.0,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: items.length,
                onReorderStart: (index) {
                  HapticFeedback.heavyImpact();
                },
                onReorderEnd: (index) {},
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.selectionClick();
                  context.read<AzkarBloc>().add(
                        ReorderAzkarEvent(
                          category: state.selectedCategory,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                      );
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, animChild) {
                      final animValue = Curves.easeOutCubic.transform(animation.value);
                      final elevation = lerpDouble(0, 12, animValue)!;
                      final scale = lerpDouble(1.0, 1.025, animValue)!;
                      return Transform.scale(
                        scale: scale,
                        child: Material(
                          elevation: elevation,
                          color: Colors.transparent,
                          shadowColor: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        ),
                      );
                    },
                  );
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: buildCard(item, index),
                  );
                },
              ),
      ),
    );
  }
}
