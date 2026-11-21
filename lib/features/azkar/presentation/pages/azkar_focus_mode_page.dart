import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/azkar_item_model.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import '../bloc/azkar_state.dart';

/// Distraction-free reading and counting mode for Azkar.
class AzkarFocusModePage extends StatefulWidget {
  final int initialIndex;

  const AzkarFocusModePage({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AzkarFocusModePage> createState() => _AzkarFocusModePageState();
}

class _AzkarFocusModePageState extends State<AzkarFocusModePage> {
  late final PageController _pageController;
  late int _currentPage;
  String? _lastCompletedAdvanceId;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isQuranic(AzkarItem item) {
    return item.title.contains('آية') ||
        item.title.contains('المعوذات') ||
        item.title.contains('سورة') ||
        item.title.contains('خواتيم') ||
        item.title.contains('الكافرون') ||
        item.title.contains('الإخلاص') ||
        item.title.contains('الفلق') ||
        item.title.contains('الناس');
  }

  void _handleIncrement(
    BuildContext context,
    AzkarLoaded state,
    AzkarItem item,
    int index,
  ) {
    final willCompleteNow =
        !item.isCompleted && (item.currentCount + 1) >= item.targetCount;

    HapticFeedback.selectionClick();
    context.read<AzkarBloc>().add(
          IncrementZikrCountEvent(
            id: item.id,
            targetCount: item.targetCount,
            category: state.selectedCategory,
          ),
        );

    if (willCompleteNow && _lastCompletedAdvanceId != item.id) {
      _lastCompletedAdvanceId = item.id;
      HapticFeedback.heavyImpact();

      final items = state.currentItems;
      int nextIndex = -1;
      for (int i = index + 1; i < items.length; i++) {
        if (!items[i].isCompleted) {
          nextIndex = i;
          break;
        }
      }

      if (nextIndex != -1) {
        Future.delayed(const Duration(milliseconds: 380), () {
          if (mounted && _pageController.hasClients) {
            _pageController.animateToPage(
              nextIndex,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        final allOthersDone =
            items.where((e) => e.id != item.id).every((e) => e.isCompleted);
        if (allOthersDone) {
          AppSnackBar.showSuccess(
            context,
            'اكتمل ورد ${state.selectedCategory.titleArabic} بحمد الله',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocBuilder<AzkarBloc, AzkarState>(
      builder: (context, state) {
        if (state is! AzkarLoaded || state.currentItems.isEmpty) {
          return Scaffold(
            backgroundColor: p.background,
            appBar: AppBar(title: const Text('وضع التركيز')),
            body: Center(
              child: Text(
                'لا توجد أذكار في هذا القسم حالياً',
                style: AppTypography.body(p.textPrimary),
              ),
            ),
          );
        }

        final items = state.currentItems;
        final safeIndex = _currentPage.clamp(0, items.length - 1);

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.selectedCategory.titleArabic,
                  style: AppTypography.sectionHeader(p.textPrimary),
                ),
                Text(
                  '${toArabicDigits(safeIndex + 1)} / ${toArabicDigits(items.length)}',
                  style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'تصغير الخط',
                icon: Text(
                  'أ-',
                  style: AppTypography.body(p.accentText, weight: FontWeight.w700),
                ),
                onPressed: () {
                  context.read<AzkarBloc>().add(
                        ChangeAzkarFontScaleEvent(state.fontScale - 0.1),
                      );
                },
              ),
              IconButton(
                tooltip: 'تكبير الخط',
                icon: Text(
                  'أ+',
                  style: AppTypography.body(p.accentText, weight: FontWeight.w700),
                ),
                onPressed: () {
                  context.read<AzkarBloc>().add(
                        ChangeAzkarFontScaleEvent(state.fontScale + 0.1),
                      );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: state.categoryCompletionRate,
                  minHeight: 3.5,
                  backgroundColor: p.border.withValues(alpha: 0.45),
                  valueColor: AlwaysStoppedAnimation<Color>(p.primary),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentPage = idx;
                        _lastCompletedAdvanceId = null;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isQuranic = _isQuranic(item);
                      final isDone = item.isCompleted;
                      final remaining =
                          (item.targetCount - item.currentCount).clamp(0, item.targetCount);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title + Status Row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.sectionHeader(p.accentText),
                                  ),
                                ),
                                if (isDone)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.completedCardBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'مكتمل بحمد الله',
                                      style: AppTypography.badge(p.accentText),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Open Reading Canvas (no double-nested borders in focus mode)
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      item.arabicText,
                                      textAlign: TextAlign.start,
                                      textDirection: TextDirection.rtl,
                                      style: AppTypography.dhikrBody(
                                        p.textPrimary,
                                        scale: state.fontScale * 1.12,
                                        isQuranic: isQuranic,
                                      ),
                                    ),
                                    if (item.reward != null ||
                                        item.reference != null) ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                          14,
                                          6,
                                          4,
                                          6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: p.accent
                                                  .withValues(alpha: 0.7),
                                              width: 2.5,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (item.reward != null)
                                              Text(
                                                item.reward!,
                                                style: AppTypography.meta(
                                                  p.textPrimary
                                                      .withValues(alpha: 0.85),
                                                  size: 12.5,
                                                  height: 1.5,
                                                ),
                                              ),
                                            if (item.reference != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                item.reference!,
                                                style: AppTypography.meta(
                                                  p.textSecondary,
                                                  size: 11.5,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Bottom Tap Counter Button + Prev/Next
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'الذكر السابق',
                                  onPressed: index > 0
                                      ? () => _pageController.previousPage(
                                            duration: const Duration(
                                                milliseconds: 240),
                                            curve: Curves.easeOutCubic,
                                          )
                                      : null,
                                  icon: const Icon(Icons.arrow_back_ios_rounded),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Material(
                                    color: p.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _handleIncrement(
                                          context, state, item, index),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isDone
                                                  ? Icons.check_circle_rounded
                                                  : Icons.touch_app_outlined,
                                              color: p.onPrimary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                isDone
                                                    ? 'مكتمل (${toArabicDigits(item.currentCount)} / ${toArabicDigits(item.targetCount)})'
                                                    : 'التكرار: ${toArabicDigits(item.currentCount)} / ${toArabicDigits(item.targetCount)} • متبقي ${toArabicDigits(remaining)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.timeValue(
                                                  p.onPrimary,
                                                  size: 14,
                                                  weight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'الذكر التالي',
                                  onPressed: index < items.length - 1
                                      ? () => _pageController.nextPage(
                                            duration: const Duration(
                                                milliseconds: 240),
                                            curve: Curves.easeOutCubic,
                                          )
                                      : null,
                                  icon:
                                      const Icon(Icons.arrow_forward_ios_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
