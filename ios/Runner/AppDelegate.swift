import Flutter
import NidThirdPartyLogin
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let naverAuthChannelName = "petnurim/naver_auth"
  private let defaultNaverUrlScheme = "com.dkdr.newPetnurimApp"
  private var pendingNaverResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let naverAuthChannel = FlutterMethodChannel(
        name: naverAuthChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      naverAuthChannel.setMethodCallHandler(handleNaverAuthCall)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if NidOAuth.shared.handleURL(url) == true {
      return true
    }

    return super.application(app, open: url, options: options)
  }

  private func handleNaverAuthCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "login":
      startNaverLogin(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startNaverLogin(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if pendingNaverResult != nil {
      result(FlutterError(code: "IN_PROGRESS", message: "네이버 로그인이 이미 진행 중입니다.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGS", message: "네이버 로그인 설정값이 비어 있습니다.", details: nil))
      return
    }

    let clientId = (arguments["clientId"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let clientSecret = (arguments["clientSecret"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let clientName = (arguments["clientName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let requestedUrlScheme = (arguments["urlScheme"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let urlScheme = requestedUrlScheme?.isEmpty == false
      ? requestedUrlScheme!
      : (Bundle.main.bundleIdentifier ?? defaultNaverUrlScheme)

    guard
      let clientId,
      !clientId.isEmpty,
      let clientSecret,
      !clientSecret.isEmpty,
      let clientName,
      !clientName.isEmpty
    else {
      result(FlutterError(code: "INVALID_ARGS", message: "네이버 로그인 설정값이 비어 있습니다.", details: nil))
      return
    }

    pendingNaverResult = result

    NidOAuth.shared.initialize(
      appName: clientName,
      clientId: clientId,
      clientSecret: clientSecret,
      urlScheme: urlScheme
    )
    NidOAuth.shared.setLoginBehavior(.appPreferredWithInAppBrowserFallback)

    NidOAuth.shared.requestLogin { [weak self] loginResult in
      guard let self else { return }

      switch loginResult {
      case .success(let loginResult):
        self.fetchNaverUserProfile(
          accessToken: loginResult.accessToken.tokenString,
          refreshToken: loginResult.refreshToken.tokenString
        )
      case .failure(let error):
        self.finishNaverWithError(
          code: "LOGIN_FAILURE",
          message: "네이버 로그인에 실패했습니다. (\(error.localizedDescription))"
        )
      }
    }
  }

  private func fetchNaverUserProfile(accessToken: String, refreshToken: String?) {
    NidOAuth.shared.getUserProfile(accessToken: accessToken) { [weak self] result in
      guard let self else { return }

      switch result {
      case .success(let profileResult):
        var payload: [String: String] = [
          "accessToken": accessToken
        ]

        if let refreshToken, !refreshToken.isEmpty {
          payload["refreshToken"] = refreshToken
        }

        if let userId = profileResult["id"], !userId.isEmpty {
          payload["userId"] = userId
        }
        if let name = profileResult["name"], !name.isEmpty {
          payload["name"] = name
        }
        if let nickname = profileResult["nickname"], !nickname.isEmpty {
          payload["nickname"] = nickname
        }
        if let email = profileResult["email"], !email.isEmpty {
          payload["email"] = email
        }
        if let mobile = profileResult["mobile"] ?? profileResult["mobile_e164"], !mobile.isEmpty {
          payload["mobile"] = mobile
        }
        if let profileImage = profileResult["profile_image"], !profileImage.isEmpty {
          payload["profileImage"] = profileImage
        }

        self.finishNaverWithSuccess(payload)
      case .failure(let error):
        self.finishNaverWithError(
          code: "PROFILE_FAILURE",
          message: "네이버 프로필 조회에 실패했습니다. (\(error.localizedDescription))"
        )
      }
    }
  }

  private func finishNaverWithSuccess(_ payload: [String: String]) {
    pendingNaverResult?(payload)
    pendingNaverResult = nil
  }

  private func finishNaverWithError(code: String, message: String) {
    pendingNaverResult?(FlutterError(code: code, message: message, details: nil))
    pendingNaverResult = nil
  }
}
