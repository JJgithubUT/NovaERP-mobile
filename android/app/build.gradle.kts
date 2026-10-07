import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciales de firma. android/key.properties queda FUERA del repositorio
// (ver .gitignore): contiene la contrasena del almacen de claves. Si el archivo
// no existe se compila con la clave de depuracion, para que `flutter run` siga
// funcionando en una maquina recien clonada.
val propiedadesFirma = Properties()
val archivoFirma = rootProject.file("key.properties")
val hayFirmaDeRelease = archivoFirma.exists()
if (hayFirmaDeRelease) {
    archivoFirma.inputStream().use { propiedadesFirma.load(it) }
}

android {
    namespace = "com.novaerp.movil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.novaerp.movil"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirmaDeRelease) {
            create("release") {
                keyAlias = propiedadesFirma.getProperty("keyAlias")
                keyPassword = propiedadesFirma.getProperty("keyPassword")
                storeFile = propiedadesFirma.getProperty("storeFile")?.let { file(it) }
                storePassword = propiedadesFirma.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties se firma con la clave de depuracion: sirve para
            // probar `--release` en local, pero un APK asi NO se puede publicar
            // ni actualizar despues con la clave real.
            signingConfig = if (hayFirmaDeRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
