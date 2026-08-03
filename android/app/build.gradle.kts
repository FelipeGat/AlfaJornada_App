import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Lê credenciais do keystore se o arquivo existir. Não-commitado por design
// (em .gitignore). Quando ausente (ex.: CI sem chave), build cai no debug.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.alfa.alfajornada"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Habilita core library desugaring — necessário pelo
        // flutter_local_notifications (usa APIs de java.time em minSdk baixo).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.alfa.alfajornada"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // R8 + shrink de recursos — regras extras em proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Assina com chave própria quando keystore.properties existe.
            // Sem o arquivo, cai no debug — mas o build release só passa
            // com o opt-in explícito allowDebugSigning (gate no fim do
            // arquivo), pra um APK "release" debug-signed nunca sair por
            // engano pra distribuição.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Gate de assinatura: falha builds release sem keystore, a menos que o
// dev peça debug-sign explicitamente (ex.: testar `flutter run --release`
// sem a chave): ORG_GRADLE_PROJECT_allowDebugSigning=true ou
// -PallowDebugSigning=true.
gradle.taskGraph.whenReady {
    val vaiBuildarRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    val temKeystore = keystorePropertiesFile.exists()
    val debugSignPermitido = project.hasProperty("allowDebugSigning")
    if (vaiBuildarRelease && !temKeystore && !debugSignPermitido) {
        throw GradleException(
            "keystore.properties ausente — o build release seria assinado com a chave DEBUG. " +
                "Coloque o keystore.properties na raiz de android/ ou, pra um teste local " +
                "consciente, rode com ORG_GRADLE_PROJECT_allowDebugSigning=true."
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Runtime pro core library desugaring — obrigatório quando
    // isCoreLibraryDesugaringEnabled = true.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
