import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prayer Notification Styling & Customization Tests', () {
    final service = NotificationService();

    test('Each prayer has a unique, distinct Arabic notification title', () {
      final fajrTitle = service.getPrayerNotificationTitle(PrayerType.fajr, true);
      final dhuhrTitle = service.getPrayerNotificationTitle(PrayerType.dhuhr, true);
      final asrTitle = service.getPrayerNotificationTitle(PrayerType.asr, true);
      final maghribTitle = service.getPrayerNotificationTitle(PrayerType.maghrib, true);
      final ishaTitle = service.getPrayerNotificationTitle(PrayerType.isha, true);

      expect(fajrTitle, contains('الفجر'));
      expect(fajrTitle, contains('الصَّلَاةُ خَيْرٌ مِنَ النَّوْمِ'));

      expect(dhuhrTitle, contains('الظهر'));
      expect(dhuhrTitle, contains('حَانَ وَقْتُ الصَّلَاةِ'));

      expect(asrTitle, contains('العصر'));
      expect(asrTitle, contains('الصَّلَاةِ الْوُسْطَى'));

      expect(maghribTitle, contains('المغرب'));
      expect(maghribTitle, contains('لِدُلُوكِ الشَّمْسِ'));

      expect(ishaTitle, contains('العشاء'));
      expect(ishaTitle, contains('خَاتِمَةُ صَلَوَاتِ النَّهَارِ'));

      final allTitles = [fajrTitle, dhuhrTitle, asrTitle, maghribTitle, ishaTitle];
      expect(allTitles.toSet().length, 5, reason: 'All 5 prayer titles must be strictly unique');
    });

    test('Each prayer has a unique spiritual message body', () {
      final fajrBody = service.getPrayerNotificationBody(PrayerType.fajr, '', true);
      final dhuhrBody = service.getPrayerNotificationBody(PrayerType.dhuhr, '', true);
      final asrBody = service.getPrayerNotificationBody(PrayerType.asr, '', true);
      final maghribBody = service.getPrayerNotificationBody(PrayerType.maghrib, '', true);
      final ishaBody = service.getPrayerNotificationBody(PrayerType.isha, '', true);

      expect(fajrBody, contains('ذمة الله'));
      expect(dhuhrBody, contains('استراحة المؤمن'));
      expect(asrBody, contains('سعة رزقك'));
      expect(maghribBody, contains('غربت الشمس'));
      expect(ishaBody, contains('سجدة خاشعة'));

      final allBodies = [fajrBody, dhuhrBody, asrBody, maghribBody, ishaBody];
      expect(allBodies.toSet().length, 5, reason: 'All 5 prayer bodies must be strictly unique');
    });

    test('English notification titles and bodies are properly formatted', () {
      for (final type in [PrayerType.fajr, PrayerType.dhuhr, PrayerType.asr, PrayerType.maghrib, PrayerType.isha]) {
        final title = service.getPrayerNotificationTitle(type, false);
        final body = service.getPrayerNotificationBody(type, ' • Iqamah in 15 min', false);

        expect(title, contains(type.nameEnglish));
        expect(body, contains('started'));
        expect(body, contains('Iqamah in 15 min'));
      }
    });
  });
}
