// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أوقات الصلاة';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get remaining => 'متبقي';

  @override
  String get hours => 'ساعة';

  @override
  String get minutes => 'دقيقة';

  @override
  String get seconds => 'ثانية';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get settings => 'الإعدادات';

  @override
  String get location => 'الموقع';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get manualCity => 'اختيار المدينة';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get madhab => 'المذهب';

  @override
  String get shafi => 'الشافعي';

  @override
  String get hanafi => 'الحنفي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationBeforePrayer => 'إشعار قبل الصلاة';

  @override
  String get atPrayerTime => 'عند دخول وقت الصلاة';

  @override
  String minutesBefore(int count) {
    return 'قبل $count دقائق';
  }

  @override
  String get theme => 'المظهر';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get systemTheme => 'النظام';

  @override
  String get timeFormat24 => 'تنسيق 24 ساعة';

  @override
  String get onboardingWelcome => 'مرحباً بك في أوقات الصلاة';

  @override
  String get onboardingDescription =>
      'احصل على مواقيت صلاة دقيقة بناءً على موقعك باستخدام الحسابات الفلكية.';

  @override
  String get onboardingLocationTitle => 'اختر موقعك';

  @override
  String get onboardingLocationDesc => 'نحتاج موقعك لحساب مواقيت الصلاة بدقة.';

  @override
  String get useCurrentLocation => 'استخدام الموقع الحالي';

  @override
  String get selectCityManually => 'اختيار المدينة يدوياً';

  @override
  String get searchCity => 'ابحث عن مدينة...';

  @override
  String get selectCalculationMethod => 'اختر طريقة الحساب';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get next => 'التالي';

  @override
  String get skip => 'تخطي';

  @override
  String todayAt(String time) {
    return 'اليوم $time';
  }

  @override
  String prayerTimeNotification(String prayer) {
    return 'صلاة $prayer';
  }

  @override
  String prayerTimeStarted(String prayer) {
    return 'دخل وقت صلاة $prayer.';
  }

  @override
  String prayerInMinutes(String prayer, int count) {
    return 'صلاة $prayer بعد $count دقائق.';
  }

  @override
  String get locationPermissionTitle => 'إذن الموقع';

  @override
  String get locationPermissionDesc =>
      'يتم حساب مواقيت الصلاة بناءً على موقعك الجغرافي. نحتاج إذن الوصول لموقعك لتوفير أوقات دقيقة.';

  @override
  String get grantPermission => 'منح الإذن';

  @override
  String get notificationPermissionTitle => 'إذن الإشعارات';

  @override
  String get notificationPermissionDesc =>
      'اسمح بالإشعارات لتلقي تذكيرات صامتة لمواقيت الصلاة.';

  @override
  String get egyptianAuthority => 'الهيئة المصرية العامة للمساحة';

  @override
  String get muslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get isna => 'الجمعية الإسلامية لأمريكا الشمالية';

  @override
  String get ummAlQura => 'أم القرى';

  @override
  String get karachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get moonsightingCommittee => 'لجنة رؤية الهلال';

  @override
  String get kuwait => 'الكويت';

  @override
  String get qatar => 'قطر';

  @override
  String get singapore => 'سنغافورة';

  @override
  String get tehran => 'طهران';

  @override
  String get turkey => 'تركيا';

  @override
  String get dubai => 'دبي';

  @override
  String get northAmerica => 'أمريكا الشمالية';

  @override
  String get prayerTimeAdjustments => 'تعديل أوقات الصلاة';

  @override
  String adjustmentMinutes(int count) {
    return '$count د';
  }

  @override
  String get disable => 'تعطيل';

  @override
  String get enable => 'تفعيل';

  @override
  String get about => 'حول';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }
}
