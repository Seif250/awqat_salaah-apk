import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../../../settings/presentation/pages/azkar_settings_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../widgets/azkar_card.dart';
import '../widgets/daily_progress_header.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../widgets/azkar_backup_dialog.dart';
import '../utils/azkar_ui_helpers.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت استعادة الأذكار الافتراضية بنجاح'),
                  duration: Duration(seconds: 2),
                ),
              );
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
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              } else if (value == 'azkar_settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AzkarSettingsPage()),
                );
              } else if (value == 'reorder') {
                setState(() => _isReorderMode = !_isReorderMode);
                if (_isReorderMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('وضع إعادة الترتيب مفعّل: اسحب الذكر لأعلى أو لأسفل.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else if (value == 'backup') {
                AzkarBackupDialog.show(context);
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
                    Icon(Icons.cloud_sync_rounded, size: 20, color: AppColors.accentGold),
                    SizedBox(width: 8),
                    Text('النسخ الاحتياطي للأذكار (JSON)'),
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGold),
            );
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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.6),
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: AzkarCategory.values.map((category) {
                        final isSelected = state.selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: FilterChip(
                            showCheckmark: false,
                            avatar: Icon(
                              category.categoryIcon,
                              size: 16,
                              color: isSelected ? AppColors.primaryLight : Colors.grey,
                            ),
                            label: Text(category.titleArabic),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight.withValues(alpha: 0.16),
                            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryLight.withValues(alpha: 0.6)
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                            labelStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) {
                              context.read<AzkarBloc>().add(SelectCategoryEvent(category));
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                            'وضع الترتيب: اضغط واسحب الذكر لتغيير مكانه',
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
                          onOpenTasbih: () {},
                        )
                      : const SizedBox.shrink(),
                ),

                // Azkar Items List
                Expanded(
                  child: state.currentItems.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 54, color: AppColors.accentGold),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد أذكار في قسم "${state.selectedCategory.titleArabic}" حالياً',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.selectedCategory == AzkarCategory.custom
                                      ? 'يمكنك إضافة ذكر مخصص جديد أو استرجاع نسخة احتياطية سابقة محفوظة بصيغة JSON'
                                      : 'يمكنك إضافة ذكر جديد إلى هذا القسم أو استعادة الأذكار الافتراضية الأصلية',
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add_rounded),
                                      label: Text(state.selectedCategory == AzkarCategory.custom
                                          ? 'إضافة ذكر مخصص'
                                          : 'إضافة ذكر هنا'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        EditZikrDialog.showAdd(
                                          context,
                                          initialCategory: state.selectedCategory,
                                          onAdd: (item) {
                                            context.read<AzkarBloc>().add(AddNewZikrItemEvent(item));
                                          },
                                        );
                                      },
                                    ),
                                    if (state.selectedCategory == AzkarCategory.custom)
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.accentGold),
                                        label: const Text('استرجاع نسخة سابقة (JSON)'),
                                        onPressed: () => AzkarBackupDialog.show(context),
                                      )
                                    else
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.restore_rounded),
                                        label: const Text('استعادة الأذكار الافتراضية'),
                                        onPressed: () => _confirmRestoreDefaults(context),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : _isReorderMode
                          // Reorderable list view in reorder mode
                          ? ReorderableListView.builder(
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
                                return AzkarCard(
                                  key: ValueKey(item.id),
                                  item: item,
                                  isReorderMode: true,
                                  onIncrement: () {},
                                  onToggleComplete: () {},
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
                            )
                          // Standard list view with scroll auto-hide and long-press to enter reorder mode
                          : ListView.builder(
                              controller: _scrollController,
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
                                          icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                                          label: const Text('نسخ احتياطي',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () => AzkarBackupDialog.show(context),
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'تم تفعيل وضع إعادة الترتيب. اسحب الذكر لأعلى أو لأسفل.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  onIncrement: () {
                                    context.read<AzkarBloc>().add(
                                          IncrementZikrCountEvent(
                                            id: item.id,
                                            targetCount: item.targetCount,
                                          ),
                                        );
                                  },
                                  onToggleComplete: () {
                                    context.read<AzkarBloc>().add(
                                          ToggleZikrCompletionEvent(
                                            id: item.id,
                                            targetCount: item.targetCount,
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
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
