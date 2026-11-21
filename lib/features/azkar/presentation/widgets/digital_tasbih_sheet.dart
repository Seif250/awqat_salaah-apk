import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';

class DigitalTasbihSheet extends StatefulWidget {
  final int initialCount;
  final Function(int delta) onCountChanged;
  final VoidCallback onReset;

  const DigitalTasbihSheet({
    super.key,
    required this.initialCount,
    required this.onCountChanged,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialCount,
    required Function(int delta) onCountChanged,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DigitalTasbihSheet(
        initialCount: initialCount,
        onCountChanged: onCountChanged,
        onReset: onReset,
      ),
    );
  }

  @override
  State<DigitalTasbihSheet> createState() => _DigitalTasbihSheetState();
}

class _DigitalTasbihSheetState extends State<DigitalTasbihSheet> {
  late int _sessionCount;
  late int _todayTotal;
  int _target = 33;
  int _selectedZikrIndex = 0;

  final List<String> _zikrPresets = const [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'اللَّهُ أَكْبَرُ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
  ];

  @override
  void initState() {
    super.initState();
    _sessionCount = 0;
    _todayTotal = widget.initialCount;
  }

  void _increment() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionCount++;
      _todayTotal++;
      if (_target > 0 && _sessionCount % _target == 0) {
        HapticFeedback.heavyImpact();
      }
    });
    widget.onCountChanged(1);
  }

  void _resetSession() {
    HapticFeedback.vibrate();
    setState(() {
      _sessionCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final rounds = _target > 0 ? (_sessionCount / _target).floor() : 0;
    final progressInRound =
        _target > 0 ? (_sessionCount % _target) : _sessionCount;
    final double ringProgress = _target > 0
        ? (progressInRound == 0 && _sessionCount > 0
            ? 1.0
            : progressInRound / _target)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: p.border,
          width: 1,
        ),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header + Today total
          Row(
            children: [
              Icon(Icons.fingerprint_rounded, size: 22, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المسبحة الإلكترونية',
                      style: AppTypography.sectionHeader(p.textPrimary),
                    ),
                    Text(
                      'إجمالي تسبيح اليوم: ${toArabicDigits(_todayTotal)}',
                      style: AppTypography.meta(p.accentText,
                          weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: p.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preset Dhikr Selector Horizontal Scroll
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _zikrPresets.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedZikrIndex;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(_zikrPresets[index]),
                    selected: isSelected,
                    selectedColor: p.primaryContainer,
                    backgroundColor: p.cardElevated,
                    side: BorderSide(
                      color: isSelected
                          ? p.primary.withValues(alpha: 0.35)
                          : p.hairline,
                      width: 0.75,
                    ),
                    labelStyle: AppTypography.label(
                      isSelected ? p.accentText : p.textPrimary,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedZikrIndex = index;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Target Selector (33, 100, 1000, مفتوح)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الهدف: ',
                  style: AppTypography.meta(p.textPrimary,
                      weight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                ...[33, 100, 1000, 0].map((t) {
                  final isSelected = _target == t;
                  final label = t == 0 ? 'مفتوح ∞' : toArabicDigits(t);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: p.primaryContainer,
                      backgroundColor: p.cardElevated,
                      side: BorderSide(
                        color: isSelected
                            ? p.primary.withValues(alpha: 0.35)
                            : p.hairline,
                        width: 0.75,
                      ),
                      labelStyle: AppTypography.label(
                        isSelected ? p.accentText : p.textPrimary,
                        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _target = t;
                          });
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Big Interactive Tap Circle with Progress Ring
          Semantics(
            button: true,
            label: 'عداد التسبيح، العدد الحالي $_sessionCount',
            child: GestureDetector(
              onTap: _increment,
              child: SizedBox(
                width: 204,
                height: 204,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_target > 0)
                      SizedBox(
                        width: 202,
                        height: 202,
                        child: CircularProgressIndicator(
                          value: ringProgress,
                          strokeWidth: 6,
                          backgroundColor: p.hairline,
                          valueColor: AlwaysStoppedAnimation<Color>(p.accent),
                        ),
                      ),
                    Container(
                      width: 184,
                      height: 184,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            p.card,
                            p.cardElevated,
                            p.primaryContainer,
                          ],
                        ),
                        border: Border.all(
                          color: p.accent.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                        boxShadow: AppDesignSystem.cardShadow(isDark: isDark),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              toArabicDigits(_sessionCount),
                              style: AppTypography.heroCountdown(p.textPrimary)
                                  .copyWith(fontSize: 46),
                            ),
                            if (_target > 0)
                              Text(
                                'دورة: ${toArabicDigits(rounds)} • متبقي ${toArabicDigits(_target - progressInRound)}',
                                style: AppTypography.label(
                                  p.accentText,
                                  weight: FontWeight.w700,
                                ),
                              )
                            else
                              Text(
                                'اضغط للتسبيح',
                                style: AppTypography.meta(p.textSecondary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(
                  'تصفير الجلسة',
                  style:
                      AppTypography.meta(p.accentText, weight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.accentText,
                  side: BorderSide(color: p.primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _resetSession,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'إغلاق وحفظ',
                  style:
                      AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
