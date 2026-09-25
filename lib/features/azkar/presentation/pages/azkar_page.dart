import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
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
import '../widgets/custom_dhikr_tile.dart';
import '../widgets/daily_progress_header.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../widgets/import_backup_preview_dialog.dart';
import '../../../../core/utils/skeleton_loading.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _headerSizeAnimation;
  bool _isHeaderVisible = true;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOutCubic,
    ));
    _headerSizeAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  void _setHeaderVisibility(bool visible) {
    if (_isHeaderVisible == visible) return;
    setState(() => _isHeaderVisible = visible);
    if (visible) {
      _headerAnimController.forward();
    } else {
      _headerAnimController.reverse();
    }
  }

  void _onScroll() {
    if (_isDragging) return;
    if (!_scrollController.hasClients) return;

    // Keep header visible when near the top
    if (_scrollController.offset <= 20) {
      if (!_isHeaderVisible) {
        _setHeaderVisibility(true);
      }
      return;
    }

    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      if (_isHeaderVisible) {
        _setHeaderVisibility(false);
      }
    } else if (direction == ScrollDirection.forward) {
      if (!_isHeaderVisible) {
        _setHeaderVisibility(true);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف الذكر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${item.title}" من أذكارك المخصصة؟',
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AzkarBloc>().add(DeleteZikrItemEvent(item.id));
              AppSnackBar.showInfo(context, 'تم حذف الذكر من القائمة المخصصة');
            },
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        backgroundColor: Colors.transparent,
        title: Text(
          'الأذكار والورد اليومي',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
          ),
        ),
        actions: [
          // Primary Action: Add Custom Dhikr
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_circle_outline_rounded, size: 22, color: AppColors.primary),
            ),
            tooltip: 'إضافة ذكر جديد',
            onPressed: () {
              final state = context.read<AzkarBloc>().state;
              final cat = state is AzkarLoaded ? state.selectedCategory : AzkarCategory.custom;
              _openAddDhikr(context, cat);
            },
          ),

          // Secondary Action: Settings & Data management bottom sheet
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'خيارات وإعدادات الأذكار',
            onPressed: () {
              final state = context.read<AzkarBloc>().state;
              final cat = state is AzkarLoaded ? state.selectedCategory : AzkarCategory.morning;
              AzkarSettingsSheet.show(context, currentCategory: cat);
            },
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
                  Text(state.message, style: const TextStyle(fontFamily: 'Cairo')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AzkarBloc>().add(const LoadAzkarEvent()),
                    child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            );
          }

          if (state is AzkarLoaded) {
            final isCustomTab = state.selectedCategory == AzkarCategory.custom;

            return Column(
              children: [
                // Lightweight Category Segmented Tabs
                AzkarCategoryBar(
                  selectedCategory: state.selectedCategory,
                  onSelectCategory: (category) {
                    context.read<AzkarBloc>().add(SelectCategoryEvent(category));
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                    _setHeaderVisibility(true);
                  },
                  isDark: isDark,
                ),

                // Collapsible Progress Header (for standard categories)
                if (!isCustomTab)
                  AnimatedBuilder(
                    animation: _headerAnimController,
                    builder: (context, child) {
                      if (_headerAnimController.value == 0.0 && !_isHeaderVisible) {
                        return const SizedBox.shrink();
                      }
                      return ClipRect(
                        child: SizeTransition(
                          sizeFactor: _headerSizeAnimation,
                          axisAlignment: 0.0,
                          child: FadeTransition(
                            opacity: _headerFadeAnimation,
                            child: SlideTransition(
                              position: _headerSlideAnimation,
                              child: child,
                            ),
                          ),
                        ),
                      );
                    },
                    child: DailyProgressHeader(
                      category: state.selectedCategory,
                      completedCount: state.completedCategoryCount,
                      totalCount: state.totalCategoryCount,
                      completionRate: state.categoryCompletionRate,
                      onResetCategory: () {
                        context
                            .read<AzkarBloc>()
                            .add(ResetCategoryProgressEvent(state.selectedCategory));
                      },
                    ),
                  ),

                // Compact Custom Adhkar Section Header (when "أذكاري المخصصة" is active)
                if (isCustomTab)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'أذكاري المخصصة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'أذكار وأدعية أضفتها بنفسك',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${toArabicDigits(state.currentItems.length)} أذكار',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Content View: List or Calm Empty State
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
                      : isCustomTab
                          ? _buildCustomAdhkarList(state)
                          : _buildStandardAdhkarList(state),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Clean, lightweight list for Custom Adhkar where Arabic text is hero
  Widget _buildCustomAdhkarList(AzkarLoaded state) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: state.currentItems.length,
      itemBuilder: (context, index) {
        final item = state.currentItems[index];
        return CustomDhikrTile(
          item: item,
          onEdit: () => _openEditDhikr(context, item),
          onDelete: () => _confirmDeleteDhikr(context, item),
          onIncrement: () {
            context.read<AzkarBloc>().add(IncrementZikrCountEvent(
                  id: item.id,
                  targetCount: item.targetCount,
                  category: item.category,
                ));
          },
          onReset: () {
            context.read<AzkarBloc>().add(UpdateZikrItemEvent(
                  item.copyWith(currentCount: 0, isCompleted: false),
                ));
          },
        );
      },
    );
  }

  /// Reorderable interactive list for standard Azkar categories
  Widget _buildStandardAdhkarList(AzkarLoaded state) {
    return RefreshIndicator(
      color: AppColors.accentGold,
      onRefresh: () async {
        context.read<AzkarBloc>().add(const LoadAzkarEvent());
      },
      child: ReorderableListView.builder(
        scrollController: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        autoScrollerVelocityScalar: 140.0,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
        itemCount: state.currentItems.length,
        onReorderStart: (index) {
          HapticFeedback.heavyImpact();
          setState(() => _isDragging = true);
        },
        onReorderEnd: (index) {
          setState(() => _isDragging = false);
        },
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
          final item = state.currentItems[index];
          return AzkarCard(
            key: ValueKey(item.id),
            item: item,
            onIncrement: () {
              context.read<AzkarBloc>().add(IncrementZikrCountEvent(
                    id: item.id,
                    targetCount: item.targetCount,
                    category: item.category,
                  ));
            },
            onToggleComplete: () {
              context.read<AzkarBloc>().add(ToggleZikrCompletionEvent(
                    id: item.id,
                    targetCount: item.targetCount,
                    category: item.category,
                  ));
            },
            onEdit: () => _openEditDhikr(context, item),
          );
        },
      ),
    );
  }
}
