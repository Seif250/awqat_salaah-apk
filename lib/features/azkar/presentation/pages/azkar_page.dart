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
import '../../../../core/utils/skeleton_loading.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/repositories/azkar_repository.dart';
import '../../data/services/backup_service.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../utils/azkar_ui_helpers.dart';
import '../widgets/azkar_card.dart';
import '../widgets/azkar_category_bar.dart';
import '../widgets/azkar_empty_view.dart';
import '../widgets/azkar_settings_sheet.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../widgets/import_backup_preview_dialog.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late final ScrollController _scrollController;
  bool _isHeroVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        toolbarHeight: 56,
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
        // Center: Clean Title
        title: Text(
          'الأذكار والورد اليومي',
          style: AppTypography.pageTitle(p.isDark ? p.textPrimary : p.primary),
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
                      : _buildAdhkarList(
                          context,
                          state,
                          state.currentItems,
                          false,
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
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      height: 74,
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

            // Clean translucent black scrim for consistent legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withValues(alpha: isDark ? 0.56 : 0.46),
                    Colors.black.withValues(alpha: isDark ? 0.78 : 0.70),
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
                        width: 96,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: state.categoryCompletionRate,
                            ),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (_, animatedValue, __) =>
                                LinearProgressIndicator(
                              value: animatedValue,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.30),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4ADE80)),
                            ),
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

  AzkarCategory _nextAzkarCategory(AzkarCategory current) {
    switch (current) {
      case AzkarCategory.morning:
        return AzkarCategory.evening;
      case AzkarCategory.evening:
        return AzkarCategory.sleep;
      case AzkarCategory.sleep:
        return AzkarCategory.morning;
      case AzkarCategory.postPrayer:
        return AzkarCategory.morning;
      case AzkarCategory.qiyam:
        return AzkarCategory.morning;
      case AzkarCategory.supplications:
        return AzkarCategory.general;
      case AzkarCategory.general:
        return AzkarCategory.supplications;
      case AzkarCategory.custom:
        return AzkarCategory.morning;
    }
  }

  Widget _buildCategoryCompletionFooter(
    BuildContext context,
    AzkarLoaded state,
  ) {
    final p = context.palette;
    final nextCategory = _nextAzkarCategory(state.selectedCategory);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.completedCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.completedCardBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.done_all_rounded, color: p.onPrimary, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            'أتممتَ ${state.selectedCategory.titleArabic}',
            style: AppTypography.sectionHeader(p.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'تقبّل الله طاعتك وجعل يومك عامرًا بذكره',
            style: AppTypography.meta(p.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(nextCategory.categoryIcon, size: 18),
                  label: Text(
                    nextCategory.titleArabic,
                    style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    context.read<AzkarBloc>().add(SelectCategoryEvent(nextCategory));
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: Icon(Icons.replay_rounded, size: 17, color: p.accentText),
                label: Text(
                  'إعادة القراءة',
                  style: AppTypography.meta(p.accentText, weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.primary.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  context.read<AzkarBloc>().add(
                        ResetCategoryProgressEvent(state.selectedCategory),
                      );
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ],
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
    final isAllDone = state.totalCategoryCount > 0 &&
        state.completedCategoryCount >= state.totalCategoryCount;
    final p = context.palette;

    final Widget? listFooter = isAllDone
        ? _buildCategoryCompletionFooter(context, state)
        : (isCustomTab
            ? Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 16),
                child: OutlinedButton.icon(
                  icon: Icon(Icons.add_rounded, color: p.accentText),
                  label: Text(
                    'إضافة ذكر جديد',
                    style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.primary.withValues(alpha: 0.35)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _openAddDhikr(context, state.selectedCategory),
                ),
              )
            : null);

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
                footer: listFooter,
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
