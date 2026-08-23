# Flutter Proguard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Play core optional classes in Flutter engine
-dontwarn com.google.android.play.core.**

# App Specific Classes
-keep class com.awqatsalaah.awqat_salaah.** { *; }
-keep class com.awqatsalaah.awqat_salaah.widget.** { *; }
-keep class com.awqatsalaah.awqat_salaah.boot.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
