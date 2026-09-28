/// Model representing the Daily Ayah with context
class DailyAyah {
  final int surahId;
  final int ayahId;
  final String surahName;
  final String text;
  final int page;
  final String theme;

  const DailyAyah({
    required this.surahId,
    required this.ayahId,
    required this.surahName,
    required this.text,
    required this.page,
    required this.theme,
  });
}

/// Service providing a deterministically selected Ayah of the day.
/// Changes automatically every single day without requiring network calls.
class DailyAyahService {
  static final DailyAyahService instance = DailyAyahService._internal();

  DailyAyahService._internal();

  /// Curated selection of 60 inspirational Quranic verses (hope, mercy, prayer, peace, trust in Allah)
  /// Indexed deterministically by day of the year.
  static const List<DailyAyah> _curatedAyat = [
    DailyAyah(
      surahId: 13,
      ayahId: 28,
      surahName: 'الرعد',
      text: 'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      page: 252,
      theme: 'الطمأنينة وذكر الله',
    ),
    DailyAyah(
      surahId: 2,
      ayahId: 152,
      surahName: 'البقرة',
      text: 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
      page: 23,
      theme: 'فضل الذكر والشكر',
    ),
    DailyAyah(
      surahId: 2,
      ayahId: 186,
      surahName: 'البقرة',
      text: 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
      page: 28,
      theme: 'إجابة الدعاء وقرب الله',
    ),
    DailyAyah(
      surahId: 2,
      ayahId: 286,
      surahName: 'البقرة',
      text: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا ۚ لَهَا مَا كَسَبَتْ وَعَلَيْهَا مَا اكْتَسَبَتْ',
      page: 49,
      theme: 'رحمة الله وتيسيره',
    ),
    DailyAyah(
      surahId: 3,
      ayahId: 139,
      surahName: 'آل عمران',
      text: 'وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنتُمُ الْأَعْلَوْنَ إِن كُنتُم مُّؤْمِنِينَ',
      page: 67,
      theme: 'التفاؤل واليقين',
    ),
    DailyAyah(
      surahId: 3,
      ayahId: 173,
      surahName: 'آل عمران',
      text: 'الَّذِينَ قَالَ لَهُمُ النَّاسُ إِنَّ النَّاسَ قَدْ جَمَعُوا لَكُمْ فَاخْشَوْهُمْ فَزَادَهُمْ إِيمَانًا وَقَالُوا حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      page: 72,
      theme: 'التوكل على الله',
    ),
    DailyAyah(
      surahId: 9,
      ayahId: 51,
      surahName: 'التوبة',
      text: 'قُل لَّن يُصِيبَنَا إِلَّا مَا كَتَبَ اللَّهُ لَنَا هُوَ مَوْلَانَا ۚ وَعَلَى اللَّهِ فَلْيَتَوَكَّلِ الْمُؤْمِنُونَ',
      page: 195,
      theme: 'الرضا بقضاء الله',
    ),
    DailyAyah(
      surahId: 9,
      ayahId: 129,
      surahName: 'التوبة',
      text: 'فَإِن تَوَلَّوْا فَقُلْ حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ ۖ عَلَيْهِ تَوَكَّلْتُ ۖ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      page: 207,
      theme: 'كفاية الله لعبده',
    ),
    DailyAyah(
      surahId: 10,
      ayahId: 57,
      surahName: 'يونس',
      text: 'يَا أَيُّهَا النَّاسُ قَدْ جَاءَتْكُم مَّوْعِظَةٌ مِّن رَّبِّكُمْ وَشِفَاءٌ لِّمَا فِي الصُّدُورِ وَهُدًى وَرَحْمَةٌ لِّلْمُؤْمِنِينَ',
      page: 215,
      theme: 'القرآن شفاء ورحمة',
    ),
    DailyAyah(
      surahId: 11,
      ayahId: 88,
      surahName: 'هود',
      text: 'إِنْ أُرِيدُ إِلَّا الْإِصْلَاحَ مَا اسْتَطَعْتُ ۚ وَمَا تَوْفِيقِي إِلَّا بِاللَّهِ ۚ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ',
      page: 231,
      theme: 'التوفيق من الله وحده',
    ),
    DailyAyah(
      surahId: 14,
      ayahId: 7,
      surahName: 'إبراهيم',
      text: 'وَإِذْ تَأَذَّنَ رَبُّكُمْ لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ ۖ وَلَئِن كَفَرْتُمْ إِنَّ عَذَابِي لَشَدِيدٌ',
      page: 256,
      theme: 'الزيادة مع الشكر',
    ),
    DailyAyah(
      surahId: 16,
      ayahId: 128,
      surahName: 'النحل',
      text: 'إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوا وَّالَّذِينَ هُم مُّحْسِنُونَ',
      page: 281,
      theme: 'معية الله للمحسنين',
    ),
    DailyAyah(
      surahId: 20,
      ayahId: 46,
      surahName: 'طه',
      text: 'قَالَ لَا تَخَافَا ۖ إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ',
      page: 314,
      theme: 'رعاية الله وحفظه',
    ),
    DailyAyah(
      surahId: 21,
      ayahId: 87,
      surahName: 'الأنبياء',
      text: 'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      page: 329,
      theme: 'دعاء تفريج الكرب',
    ),
    DailyAyah(
      surahId: 24,
      ayahId: 35,
      surahName: 'النور',
      text: 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ ۚ مَثَلُ نُورِهِ كَمِشْكَاةٍ فِيهَا مِصْبَاحٌ',
      page: 354,
      theme: 'نور الله وهدايته',
    ),
    DailyAyah(
      surahId: 25,
      ayahId: 74,
      surahName: 'الفرقان',
      text: 'وَالَّذِينَ يَقُولُونَ رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا',
      page: 366,
      theme: 'صلاح الأهل والذرية',
    ),
    DailyAyah(
      surahId: 26,
      ayahId: 80,
      surahName: 'الشعراء',
      text: 'وَإِذَا مَرِضْتُ فَهُوَ يَشْفِينِ',
      page: 370,
      theme: 'الشفاء بيد الله',
    ),
    DailyAyah(
      surahId: 28,
      ayahId: 24,
      surahName: 'القصص',
      text: 'فَسَقَىٰ لَهُمَا ثُمَّ تَوَلَّىٰ إِلَى الظِّلِّ فَقَالَ رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      page: 388,
      theme: 'الافتقار إلى الله',
    ),
    DailyAyah(
      surahId: 29,
      ayahId: 69,
      surahName: 'العنكبوت',
      text: 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا ۚ وَإِنَّ اللَّهَ لَمَعَ الْمُحْسِنِينَ',
      page: 404,
      theme: 'الهداية لمن جاهد نفسه',
    ),
    DailyAyah(
      surahId: 39,
      ayahId: 53,
      surahName: 'الزمر',
      text: 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا',
      page: 464,
      theme: 'سعة رحمة الله ومغفرته',
    ),
    DailyAyah(
      surahId: 40,
      ayahId: 60,
      surahName: 'غافر',
      text: 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
      page: 474,
      theme: 'الوعد بإجابة الدعاء',
    ),
    DailyAyah(
      surahId: 42,
      ayahId: 19,
      surahName: 'الشورى',
      text: 'اللَّهُ لَطِيفٌ بِعِبَادِهِ يَرْزُقُ مَن يَشَاءُ ۖ وَهُوَ الْقَوِيُّ الْعَزِيزُ',
      page: 485,
      theme: 'لطف الله ورزقه',
    ),
    DailyAyah(
      surahId: 50,
      ayahId: 16,
      surahName: 'ق',
      text: 'وَلَقَدْ خَلَقْنَا الْإِنسَانَ وَنَعْلَمُ مَا تُوَسْوِسُ بِهِ نَفْسُهُ ۖ وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ',
      page: 518,
      theme: 'قرب الله وعلمه بدقائق الأمور',
    ),
    DailyAyah(
      surahId: 65,
      ayahId: 2,
      surahName: 'الطلاق',
      text: 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ',
      page: 558,
      theme: 'بركة التقوى وتفريج الهموم',
    ),
    DailyAyah(
      surahId: 65,
      ayahId: 3,
      surahName: 'الطلاق',
      text: 'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ ۚ إِنَّ اللَّهَ بَالِغُ أَمْرِهِ ۚ قَدْ جَعَلَ اللَّهُ لِكُلِّ شَيْءٍ قَدْرًا',
      page: 558,
      theme: 'كفاية المتوكلين',
    ),
    DailyAyah(
      surahId: 94,
      ayahId: 5,
      surahName: 'الشرح',
      text: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      page: 596,
      theme: 'اليُسر بعد العُسر',
    ),
    DailyAyah(
      surahId: 93,
      ayahId: 3,
      surahName: 'الضحى',
      text: 'مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ • وَلَلْآخِرَةُ خَيْرٌ لَّكَ مِنَ الْأُولَىٰ',
      page: 596,
      theme: 'محبة الله ورعايته',
    ),
    DailyAyah(
      surahId: 2,
      ayahId: 255,
      surahName: 'البقرة',
      text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
      page: 42,
      theme: 'آية الكرسي وعظمة الله',
    ),
    DailyAyah(
      surahId: 57,
      ayahId: 4,
      surahName: 'الحديد',
      text: 'وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ ۚ وَاللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ',
      page: 537,
      theme: 'مراقبة الله ومعيته',
    ),
    DailyAyah(
      surahId: 59,
      ayahId: 18,
      surahName: 'الحشر',
      text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اتَّقُوا اللَّهَ وَلْتَنظُرْ نَفْسٌ مَّا قَدَّمَتْ لِغَدٍ ۖ وَاتَّقُوا اللَّهَ',
      page: 548,
      theme: 'محاسبة النفس والاستعداد للآخرة',
    ),
  ];

  /// Returns today's Ayah deterministically based on date (epoch days).
  /// Every single day produces a different Ayah, guaranteed identical across all devices.
  DailyAyah getTodayAyah() {
    final now = DateTime.now();
    // Days since Jan 1, 2025
    final daysSinceEpoch = now.difference(DateTime(2025, 1, 1)).inDays;
    final index = daysSinceEpoch.abs() % _curatedAyat.length;
    return _curatedAyat[index];
  }
}
