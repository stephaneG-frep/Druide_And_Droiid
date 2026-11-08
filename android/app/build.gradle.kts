import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.druideanddroiid.druide_and_droiid"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.druideanddroiid.druide_and_droiid"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Clé de publication : android/key.properties, ignoré par git, indique
    // storeFile, storePassword, keyAlias et keyPassword. Sans ce fichier, la
    // release est signée avec la clé de debug de la machine : installable,
    // mais pas publiable. Voir BUILD.md.
    val releaseKey = rootProject.file("key.properties")
    if (releaseKey.exists()) {
        val keys = Properties().apply { releaseKey.inputStream().use { load(it) } }
        signingConfigs {
            create("release") {
                storeFile = file(keys.getProperty("storeFile"))
                storePassword = keys.getProperty("storePassword")
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
            }
        }
    } else {
        logger.warn(
            "android/key.properties absent : release signée avec la clé de debug, non publiable.",
        )
    }

    buildTypes {
        release {
            signingConfig = if (releaseKey.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
