plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")

    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Kotlin version
val kotlin_version = "1.9.25"

android {
    namespace = "com.example.smart_x"
    compileSdk = 36 // updated to latest required by plugins

    defaultConfig {
        applicationId = "com.example.smart_x"
        minSdk = flutter.minSdkVersion      // must be >=21 for flutter_local_notifications v19
        targetSdk = 35   // updated to latest
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isShrinkResources = false
        }
    }


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:$kotlin_version")
    implementation("androidx.core:core-ktx:1.10.1")
    implementation platform('com.google.firebase:firebase-bom:33.1.0')

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
