plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.locallendinghub.local_lending_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // -------------------------------------------------------------------------
    // White-label flavor dimensions
    // Each client = one productFlavor with its own applicationId and resources.
    // Build: flutter build apk --flavor localLendingHub -t lib/main_local_lending_hub.dart
    // -------------------------------------------------------------------------
    flavorDimensions += "app"

    productFlavors {
        create("localLendingHub") {
            dimension = "app"
            applicationId = "com.locallendinghub.app"
            resValue("string", "app_name", "Local Lending Hub")
        }
        create("capeFinance") {
            dimension = "app"
            applicationId = "com.capefinance.app"
            resValue("string", "app_name", "Cape Finance")
        }
    }


    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
        debug {
            isDebuggable = true
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

