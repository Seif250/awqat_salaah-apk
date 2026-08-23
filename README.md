# 🕌 تطبيق أوقات الصلاة | Awqat Al-Salaah App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Android-5.0%2B%20(API%2021%2B)-3DDC84?logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/State%20Management-BLoC-blue" alt="BLoC" />
  <img src="https://img.shields.io/badge/Offline--First-100%25-success" alt="Offline-First" />
  <img src="https://img.shields.io/badge/APK%20Size-19.2%20MB-brightgreen" alt="Size" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

<p align="center">
  <b>تطبيق أندرويد متكامل وأنيق لمواقيت الصلاة اليومية وحساب وقت الإقامة مع ودجت للشاشة الرئيسية (Home Screen Widget) بتصميم إسلامي فاخر وحجم فائق الخفة.</b>
</p>

---

## 🌟 أبرز مميزات التطبيق (Features)

### 1. 🕌 حساب فلكي دقيق ومحلي (100% Offline-First)
* حساب مواقيت الصلوات الخمس ووقت الشروق بدون الحاجة لأي اتصال بالإنترنت نهائياً عبر خوارزميات مكتبة `adhan`.
* **دعم كافة طرق الحساب المعتمدة عالمياً:**
  * الهيئة المصرية العامة للمساحة (الافتراضية).
  * أم القرى (مكة المكرمة).
  * رابطة العالم الإسلامي.
  * جامعة العلوم الإسلامية بكراتشي.
  * الجمعية الإسلامية لأمريكا الشمالية (ISNA).
  * الكويت، قطر، دبي، سنغافورة (MUIS)، تركيا (Diyanet)، طهران، ولجنة رؤية الهلال.
* **دعم المذهبين الفقهيين لصلاة العصر:**
  * الشافعي / المالكي / الحنبلي (المثل - الجمهور).
  * الحنفي (المثلين).
* **إمكانية التعديل اليدوي بالدقائق (+ / -)** لكل صلاة على حدة لتطابق المسجد المجاور لك بدقة.

---

### 2. ⏱️ ميزة وقت الإقامة والعد التنازلي التفاعلي (Iqamah Intervals)
* **عرض أوقات الإقامة:** تظهر الإقامة لكل صلاة مع الفارق بالدقائق (مثال: `الإقامة: 06:55 م (+10 د)`).
* **تخصيص كامل لفارق الإقامة:** إمكانية تعديل دقائق الإقامة لكل صلاة من الإعدادات (الفجر: 20د، الظهر: 15د، العصر: 15د، المغرب: 10د، العشاء: 15د).
* **النافذة الزمنية للإقامة (بين الأذان والإقامة):**
  * عند دخول وقت الأذان، تتحول البطاقة الرئيسية تلقائياً إلى حالة **"أُذِّن الآن للصلاة"** مع تدرج لوني مائي مميز.
  * يتحول العداد التنازلي فوراً إلى **"متبقي للإقامة: 08:30"** ليعد تنازلياً حتى موعد إقامة الصلاة.

---

### 3. 📱 ودجت الشاشة الرئيسية (Native Android Home Screen Widget)
* **تصميم مربع زجاجي أنيق (3x3 Modern Glassmorphism):**
  * خلفية خضراء زمردية داكنة مع إطار ذهبي رقيق.
  * عرض اسم المدينة والتاريخ.
  * بطاقة بارزة للصلاة القادمة مع **وقت الأذان ووقت الإقامة معاً**.
  * جدول مصغر لمواقيت الصلوات الخمس (الفجر، الظهر، العصر، المغرب، العشاء).
* **توافق كامل واستقرار فائق (100% Crash-Proof):**
  * متوافقة مع كافة أجهزة وواجهات أندرويد بما فيها هواتف **Realme / Oppo (ColorOS)**، **Xiaomi (MIUI/HyperOS)**، **Samsung (OneUI)**، و **Google Pixel**.
* **الضغط على أي جزء من الودجت يفتح التطبيق مباشرة.**

---

### 4. 🔕 إشعارات هادئة تماماً (Silent Notifications)
* إشعارات بدون أي صوت أو اهتزاز مطلقاً.
* إمكانية ضبط التنبيه:
  * عند دخول وقت الصلاة تماماً.
  * قبل الصلاة بـ 5 دقائق، 10 دقائق، أو 15 دقيقة.

---

### 5. 📍 تحديد الموقع الجغرافي (GPS & Manual)
* كشف تلقائي فوري للموقع الحالي عبر الـ GPS.
* أو اختيار يدوي من قاعدة بيانات مدمجة أوفلاين تضم كافة محافظات ومدن جمهورية مصر العربية والعواصم والمدن العربية والعالمية.

---

### 6. 🎨 مظهر إسلامي حديث وأيقونة مسطحة
* **لوحة ألوان إسلامية ملكية:** أخضر زمردي فاخر (`#0F5132`) مع لمسات ذهبية أنيقة (`#D4AF37`).
* **الوضع الداكن والفاتح:** دعم الوضع الليلي (Dark Mode) والوضع الفاتح (Light Mode) والوضع التلقائي للنظام.
* **تنسيق الوقت:** التبديل السلس بين نظام 12 ساعة (م/ص) ونظام 24 ساعة.
* **أيقونة مسجد مسطحة وبسيطة (Minimalist Flat Mosque Logo):** تصميم عصري وأنيق مستوحى من واجهات iOS و Material You.

---

### 7. ⚡ حجم فائق الخفة والسرعة (Ultra Lightweight)
* **الحجم: 19.2 ميجابايت فقط** (مقلص بنسبة 65% مقارنة بالحجم الافتراضي).
* تفعيل **R8 Minification & Code Shrinking** لإزالة الأكواد غير المستخدمة.
* تفعيل **Resource Shrinking** لإزالة الموارد والأيقونات الزائدة.
* تقنية **Split-Per-ABI** لإنتاج حزم مخصصة لكل معالج.

---

## 📂 هيكلة المشروع (Project Architecture)

تم بناء التطبيق باتباع معمارية **Clean Architecture** ونمط إدارة الحالة **BLoC Pattern**:

```text
lib/
├── app.dart                                # إعدادات التطبيق العامة والمظهر واللغات
├── main.dart                               # نقطة الانطلاق وتهيأة الخدمات
├── core/
│   ├── constants/
│   │   ├── app_constants.dart              # الثوابت ومفاتيح التخزين
│   │   └── prayer_constants.dart           # الـ Enums لطرق الحساب والمذاهب
│   ├── theme/
│   │   ├── app_colors.dart                 # درجات الألوان (الزمردي والذهبي)
│   │   └── app_theme.dart                  # أنماط المظهر الفاتح والداكن
│   └── utils/
│       └── date_utils.dart                 # تنسيق الأوقات والعدادات التنازلية
├── features/
│   ├── location/                           # ميزة تحديد واختيار الموقع
│   ├── onboarding/                         # شاشة الترحيب والإعداد الأول
│   ├── prayer_times/                       # ميزة مواقيت الصلاة والواجهة الرئيسية
│   │   ├── data/models/                    # نماذج البيانات (PrayerDay, PrayerTime)
│   │   └── presentation/                   # الـ BLoC والواجهات (HomePage, Cards, Rows)
│   └── settings/                           # ميزة إعدادات الحساب والمظهر والإقامة
└── services/
    ├── notification_service.dart           # جدولة الإشعارات الصامتة
    ├── prayer_calculation_service.dart     # خوارزميات الحساب الفلكي
    ├── storage_service.dart                # حفظ الإعدادات عبر SharedPreferences
    └── widget_service.dart                 # مزامنة بيانات الودجت مع نظام أندرويد
```

---

## 🛠️ التقنيات والمكتبات المستخدمة (Tech Stack)

* **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
* **State Management:** [`flutter_bloc`](https://pub.dev/packages/flutter_bloc) & [`equatable`](https://pub.dev/packages/equatable)
* **Prayer Calculations:** [`adhan`](https://pub.dev/packages/adhan)
* **Local Notifications:** [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications) & [`timezone`](https://pub.dev/packages/timezone)
* **Geolocation:** [`geolocator`](https://pub.dev/packages/geolocator) & [`geocoding`](https://pub.dev/packages/geocoding)
* **Local Storage:** [`shared_preferences`](https://pub.dev/packages/shared_preferences)
* **Hijri Calendar:** [`hijri`](https://pub.dev/packages/hijri)
* **Android Native:** Kotlin, `RemoteViews`, `AppWidgetProvider`, `MethodChannel`

---

## 🚀 تشغيل وبناء المشروع محلياً (How to Run & Build)

### المتطلبات الأساسية:
* Flutter SDK (3.x أو أحدث)
* Android SDK (API 34+) مع JDK 17

### 1. استنساخ المستودع وتثبيت الحزم:
```bash
git clone https://github.com/Seif250/awqat_salaah-apk.git
cd awqat_salaah-apk
flutter pub get
```

### 2. تشغيل الاختبارات البرمجية:
```bash
flutter test
```

### 3. تشغيل التطبيق على الهاتف أو المحاكي:
```bash
flutter run
```

### 4. بناء ملف الـ APK النهائي (Release Build):
```bash
# بناء حزم خفيفة مخصصة لكل معالج (19.2 MB)
flutter build apk --split-per-abi --release
```

ستجد ملفات الـ APK الناتجة داخل المسار: `build/app/outputs/flutter-apk/`

---

## 📥 روابط ملفات الـ APK الجاهزة للتثبيت المباشر:

| الملف | الحجم | نوع المعالج والأجهزة |
|---|---|---|
| 📱 **`awqat_salaah.apk`** (الأساسي) | **19.2 MB** | لجميع الهواتف الذكية الحديثة (ARM64-v8a) |
| 📱 **`awqat_salaah_32bit.apk`** | **16.8 MB** | للأجهزة الأقدم ذات معمارية 32-bit |

---

## 📄 الترخيص (License)

هذا المشروع مرخص تحت رخصة **[MIT License](LICENSE)** — متاح للاستخدام والتطوير الحر ومفتوح المصدر.