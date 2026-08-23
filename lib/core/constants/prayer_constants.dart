enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  none,
}

enum PrayerPhase {
  beforeAdhan, // متبقي للأذان
  duringIqamah, // متبقي للإقامة (بين الأذان والإقامة)
}

enum AppMadhab {
  shafi,
  hanafi,
}

enum AppCalculationMethod {
  egyptian,
  muslimWorldLeague,
  isna,
  ummAlQura,
  karachi,
  moonsightingCommittee,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  dubai,
  northAmerica,
}

extension PrayerTypeX on PrayerType {
  String get nameArabic {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
      case PrayerType.none:
        return '';
    }
  }

  String get nameEnglish {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.sunrise:
        return 'Sunrise';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
      case PrayerType.none:
        return '';
    }
  }

  bool get isActualPrayer => this != PrayerType.sunrise && this != PrayerType.none;
}

extension AppCalculationMethodX on AppCalculationMethod {
  String get displayNameArabic {
    switch (this) {
      case AppCalculationMethod.egyptian:
        return 'الهيئة المصرية العامة للمساحة';
      case AppCalculationMethod.muslimWorldLeague:
        return 'رابطة العالم الإسلامي';
      case AppCalculationMethod.isna:
        return 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)';
      case AppCalculationMethod.ummAlQura:
        return 'أم القرى - مكة المكرمة';
      case AppCalculationMethod.karachi:
        return 'جامعة العلوم الإسلامية، كراتشي';
      case AppCalculationMethod.moonsightingCommittee:
        return 'لجنة رؤية الهلال';
      case AppCalculationMethod.kuwait:
        return 'الكويت';
      case AppCalculationMethod.qatar:
        return 'قطر';
      case AppCalculationMethod.singapore:
        return 'سنغافورة (MUIS)';
      case AppCalculationMethod.tehran:
        return 'معهد الجيوفيزياء، جامعة طهران';
      case AppCalculationMethod.turkey:
        return 'رئاسة الشؤون الدينية، تركيا';
      case AppCalculationMethod.dubai:
        return 'دبي';
      case AppCalculationMethod.northAmerica:
        return 'أمريكا الشمالية';
    }
  }

  String get displayNameEnglish {
    switch (this) {
      case AppCalculationMethod.egyptian:
        return 'Egyptian General Authority of Survey';
      case AppCalculationMethod.muslimWorldLeague:
        return 'Muslim World League';
      case AppCalculationMethod.isna:
        return 'ISNA';
      case AppCalculationMethod.ummAlQura:
        return 'Umm Al-Qura, Makkah';
      case AppCalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case AppCalculationMethod.moonsightingCommittee:
        return 'Moonsighting Committee';
      case AppCalculationMethod.kuwait:
        return 'Kuwait';
      case AppCalculationMethod.qatar:
        return 'Qatar';
      case AppCalculationMethod.singapore:
        return 'Singapore (MUIS)';
      case AppCalculationMethod.tehran:
        return 'Tehran';
      case AppCalculationMethod.turkey:
        return 'Diyanet (Turkey)';
      case AppCalculationMethod.dubai:
        return 'Dubai';
      case AppCalculationMethod.northAmerica:
        return 'North America';
    }
  }
}
