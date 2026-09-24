import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../data/models/azkar_item_model.dart';
import '../../../settings/presentation/pages/azkar_settings_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../widgets/azkar_card.dart';
import '../widgets/azkar_category_bar.dart';
import '../widgets/azkar_empty_view.dart';
import '../widgets/daily_progress_header.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../../data/services/azkar_backup_service.dart';
import '../../../../core/utils/skeleton_loading.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late final ScrollController _scrollController;
  bool _isHeaderVisible = true;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isReorderMode) return;
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      if (_isHeaderVisible) {
        setState(() => _isHeaderVisible = false);
      }
    } else if (direction == ScrollDirection.forward) {
      if (!_isHeaderVisible) {
        setState(() => _isHeaderVisible = true);
      }
    }
  }

  void _confirmRestoreDefaults(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('استعادة الأذكار الأصلية'),
          ],
        ),
        content: const Text(
          'هل تريد استعادة جميع أذكار السنة النبوية الافتراضية؟\n\n'
          'سيتم استرجاع جميع الأذكار الأصلية مع الاحتفاظ بالأذكار التي قمت بإضافتها بنفسك.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              AppSnackBar.showSuccess(context, 'تمت استعادة الأذكار الافتراضية بنجاح');
            },
            child: const Text('استعادة'),
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
        title: Text(
          'الأذكار والورد اليومي',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'إضافة ذكر جديد',
            onPressed: () {
              final state = context.read<AzkarBloc>().state;
              final cat = state is AzkarLoaded ? state.selectedCategory : AzkarCategory.morning;
              EditZikrDialog.showAdd(
                context,
                initialCategory: cat,
                onAdd: (item) {
                  context.read<AzkarBloc>().add(AddNewZikrItemEvent(item));
                },
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'خيارات إضافية',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: const SettingsPage()),
                );
              } else if (value == 'azkar_settings') {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: const AzkarSettingsPage()),
                );
              } else if (value == 'reorder') {
                setState(() => _isReorderMode = !_isReorderMode);
                if (_isReorderMode) {
                  AppSnackBar.showInfo(context, 'وضع إعادة الترتيب مفعّل: اسحب الذكر لأعلى أو لأسفل.');
                }
              } else if (value == 'backup') {
                AzkarBackupService.performBackupFlow(context);
              } else if (value == 'restore_backup') {
                AzkarBackupService.performRestoreFlow(context);
              } else if (value == 'restore') {
                _confirmRestoreDefaults(context);
              } else if (value == 'reset_cat') {
                final state = context.read<AzkarBloc>().state;
                if (state is AzkarLoaded) {
                  context.read<AzkarBloc>().add(ResetCategoryProgressEvent(state.selectedCategory));
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                    const SizedBox(width: 8),
                    const Text('الإعدادات العامة'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'azkar_settings',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                    const SizedBox(width: 8),
                    const Text('إعدادات الأذكار والتنبيهات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reorder',
                child: Row(
                  children: [
                    Icon(
                      _isReorderMode ? Icons.check_circle_outline_rounded : Icons.swap_vert_rounded,
                      size: 20,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 8),
                    Text(_isReorderMode ? 'إنهاء إعادة الترتيب' : 'إعادة ترتيب الأذكار'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.save_alt_rounded, size: 20, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text('النسخ الاحتياطي للأذكار (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore_backup',
                child: Row(
                  children: [
                    Icon(Icons.file_open_rounded, size: 20, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text('استرجاع نسخة سابقة (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded, size: 20, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text('استعادة الأذكار الافتراضية'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_cat',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 20, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('تصفير عدادات هذا القسم'),
                  ],
                ),
              ),
            ],
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
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<AzkarBloc>().add(const LoadAzkarEvent()),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is AzkarLoaded) {
            return Column(
              children: [
                // Category Chips Selector Bar
                AzkarCategoryBar(
                  selectedCategory: state.selectedCategory,
                  onSelectCategory: (category) {
                    context.read<AzkarBloc>().add(SelectCategoryEvent(category));
                  },
                  isDark: isDark,
                ),

                // Reorder Mode Active Banner
                if (_isReorderMode)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: isDark ? 0.16 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: AppColors.accentGold, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'وضع إعادة الترتيب: يمكنك السحب بالأيقونة أو استخدام الأسهم ⬆ ⬇',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => setState(() => _isReorderMode = false),
                          child: const Text('تم'),
                        ),
                      ],
                    ),
                  ),

                // Collapsible Daily Progress Header on Scroll
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: (_isHeaderVisible && !_isReorderMode)
                      ? DailyProgressHeader(
                          category: state.selectedCategory,
                          completedCount: state.completedCategoryCount,
                          totalCount: state.totalCategoryCount,
                          completionRate: state.categoryCompletionRate,
                          onResetCategory: () {
                            context
                                .read<AzkarBloc>()
                                .add(ResetCategoryProgressEvent(state.selectedCategory));
                          },
                        )
                      : const SizedBox.shrink(),
                ),

                // Azkar Items List
                Expanded(
                  child: state.currentItems.isEmpty
                      ? AzkarEmptyView(
                          category: state.selectedCategory,
                          onAdd: () {
                            EditZikrDialog.showAdd(
                              context,
                              initialCategory: state.selectedCategory,
                              onAdd: (item) {
                                context.read<AzkarBloc>().add(AddNewZikrItemEvent(item));
                              },
                            );
                          },
                          onRestore: () => _confirmRestoreDefaults(context),
                          onRestoreBackup: state.selectedCategory == AzkarCategory.custom
                              ? () => AzkarBackupService.performRestoreFlow(context)
                              : null,
                        )
                      : _isReorderMode
                          // Reorderable list view in reorder mode
                          ? ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                              itemCount: state.currentItems.length,
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
                              itemBuilder: (context, index) {
                                final item = state.currentItems[index];
                                return ReorderableDragStartListener(
                                  key: ValueKey(item.id),
                                  index: index,
                                  child: AzkarCard(
                                    item: item,
                                    isReorderMode: true,
                                    reorderIndex: index,
                                    onMoveUp: index > 0
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            context.read<AzkarBloc>().add(
                                                  MoveZikrItemEvent(
                                                    category: state.selectedCategory,
                                                    fromIndex: index,
                                                    toIndex: index - 1,
                                                  ),
                                                );
                                          }
                                        : null,
                                    onMoveDown: index < state.currentItems.length - 1
                                        ? () {
                                            HapticFeedback.selectionClick();
                                            context.read<AzkarBloc>().add(
                                                  MoveZikrItemEvent(
                                                    category: state.selectedCategory,
                                                    fromIndex: index,
                                                    toIndex: index + 1,
                                                  ),
                                                );
                                          }
                                        : null,
                                    onIncrement: () {},
                                    onToggleComplete: () {},
                                    onEdit: null,
                                  ),
                                );
                              },
                            )
                          // Standard list view with scroll auto-hide and long-press to enter reorder mode
                          : RefreshIndicator(
                              color: AppColors.accentGold,
                              onRefresh: () async {
                                context.read<AzkarBloc>().add(const LoadAzkarEvent());
                              },
                              child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                              itemCount: state.selectedCategory == AzkarCategory.custom
                                  ? state.currentItems.length + 1
                                  : state.currentItems.length,
                              itemBuilder: (context, index) {
                                if (state.selectedCategory == AzkarCategory.custom && index == 0) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shield_outlined, size: 20, color: AppColors.accentGold),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'أذكارك المخصصة (${state.currentItems.length})',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            foregroundColor: AppColors.accentGold,
                                          ),
                                          icon: const Icon(Icons.save_alt_rounded, size: 18),
                                          label: const Text('نسخ احتياطي',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => AzkarBackupService.performBackupFlow(context),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                final item = state.currentItems[
                                    state.selectedCategory == AzkarCategory.custom ? index - 1 : index];
                                return AzkarCard(
                                  key: ValueKey(item.id),
                                  item: item,
                                  onLongPress: () {
                                    setState(() => _isReorderMode = true);
                                    AppSnackBar.showInfo(context, 'تم تفعيل وضع إعادة الترتيب. اسحب الذكر أو استخدم الأسهم.');
                                  },
                                  onIncrement: () {
                                    context.read<AzkarBloc>().add(
                                          IncrementZikrCountEvent(
                                            id: item.id,
                                            targetCount: item.targetCount,
                                            category: state.selectedCategory,
                                          ),
                                        );
                                  },
                                  onToggleComplete: () {
                                    context.read<AzkarBloc>().add(
                                          ToggleZikrCompletionEvent(
                                            id: item.id,
                                            targetCount: item.targetCount,
                                            category: state.selectedCategory,
                                          ),
                                        );
                                  },
                                  onEdit: () {
                                    EditZikrDialog.show(
                                      context,
                                      item: item,
                                      onSave: (updated) {
                                        context.read<AzkarBloc>().add(UpdateZikrItemEvent(updated));
                                      },
                                      onDelete: () {
                                        context.read<AzkarBloc>().add(DeleteZikrItemEvent(item.id));
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          }

          // Unexpected state — show a helpful fallback
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.accentGold),
                const SizedBox(height: 16),
                const Text(
                  'جاري تحميل الأذكار...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة التحميل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => context.read<AzkarBloc>().add(const LoadAzkarEvent()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
