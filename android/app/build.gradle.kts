plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // REQUIRED for flutter_local_notifications + Java 8 features
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        minSdk = flutter.minSdkVersion                       // you already updated this – correct!
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}

dependencies {

    // ❌ Remove this — it causes your error:
    // implementation(project(":flutter"))

    // REQUIRED for desugaring support
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // You may include this (optional)
    implementation("com.google.firebase:firebase-auth")
}

flutter {
    source = "../.."
}
