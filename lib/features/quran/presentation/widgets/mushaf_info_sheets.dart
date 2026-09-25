import 'package:flutter/material.dart';

/// Modal sheets for authentic Quran details:
/// 1. Dua Khatm al-Quran (دعاء ختم القرآن الكريم)
/// 2. Stop Marks & Orthography Guide (علامات الوقف ومصطلحات ضبط المصحف)
class MushafInfoSheets {
  static const Color paperBg = Color(0xFFFBF8F0);
  static const Color paperBorder = Color(0xFFE8DECA);
  static const Color goldAccent = Color(0xFFB89368);
  static const Color bronzeAccent = Color(0xFF8C643E);
  static const Color textDark = Color(0xFF1E1A17);
  static const Color nightPaper = Color(0xFF1B201D);
  static const Color nightBronze = Color(0xFFD4AF37);
  static const Color nightText = Color(0xFFE8E5DD);

  /// Shows the authentic Dua Khatm al-Quran
  static void showDuaKhatm(BuildContext context, {bool isDark = false}) {
    final bg = isDark ? nightPaper : paperBg;
    final bronze = isDark ? nightBronze : bronzeAccent;
    final text = isDark ? nightText : textDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: bronze, width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories_rounded, color: bronze, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'دُعَاءُ خَتْمِ القُرْآنِ الكَرِيمِ',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: bronze,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.white60,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : paperBorder,
                      ),
                    ),
                    child: Text(
                      'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ، وَاجْعَلْهُ لِي إِمَاماً وَنُوراً وَهُدًى وَرَحْمَةً.\n\n'
                      'اللَّهُمَّ ذَكِّرْنِي مِنْهُ مَا نَسِيتُ، وَعَلِّمْنِي مِنْهُ مَا جَهِلْتُ، وَارْزُقْنِي تِلاوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لِي حُجَّةً يَا رَبَّ العَالَمِينَ.\n\n'
                      'اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي، وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي، وَأَصْلِحْ لِي آخِرَتِي الَّتِي فِيهَا مَعَادِي، وَاجْعَلِ الحَيَاةَ زِيَادَةً لِي فِي كُلِّ خَيْرٍ، وَاجْعَلِ المَوْتَ رَاحَةً لِي مِنْ كُلِّ شَرٍّ.\n\n'
                      'اللَّهُمَّ اجْعَلْ خَيْرَ عُمْرِي آخِرَهُ، وَخَيْرَ عَمَلِي خَوَاتِمَهُ، وَخَيْرَ أَيَّامِي يَوْمَ أَلْقَاكَ فِيهِ.\n\n'
                      'اللَّهُمَّ إِنِّي أَسْأَلُكَ عِيشَةً هَنِيَّةً، وَمِيتَةً سَوِيَّةً، وَمَرَدّاً غَيْرَ مُخْزٍ وَلا فَاضِحٍ.\n\n'
                      'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ المَسْأَلَةِ، وَخَيْرَ الدُّعَاءِ، وَخَيْرَ النَّجَاحِ، وَخَيْرَ العِلْمِ، وَخَيْرَ العَمَلِ، وَخَيْرَ الثَّوَابِ، وَخَيْرَ الحَيَاةِ، وَخَيْرَ المَمَاتِ، وَثَبِّتْنِي وَثَقِّلْ مَوَازِينِي، وَحَقِّقْ إِيمَانِي، وَارْفَعْ دَرَجَتِي، وَتَقَبَّلْ صَلاتِي، وَاغْفِرْ خَطِيئَاتِي، وَأَسْأَلُكَ العُلا مِنَ الجَنَّةِ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 2.2,
                        color: text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the Guide to Stops & Diacritics (علامات الوقف ومصطلحات الضبط)
  static void showTajweedGuide(BuildContext context, {bool isDark = false}) {
    final bg = isDark ? nightPaper : paperBg;
    final bronze = isDark ? nightBronze : bronzeAccent;
    final text = isDark ? nightText : textDark;

    const stops = [
      {'symbol': 'مـ', 'name': 'الوقف اللازم', 'desc': 'يلزم الوقف عليه حتى لا يتغير المعنى المراد.'},
      {'symbol': 'لا', 'name': 'الوقف الممنوع', 'desc': 'لا يجوز الوقف عليه لأن المعنى لم يتم.'},
      {'symbol': 'ج', 'name': 'جواز الوقف', 'desc': 'يجوز الوقف والوصل على حد سواء بلا ترجيح.'},
      {'symbol': 'صلى', 'name': 'الوصل أولى', 'desc': 'يجوز الوقف والوصل، والوصل أولى وأفضل.'},
      {'symbol': 'قلى', 'name': 'الوقف أولى', 'desc': 'يجوز الوقف والوصل، والوقف أولى وأفضل.'},
      {'symbol': 'ۛ   ۛ', 'name': 'تعانق الوقف', 'desc': 'إذا وُقف على الموضع الأول، امتنع الوقف على الثاني.'},
      {'symbol': '۞', 'name': 'علامة الحزب والربع', 'desc': 'تحدد بداية الأجزاء والأحزاب وأرباعها.'},
      {'symbol': '۩', 'name': 'سجدة تلاوة', 'desc': 'موضع سجدة تلاوة يُستحب للقارئ والمستمع السجود عندها.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: bronze, width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_rounded, color: bronze, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'علامات الوقف وضبط المصحف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: bronze,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: stops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final item = stops[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.white60,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : paperBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: bronze.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: bronze.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                item['symbol']!,
                                style: TextStyle(
                                  fontFamily: 'UthmanicHafs',
                                  fontFamilyFallback: const ['AmiriQuran', 'Cairo'],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: bronze,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: text,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['desc']!,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
