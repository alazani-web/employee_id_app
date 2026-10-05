plugins {
    id("com.android.application")

    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration

    id("kotlin-android")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.employee.identity.employee_id_app"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ============================================================
    // Java / Core Library Desugaring
    // ============================================================

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // Required by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ============================================================
    // Default configuration
    // ============================================================

    defaultConfig {
        applicationId = "com.employee.identity.employee_id_app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ============================================================
    // Release
    // ============================================================

    buildTypes {
        release {
            // Using debug signing for now.
            // This allows testing the release APK.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// ================================================================
// Core Library Desugaring dependency
// ================================================================

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// ================================================================
// Flutter
// ================================================================

flutter {
    source = "../.."
}