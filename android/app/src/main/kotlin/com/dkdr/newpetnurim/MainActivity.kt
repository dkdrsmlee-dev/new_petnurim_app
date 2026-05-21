package com.dkdr.newpetnurim

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.navercorp.nid.NidOAuth
import com.navercorp.nid.core.data.datastore.NidOAuthInitializingCallback
import com.navercorp.nid.oauth.domain.enum.NidOAuthLoginState
import com.navercorp.nid.oauth.util.NidOAuthCallback
import com.navercorp.nid.profile.domain.vo.NidProfile
import com.navercorp.nid.profile.domain.vo.NidProfileDetail
import com.navercorp.nid.profile.util.NidProfileCallback
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val NAVER_AUTH_CHANNEL = "petnurim/naver_auth"
        private const val CLIENT_USER_CANCEL = "CLIENT_USER_CANCEL"
        private const val NAVER_LOG_TAG = "PetnurimNaverAuth"
        private const val NAVER_READY_RETRY_DELAY_MS = 150L
        private const val NAVER_READY_MAX_RETRIES = 20
    }

    private var pendingNaverResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NAVER_AUTH_CHANNEL,
        ).setMethodCallHandler(::handleMethodCall)
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "login" -> startNaverLogin(call, result)
            else -> result.notImplemented()
        }
    }

    private fun startNaverLogin(call: MethodCall, result: MethodChannel.Result) {
        if (pendingNaverResult != null) {
            result.error("IN_PROGRESS", "네이버 로그인이 이미 진행 중입니다.", null)
            return
        }

        val clientId = call.argument<String>("clientId")
        val clientSecret = call.argument<String>("clientSecret")
        val clientName = call.argument<String>("clientName")

        Log.d(
            NAVER_LOG_TAG,
            "startNaverLogin clientId=$clientId clientName=$clientName hasSecret=${!clientSecret.isNullOrBlank()}",
        )

        if (clientId.isNullOrBlank() || clientSecret.isNullOrBlank() || clientName.isNullOrBlank()) {
            result.error("INVALID_ARGS", "네이버 로그인 설정값이 비어 있습니다.", null)
            return
        }

        pendingNaverResult = result

        NidOAuth.initialize(
            this,
            clientId,
            clientSecret,
            clientName,
            object : NidOAuthInitializingCallback {
                override fun onFailure(e: Exception) {
                    Log.e(NAVER_LOG_TAG, "Naver SDK initialize failed", e)
                    finishNaverWithError(
                        code = "INIT_ERROR",
                        message = "네이버 SDK 초기화에 실패했습니다. (${e.message ?: e.javaClass.simpleName})",
                    )
                }

                override fun onSuccess() {
                    Log.d(NAVER_LOG_TAG, "Naver SDK initialize success")
                    NidOAuth.setLogEnabled(true)
                    logNaverState("afterInitialize")
                    waitForNaverReadyThenRequestLogin()
                }
            },
        )
    }

    private fun waitForNaverReadyThenRequestLogin(attempt: Int = 0) {
        val state = NidOAuth.getState()
        val initialized = NidOAuth.isInitialized()
        Log.d(
            NAVER_LOG_TAG,
            "waitForNaverReady attempt=$attempt initialized=$initialized state=$state",
        )

        if (initialized && state != NidOAuthLoginState.NEED_INIT && state != NidOAuthLoginState.OAUTH_DATA_INITIALIZING) {
            requestNaverLogin()
            return
        }

        if (attempt >= NAVER_READY_MAX_RETRIES) {
            finishNaverWithError(
                code = "INIT_STATE_TIMEOUT",
                message = "네이버 로그인 SDK 초기화 상태를 확인하지 못했습니다. state=$state",
            )
            return
        }

        mainHandler.postDelayed(
            { waitForNaverReadyThenRequestLogin(attempt + 1) },
            NAVER_READY_RETRY_DELAY_MS,
        )
    }

    private fun requestNaverLogin() {
        logNaverState("beforeRequestLogin")

        val state = NidOAuth.getState()
        if (state == NidOAuthLoginState.OK || state == NidOAuthLoginState.NEED_REFRESH_TOKEN) {
            Log.d(
                NAVER_LOG_TAG,
                "Existing Naver token state detected. Logging out before fresh login. state=$state",
            )
            NidOAuth.logout(
                object : NidOAuthCallback {
                    override fun onSuccess() {
                        Log.d(NAVER_LOG_TAG, "Naver logout success before login retry")
                        logNaverState("afterLogoutSuccess")
                        requestFreshNaverLogin()
                    }

                    override fun onFailure(errorCode: String, errorDesc: String) {
                        Log.e(
                            NAVER_LOG_TAG,
                            "Naver logout failure before login retry errorCode=$errorCode errorDesc=$errorDesc",
                        )
                        logNaverState("afterLogoutFailure")
                        requestFreshNaverLogin()
                    }
                },
            )
            return
        }

        requestFreshNaverLogin()
    }

    private fun requestFreshNaverLogin() {
        Log.d(NAVER_LOG_TAG, "requestFreshNaverLogin NidOAuth.requestLogin(callback)")
        logNaverState("requestFreshLogin")
        NidOAuth.requestLogin(
            this,
            object : NidOAuthCallback {
                override fun onSuccess() {
                    handleNaverLoginSuccess()
                }

                override fun onFailure(errorCode: String, errorDesc: String) {
                    handleNaverLoginFailureFromSdk(errorCode, errorDesc)
                }
            },
        )
    }

    private fun handleNaverLoginSuccess() {
        Log.d(NAVER_LOG_TAG, "Naver authenticate success")
        logNaverState("onSuccess")
        val accessToken = NidOAuth.getAccessToken()
        if (accessToken.isNullOrBlank()) {
            finishNaverWithError(
                code = "TOKEN_EMPTY",
                message = "네이버 access token을 받지 못했습니다.",
            )
            return
        }

        NidOAuth.getUserProfile(
            object : NidProfileCallback<NidProfile> {
                override fun onSuccess(result: NidProfile) {
                    val detail: NidProfileDetail? = result.profile
                    Log.d(
                        NAVER_LOG_TAG,
                        "Naver profile success userId=${detail?.id} email=${detail?.email}",
                    )
                    val payload =
                        hashMapOf<String, Any?>(
                            "accessToken" to accessToken,
                            "refreshToken" to NidOAuth.getRefreshToken(),
                            "userId" to detail?.id,
                            "name" to detail?.name,
                            "nickname" to detail?.nickname,
                            "email" to detail?.email,
                            "mobile" to detail?.mobile,
                            "profileImage" to detail?.profileImage,
                        )
                    finishNaverWithSuccess(payload)
                }

                override fun onFailure(errorCode: String, errorDesc: String) {
                    Log.e(
                        NAVER_LOG_TAG,
                        "Naver profile failure errorCode=$errorCode message=$errorDesc",
                    )
                    finishNaverWithError(
                        code = "PROFILE_FAILURE",
                        message = "네이버 프로필 조회에 실패했습니다. ($errorCode: $errorDesc)",
                    )
                }
            },
        )
    }

    private fun handleNaverLoginFailureFromSdk(
        errorCode: String = NidOAuth.getLastErrorCode().code,
        errorDesc: String = NidOAuth.getLastErrorDescription().orEmpty(),
    ) {
        Log.e(
            NAVER_LOG_TAG,
            "Naver authenticate failure errorCode=$errorCode errorDesc=$errorDesc",
        )
        logNaverState("onFailure")
        if (errorCode == CLIENT_USER_CANCEL) {
            finishNaverWithError(
                code = "CANCELLED",
                message = "네이버 로그인이 취소되었습니다.",
            )
            return
        }

        finishNaverWithError(
            code = errorCode,
            message = "네이버 로그인에 실패했습니다. ($errorCode: $errorDesc)",
        )
    }

    private fun logNaverState(label: String) {
        val state = NidOAuth.getState()
        val initialized = NidOAuth.isInitialized()
        val hasAccessToken = !NidOAuth.getAccessToken().isNullOrBlank()
        val hasRefreshToken = !NidOAuth.getRefreshToken().isNullOrBlank()
        Log.d(
            NAVER_LOG_TAG,
            "state[$label] initialized=$initialized state=$state hasAccessToken=$hasAccessToken hasRefreshToken=$hasRefreshToken",
        )
    }

    private fun finishNaverWithSuccess(payload: Map<String, Any?>) {
        Log.d(NAVER_LOG_TAG, "finishNaverWithSuccess payloadKeys=${payload.keys}")
        pendingNaverResult?.success(payload)
        pendingNaverResult = null
    }

    private fun finishNaverWithError(code: String, message: String) {
        Log.e(NAVER_LOG_TAG, "finishNaverWithError code=$code message=$message")
        pendingNaverResult?.error(code, message, null)
        pendingNaverResult = null
    }
}
