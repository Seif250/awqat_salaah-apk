import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

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
  int _target = 33;
  int _selectedZikrIndex = 0;

  final List<String> _zikrPresets = [
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
  }

  void _increment() {
    HapticFeedback.mediumImpact();
    setState(() {
      _sessionCount++;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rounds = _target > 0 ? (_sessionCount / _target).floor() : 0;
    final progressInRound = _target > 0 ? (_sessionCount % _target) : _sessionCount;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fingerprint_rounded, size: 22, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  Text(
                    'المسبحة الإلكترونية',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
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
                    selectedColor: AppColors.accentGold.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.accentGold : null,
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
          const SizedBox(height: 16),

          // Target Selector (33, 100, 1000, مفتوح)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('الهدف: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ...[33, 100, 1000, 0].map((t) {
                final isSelected = _target == t;
                final label = t == 0 ? 'مفتوح ∞' : '$t';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryLight : null,
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
          const SizedBox(height: 16),

          // Big Interactive Tap Circle
          GestureDetector(
            onTap: _increment,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: isDark
                      ? [
                          AppColors.darkCardElevated,
                          AppColors.darkCard,
                          AppColors.primaryDark,
                        ]
                      : [
                          AppColors.lightCardElevated,
                          AppColors.primaryContainer.withValues(alpha: 0.4),
                          AppColors.accentGold.withValues(alpha: 0.2),
                        ],
                ),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_sessionCount',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
                    if (_target > 0)
                      Text(
                        'دورة: $rounds (متبقي ${_target - progressInRound})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const Text(
                        'اضغط للتسبيح',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons: Reset session count & Total Lifetime
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('تصفير الجلسة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _resetSession,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('إغلاق وحفظ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
