import 'package:flutter/material.dart';

/// Authentic Centered Basmalah Calligraphy for Mushaf Pages
class MushafBismillah extends StatelessWidget {
  final bool isDark;

  const MushafBismillah({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Center(
        child: Text(
          'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8D7B8) : const Color(0xFF1E1A17),
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
