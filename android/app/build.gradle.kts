plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // Flutter Gradle 플러그인은 Android/Kotlin 플러그인 뒤에 적용합니다.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dkdr.newpetnurim"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 실제 배포 전 고유한 Application ID를 확정합니다.
        applicationId = "com.dkdr.newpetnurim"
        // 앱 요구사항에 맞춰 SDK/버전 값을 조정합니다.
        // 참고: https://flutter.dev/to/review-gradle-config
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 실제 배포 전 release 서명 설정을 별도로 추가합니다.
            // 현재는 `flutter run --release` 확인을 위해 debug 키를 사용합니다.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.navercorp.nid:oauth:5.11.2")
}
