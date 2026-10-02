import 'dart:ui' show ImageFilter, lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
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
        // Right side (in RTL): Add button (Deep green circle with white +)
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
                    color: isDark ? const Color(0xFF1B4D3E) : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
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
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 19.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              'قربًا من الله .. في كل وقت',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
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
                      color: isDark ? Colors.white10 : const Color(0xFFF2F4F3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
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
                // Top Horizontally Scrollable Segmented Category Tabs
                AzkarCategoryBar(
                  selectedCategory: state.selectedCategory,
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

                // Content View: Reorderable Adhkar List or Calm Empty State
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
                      : _buildAdhkarList(context, state, isDark),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Compact & Elegant Section Hero Banner matching the mockup screenshot
  Widget _buildAzkarHeroHeader(BuildContext context, AzkarLoaded state, bool isDark) {
    final isAllDone = state.totalCategoryCount > 0 &&
        state.completedCategoryCount >= state.totalCategoryCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // AI-generated grand mosque archway & morning sunlight
            Image.asset(
              'assets/images/azkar_header_card.jpg',
              fit: BoxFit.cover,
            ),

            // Light blur & transparent gradient overlay for readability
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.black.withValues(alpha: isDark ? 0.58 : 0.42),
                      AppColors.primaryDark.withValues(alpha: isDark ? 0.75 : 0.62),
                    ],
                  ),
                ),
              ),
            ),

            // Content inside the hero banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Row 1: Right Title with Sun Icon & Left Completion Capsule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Right: Icon + Title with graceful fade and slide animation
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
                              const Icon(
                                Icons.wb_sunny_rounded,
                                size: 20,
                                color: Color(0xFFFDE047),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.selectedCategory.titleArabic,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Left: Dark capsule with checkmark and completion text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAllDone
                                ? const Color(0xFF4ADE80).withValues(alpha: 0.6)
                                : Colors.white24,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: isAllDone ? const Color(0xFF4ADE80) : const Color(0xFF34D399),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAllDone
                                  ? 'مكتمل بحمد الله'
                                  : '${toArabicDigits(state.completedCategoryCount)} / ${toArabicDigits(state.totalCategoryCount)} مكتملة',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Row 2: Subtitle time description
                  Text(
                    state.selectedCategory.timeDescription,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Row 3: Clean progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.categoryCompletionRate,
                      minHeight: 5.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.35),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reorderable interactive list for standard and custom Adhkar
  Widget _buildAdhkarList(BuildContext context, AzkarLoaded state, bool isDark) {
    final isCustomTab = state.selectedCategory == AzkarCategory.custom;

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          if (notification.direction == ScrollDirection.reverse) {
            // Scrolling down through list -> hide progress bar
            if (_isHeroVisible) {
              setState(() => _isHeroVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            // Scrolling up towards top -> show progress bar
            if (!_isHeroVisible) {
              setState(() => _isHeroVisible = true);
            }
          }
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.accentGold,
        onRefresh: () async {
          context.read<AzkarBloc>().add(const LoadAzkarEvent());
        },
        child: ReorderableListView.builder(
          scrollController: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          autoScrollerVelocityScalar: 140.0,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: state.currentItems.length,
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
          final item = state.currentItems[index];
          final isItemCustom = isCustomTab || item.isCustom;

          return ReorderableDelayedDragStartListener(
            key: ValueKey(item.id),
            index: index,
            child: AzkarCard(
              item: item,
              itemIndex: index + 1,
              reorderIndex: index,
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
              onShare: () {
                Clipboard.setData(ClipboardData(
                  text: '${item.title}\n\n${item.arabicText}\n\n${item.reward != null ? "من فضلها: ${item.reward}\n" : ""}${item.reference != null ? "المصدر: ${item.reference}" : ""}',
                ));
                AppSnackBar.showInfo(context, 'تم نسخ نص الذكر للمشاركة بنجاح');
              },
              onEdit: () => _openEditDhikr(context, item),
              onDelete: isItemCustom ? () => _confirmDeleteDhikr(context, item) : null,
            ),
          );
        },
      ),
      ),
    );
  }
}
