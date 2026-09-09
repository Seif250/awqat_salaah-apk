import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';
import '../widgets/add_custom_zikr_dialog.dart';
import '../widgets/azkar_card.dart';
import '../widgets/daily_progress_header.dart';
import '../widgets/digital_tasbih_sheet.dart';

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('📿 ', style: TextStyle(fontSize: 20)),
            Text(
              'الأذكار والورد اليومي',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.touch_app_rounded, color: AppColors.accentGold),
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
            tooltip: 'إضافة ذكر مخصص',
            onPressed: () {
              AddCustomZikrDialog.show(
                context,
                onAdd: (zikr) {
                  context.read<AzkarBloc>().add(AddCustomZikrEvent(zikr));
                },
              );
            },
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
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: AzkarCategory.values.map((category) {
                        final isSelected = state.selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            avatar: Text(category.iconAssetOrEmoji, style: const TextStyle(fontSize: 14)),
                            label: Text(category.titleArabic),
                            selected: isSelected,
                            selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primaryLight,
                            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            labelStyle: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bookmark_add_outlined, size: 54, color: AppColors.accentGold),
                              const SizedBox(height: 16),
                              Text(
                                state.selectedCategory == AzkarCategory.custom
                                    ? 'لم تضف أذكاراً مخصصة بعد'
                                    : 'لا توجد أذكار مسجلة',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              if (state.selectedCategory == AzkarCategory.custom)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('إضافة ذكرك الأول'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    AddCustomZikrDialog.show(
                                      context,
                                      onAdd: (zikr) {
                                        context.read<AzkarBloc>().add(AddCustomZikrEvent(zikr));
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.touch_app_rounded, color: AppColors.accentGold),
        label: const Text(
          'مسبحة إلكترونية',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
    );
  }
}
