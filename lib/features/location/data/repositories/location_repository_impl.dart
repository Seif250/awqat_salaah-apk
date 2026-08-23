import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/city_model.dart';

class LocationRepository {
  static const List<CityModel> defaultCities = [
    // Egyptian Governorates & Cities
    CityModel(nameArabic: 'القاهرة', nameEnglish: 'Cairo', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 30.0444, longitude: 31.2357),
    CityModel(nameArabic: 'الإسكندرية', nameEnglish: 'Alexandria', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.2001, longitude: 29.9187),
    CityModel(nameArabic: 'الجيزة', nameEnglish: 'Giza', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 30.0131, longitude: 31.2089),
    CityModel(nameArabic: 'طنطا', nameEnglish: 'Tanta', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 30.7865, longitude: 31.0004),
    CityModel(nameArabic: 'المنصورة', nameEnglish: 'Mansoura', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.0409, longitude: 31.3785),
    CityModel(nameArabic: 'الزقازيق', nameEnglish: 'Zagazig', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 30.5877, longitude: 31.5020),
    CityModel(nameArabic: 'أسيوط', nameEnglish: 'Asyut', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 27.1810, longitude: 31.1837),
    CityModel(nameArabic: 'سوهاج', nameEnglish: 'Sohag', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 26.5569, longitude: 31.6948),
    CityModel(nameArabic: 'الأقصر', nameEnglish: 'Luxor', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 25.6872, longitude: 32.6396),
    CityModel(nameArabic: 'أسوان', nameEnglish: 'Aswan', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 24.0889, longitude: 32.8998),
    CityModel(nameArabic: 'بورسعيد', nameEnglish: 'Port Said', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.2653, longitude: 32.3019),
    CityModel(nameArabic: 'السويس', nameEnglish: 'Suez', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 29.9668, longitude: 32.5498),
    CityModel(nameArabic: 'الإسماعيلية', nameEnglish: 'Ismailia', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 30.6043, longitude: 32.2723),
    CityModel(nameArabic: 'دمياط', nameEnglish: 'Damietta', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.4175, longitude: 31.8144),
    CityModel(nameArabic: 'الفيوم', nameEnglish: 'Fayoum', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 29.3084, longitude: 30.8428),
    CityModel(nameArabic: 'بني سويف', nameEnglish: 'Beni Suef', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 29.0661, longitude: 31.0994),
    CityModel(nameArabic: 'المنيا', nameEnglish: 'Minya', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 28.1099, longitude: 30.7503),
    CityModel(nameArabic: 'قنا', nameEnglish: 'Qena', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 26.1551, longitude: 32.7160),
    CityModel(nameArabic: 'مطروح', nameEnglish: 'Marsa Matruh', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.3543, longitude: 27.2373),
    CityModel(nameArabic: 'الغردقة', nameEnglish: 'Hurghada', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 27.2579, longitude: 33.8116),
    CityModel(nameArabic: 'شرم الشيخ', nameEnglish: 'Sharm El Sheikh', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 27.9158, longitude: 34.3299),
    CityModel(nameArabic: 'العريش', nameEnglish: 'Arish', countryArabic: 'مصر', countryEnglish: 'Egypt', latitude: 31.1316, longitude: 33.7984),

    // Arab & Islamic World Capitals / Major Cities
    CityModel(nameArabic: 'مكة المكرمة', nameEnglish: 'Makkah', countryArabic: 'السعودية', countryEnglish: 'Saudi Arabia', latitude: 21.3891, longitude: 39.8579),
    CityModel(nameArabic: 'المدينة المنورة', nameEnglish: 'Madinah', countryArabic: 'السعودية', countryEnglish: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692),
    CityModel(nameArabic: 'الرياض', nameEnglish: 'Riyadh', countryArabic: 'السعودية', countryEnglish: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753),
    CityModel(nameArabic: 'جدة', nameEnglish: 'Jeddah', countryArabic: 'السعودية', countryEnglish: 'Saudi Arabia', latitude: 21.4858, longitude: 39.1925),
    CityModel(nameArabic: 'القدس', nameEnglish: 'Jerusalem', countryArabic: 'فلسطين', countryEnglish: 'Palestine', latitude: 31.7683, longitude: 35.2137),
    CityModel(nameArabic: 'دبي', nameEnglish: 'Dubai', countryArabic: 'الإمارات', countryEnglish: 'UAE', latitude: 25.2048, longitude: 55.2708),
    CityModel(nameArabic: 'أبو ظبي', nameEnglish: 'Abu Dhabi', countryArabic: 'الإمارات', countryEnglish: 'UAE', latitude: 24.4539, longitude: 54.3773),
    CityModel(nameArabic: 'الدوحة', nameEnglish: 'Doha', countryArabic: 'قطر', countryEnglish: 'Qatar', latitude: 25.2854, longitude: 51.5310),
    CityModel(nameArabic: 'الكويت', nameEnglish: 'Kuwait City', countryArabic: 'الكويت', countryEnglish: 'Kuwait', latitude: 29.3759, longitude: 47.9774),
    CityModel(nameArabic: 'عمان', nameEnglish: 'Amman', countryArabic: 'الأردن', countryEnglish: 'Jordan', latitude: 31.9454, longitude: 35.9284),
    CityModel(nameArabic: 'بيروت', nameEnglish: 'Beirut', countryArabic: 'لبنان', countryEnglish: 'Lebanon', latitude: 33.8938, longitude: 35.5018),
    CityModel(nameArabic: 'دمشق', nameEnglish: 'Damascus', countryArabic: 'سوريا', countryEnglish: 'Syria', latitude: 33.5138, longitude: 36.2765),
    CityModel(nameArabic: 'بغداد', nameEnglish: 'Baghdad', countryArabic: 'العراق', countryEnglish: 'Iraq', latitude: 33.3152, longitude: 44.3661),
    CityModel(nameArabic: 'طرابلس', nameEnglish: 'Tripoli', countryArabic: 'ليبيا', countryEnglish: 'Libya', latitude: 32.8872, longitude: 13.1913),
    CityModel(nameArabic: 'تونس', nameEnglish: 'Tunis', countryArabic: 'تونس', countryEnglish: 'Tunisia', latitude: 36.8065, longitude: 10.1815),
    CityModel(nameArabic: 'الجزائر', nameEnglish: 'Algiers', countryArabic: 'الجزائر', countryEnglish: 'Algeria', latitude: 36.7538, longitude: 3.0588),
    CityModel(nameArabic: 'الرباط', nameEnglish: 'Rabat', countryArabic: 'المغرب', countryEnglish: 'Morocco', latitude: 34.0209, longitude: -6.8416),
    CityModel(nameArabic: 'الدار البيضاء', nameEnglish: 'Casablanca', countryArabic: 'المغرب', countryEnglish: 'Morocco', latitude: 33.5731, longitude: -7.5898),
    CityModel(nameArabic: 'إسطنبول', nameEnglish: 'Istanbul', countryArabic: 'تركيا', countryEnglish: 'Turkey', latitude: 41.0082, longitude: 28.9784),
    CityModel(nameArabic: 'جاكرتا', nameEnglish: 'Jakarta', countryArabic: 'إندونيسيا', countryEnglish: 'Indonesia', latitude: -6.2088, longitude: 106.8456),
    CityModel(nameArabic: 'كوالالمبور', nameEnglish: 'Kuala Lumpur', countryArabic: 'ماليزيا', countryEnglish: 'Malaysia', latitude: 3.1390, longitude: 101.6869),
    CityModel(nameArabic: 'لندن', nameEnglish: 'London', countryArabic: 'المملكة المتحدة', countryEnglish: 'UK', latitude: 51.5074, longitude: -0.1278),
    CityModel(nameArabic: 'باريس', nameEnglish: 'Paris', countryArabic: 'فرنسا', countryEnglish: 'France', latitude: 48.8566, longitude: 2.3522),
    CityModel(nameArabic: 'نيويورك', nameEnglish: 'New York', countryArabic: 'الولايات المتحدة', countryEnglish: 'USA', latitude: 40.7128, longitude: -74.0060),
  ];

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<String> getCityNameFromCoordinates(double lat, double lng, {String locale = 'ar'}) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
        if (city != null && city.isNotEmpty) {
          return city;
        }
      }
    } catch (_) {
      // Fallback for offline
    }
    return locale.startsWith('ar') ? 'موقعي الحالي' : 'Current Location';
  }

  List<CityModel> searchCities(String query) {
    if (query.trim().isEmpty) return defaultCities;
    final lower = query.toLowerCase().trim();
    return defaultCities.where((c) {
      return c.nameArabic.toLowerCase().contains(lower) ||
          c.nameEnglish.toLowerCase().contains(lower) ||
          c.countryArabic.toLowerCase().contains(lower) ||
          c.countryEnglish.toLowerCase().contains(lower);
    }).toList();
  }
}
