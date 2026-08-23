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
  <b>تطبيق أندرويد إسلامي متكامل لحساب مواقيت الصلاة اليومية وفارق الإقامة مع دورة تتابع تلقائية (أذان ⬅️ إقامة ⬅️ الصلاة التالية) وودجت للشاشة الرئيسية (Home Screen Widget) بحجم خفيف جداً (19.2 MB).</b>
</p>

---

## 🌟 أبرز مميزات التطبيق (Features)

### 1. 🔄 دورة التتابع الزمني التلقائية (The Prayer Lifecycle)
يعمل التطبيق والودجت بنظام تتابع ذكي ودقيق ثانية بثانية:
* **المرحلة 1 (قبل الأذان):** يعرض العداد التنازلي **"متبقي للأذان: 01:25:30"** مع وقت الأذان ووقت الإقامة المجدول.
* **المرحلة 2 (فور دخول وقت الأذان):** يتحول العداد فوراً وبنفس الثانية إلى **"متبقي للإقامة: 09:59"** ويعد تنازلياً حتى موعد الإقامة.
* **المرحلة 3 (فور انتهاء وقت الإقامة):** ينتقل التطبيق والودجت **تلقائياً إلى الصلاة التالية** ويبدأ بالعد التنازلي لأذانها!

---

### 2. 🕌 حساب فلكي دقيق ومحلي (100% Offline-First)
* حساب مواقيت الصلوات الخمس ووقت الشروق بدون الحاجة لأي اتصال بالإنترنت نهائياً عبر خوارزميات مكتبة `adhan`.
* **دعم كافة طرق الحساب المعتمدة عالمياً:**
  * رابطة العالم الإسلامي (الافتراضية).
  * الهيئة المصرية العامة للمساحة.
  * جامعة العلوم الإسلامية بكراتشي.
  * الجمعية الإسلامية لأمريكا الشمالية (ISNA).
  * الكويت، قطر، دبي، سنغافورة (MUIS)، تركيا (Diyanet)، طهران، ولجنة رؤية الهلال.
* **دعم المذهبين الفقهيين لصلاة العصر:**
  * الشافعي / المالكي / الحنبلي (المثل - الجمهور).
  * الحنفي (المثلين).
* **إمكانية التعديل اليدوي بالدقائق (+ / -)** لكل صلاة على حدة لتطابق المسجد المجاور لك بدقة.

---

### 3. ⏱️ تخصيص كامل لفارق وقت الإقامة (Iqamah Intervals)
* إمكانية ضبط وتعديل دقائق الإقامة لكل صلاة من الإعدادات:
  * **صلاة الفجر:** 20 دقيقة (افتراضي).
  * **صلاة الظهر:** 15 دقيقة (افتراضي).
  * **صلاة العصر:** 15 دقيقة (افتراضي).
  * **صلاة المغرب:** 10 دقائق (افتراضي).
  * **صلاة العشاء:** 15 دقيقة (افتراضي).
* عرض وقت الإقامة بوضوح في كافة بطاقات وجداول التطبيق والودجت.

---

### 4. 📱 ودجت الشاشة الرئيسية (Native Android Home Screen Widget)
* **تصميم زجاجي عصري (Glassmorphism Layout):**
  * خلفية زمردية داكنة مع إطار ذهبي أنيق.
  * بطاقة الصلاة القادمة تعرض: **اسم الصلاة + وقت الأذان + وقت الإقامة والفارق بالدقائق**.
  * جدول مصغر لمواقيت الصلوات الخمس.
* **استقرار تام وتوافق 100% (Crash-Proof):**
  * مبنية بالكامل باستخدام عناصر RemoteViews القياسية المتوافقة مع جميع مشغلات الواجهات بما فيها **Realme/Oppo (ColorOS)**، **Xiaomi (MIUI/HyperOS)**، **Samsung (OneUI)**، و **Google Pixel**.
* **الضغط على الودجت يفتح التطبيق مباشرة.**

---

### 5. 🔔 إشعارات وتنبيهات نشطة مع خيار الوضع الصامت (Smart Notifications)
* **إشعارات عالية الأهمية (High Priority Heads-up):** تظهر كنافذة منبثقة على الشاشة الرئيسية وشاشة القفل.
* **تنبيه صوتي واهتزاز:** تشغيل نغمة تنبيه النظام عند دخول الوقت.
* **خيار كتم الصوت:** إمكانية تحويل الإشعارات إلى صامتة تماماً بضغطة زر من الإعدادات.
* **تحديد موعد التنبيه:** عند وقت الصلاة تماماً، أو قبلها بـ 5، 10، أو 15 دقيقة.
* **زر تجربة فورية للإشعار داخل الإعدادات.**

---

### 6. 📍 تحديد الموقع الجغرافي (GPS & Offline Cities)
* كشف تلقائي فوري للموقع الحالي عبر الـ GPS.
* أو اختيار يدوي من قاعدة بيانات مدمجة أوفلاين تضم كافة محافظات ومدن جمهورية مصر العربية والعواصم والمدن العربية والعالمية.

---

### 7. 🎨 مظهر إسلامي فاخر وأيقونة مسجد مسطحة
* **لوحة ألوان إسلامية ملكية:** أخضر زمردي فاخر (`#0F5132`) مع لمسات ذهبية أنيقة (`#D4AF37`).
* **الوضع الداكن والفاتح:** دعم الوضع الليلي والوضع الفاتح والوضع التلقائي للنظام.
* **تنسيق الوقت:** التبديل السلس بين نظام 12 ساعة (م/ص) ونظام 24 ساعة.
* **أيقونة مسجد مسطحة وبسيطة (Minimalist Flat Mosque Logo).**

---

### 8. ⚡ حجم فائق الخفة والسرعة (Ultra Lightweight)
* **الحجم: 19.2 ميجابايت فقط** (مقلص بنسبة 65% مقارنة بالحجم الافتراضي).
* تفعيل **R8 Minification & Resource Shrinking**.
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
│   │   └── prayer_constants.dart           # الـ Enums لطرق الحساب والمذاهب والأطوار
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
│   └── settings/                           # ميزة إعدادات الحساب والمظهر والإقامة والإشعارات
└── services/
    ├── notification_service.dart           # جدولة الإشعارات المسموعة والمرئية
    ├── prayer_calculation_service.dart     # خوارزميات الحساب الفلكي وإدارة دورة التتابع
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