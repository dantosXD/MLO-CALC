# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Google Fonts
-keep class com.google.android.gms.fonts.** { *; }

# Google Play Core (optional classes - don't warn if missing)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Provider package
-keepclassmembers class ** {
    @androidx.annotation.Keep <fields>;
}
-keepclassmembers class ** {
    @androidx.annotation.Keep <methods>;
}
