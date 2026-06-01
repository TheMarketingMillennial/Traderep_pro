import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ── Release signing config ────────────────────────────────────────────────────
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tradereppro.rep"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ── Signing configs ───────────────────────────────────────────────────────
    signingConfigs {
        create("release") {
            keyAlias     = keystoreProperties["keyAlias"] as String
            keyPassword  = keystoreProperties["keyPassword"] as String
            storeFile    = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId  = "com.tradereppro.rep"
        minSdk         = 21 // Stripe requires minSdk 21
        targetSdk      = flutter.targetSdkVersion
        // ── Version — bump these for each Play Store release ─────────────────
        // versionCode: integer, must increment with every upload to Play Store
        // versionName: human-readable string shown to users
        versionCode    = 1
        versionName    = "1.0.0"
    }

    buildTypes {
        // ── Debug ─────────────────────────────────────────────────────────────
        debug {
            // No applicationIdSuffix — keeps package name matching google-services.json
            versionNameSuffix = "-debug"
            isDebuggable      = true
        }
        // ── Release ───────────────────────────────────────────────────────────
        release {
            signingConfig   = signingConfigs.getByName("release")
            isMinifyEnabled = false   // set true + add proguard rules when ready to shrink
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
