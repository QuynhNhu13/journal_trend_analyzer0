plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase Gradle plugins are applied ONLY when google-services.json is present,
// so the project still builds before Firebase has been configured.
// After running `flutterfire configure`, google-services.json appears and these activate automatically.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.journal_trend_analyzer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.journal_trend_analyzer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Firebase Auth / Google Sign-In require a minimum SDK of 23.
        minSdk = maxOf(23, flutter.minSdkVersion)
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ── Patrol E2E test runner ──
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        // Keep app data (incl. the login session) between tests — do NOT clear.
        testInstrumentationRunnerArguments["clearPackageData"] = "false"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Required by Patrol to run each test in isolation via the Android Test
    // Orchestrator (while preserving app data — see clearPackageData=false above).
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Enables java.time (and other newer APIs) on older Android via desugaring —
    // required by flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Android Test Orchestrator used by Patrol.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
}
