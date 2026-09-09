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

# Flutter Local Notifications & Gson (CRITICAL: preserve generic signatures and TypeToken)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }

# Gson rules
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keepclassmembers class * extends com.google.gson.reflect.TypeToken {
    protected <init>();
    <fields>;
    <methods>;
}
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-dontwarn sun.misc.**
