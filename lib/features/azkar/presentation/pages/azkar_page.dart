import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../widgets/azkar_card.dart';
import '../widgets/daily_progress_header.dart';
import '../widgets/digital_tasbih_sheet.dart';
import '../widgets/edit_zikr_dialog.dart';
import '../utils/azkar_ui_helpers.dart';

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

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
            icon: const Icon(Icons.fingerprint_rounded, color: AppColors.accentGold),
            tooltip: 'المسبحة الإلكترونية',
            onPressed: () {
              final state = context.read<AzkarBloc>().state;
              final currentTotal = state is AzkarLoaded ? state.dailyProgress.freeTasbihCount : 0;
              DigitalTasbihSheet.show(
                context,
                initialCount: currentTotal,
                onCountChanged: (delta) {
                  context.read<AzkarBloc>().add(UpdateFreeTasbihEvent(delta));
                },
                onReset: () {
                  context.read<AzkarBloc>().add(const ResetFreeTasbihEvent());
                },
              );
            },
          ),
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
              if (value == 'restore') {
                _confirmRestoreDefaults(context);
              } else if (value == 'reset_cat') {
                final state = context.read<AzkarBloc>().state;
                if (state is AzkarLoaded) {
                  context.read<AzkarBloc>().add(ResetCategoryProgressEvent(state.selectedCategory));
                }
              }
            },
            itemBuilder: (ctx) => [
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
                            avatar: Icon(category.categoryIcon, size: 16, color: isSelected ? AppColors.primaryLight : Colors.grey),
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

                // Daily Progress Header
                DailyProgressHeader(
                  category: state.selectedCategory,
                  completedCount: state.completedCategoryCount,
                  totalCount: state.totalCategoryCount,
                  completionRate: state.categoryCompletionRate,
                  onResetCategory: () {
                    context
                        .read<AzkarBloc>()
                        .add(ResetCategoryProgressEvent(state.selectedCategory));
                  },
                  onOpenTasbih: () {
                    DigitalTasbihSheet.show(
                      context,
                      initialCount: state.dailyProgress.freeTasbihCount,
                      onCountChanged: (delta) {
                        context.read<AzkarBloc>().add(UpdateFreeTasbihEvent(delta));
                      },
                      onReset: () {
                        context.read<AzkarBloc>().add(const ResetFreeTasbihEvent());
                      },
                    );
                  },
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
                                const Text(
                                  'يمكنك إضافة ذكر جديد إلى هذا القسم أو استعادة الأذكار الافتراضية الأصلية',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
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
                                      label: const Text('إضافة ذكر هنا'),
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                          itemCount: state.currentItems.length,
                          itemBuilder: (context, index) {
                            final item = state.currentItems[index];
                            return AzkarCard(
                              key: ValueKey(item.id),
                              item: item,
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
