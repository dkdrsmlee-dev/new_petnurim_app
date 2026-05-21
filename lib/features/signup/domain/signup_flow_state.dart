import '../../auth/domain/social_login_result.dart';
import 'signup_profile.dart';

class SignupFlowState {
  const SignupFlowState({
    this.signupToken,
    this.profile = const SignupProfileDraft(),
    this.verificationComplete = false,
  });

  final String? signupToken;
  final SignupProfileDraft profile;
  final bool verificationComplete;

  bool get hasSignupToken =>
      signupToken != null && signupToken!.trim().isNotEmpty;

  SignupFlowState copyWith({
    String? signupToken,
    SignupProfileDraft? profile,
    bool? verificationComplete,
  }) {
    return SignupFlowState(
      signupToken: signupToken ?? this.signupToken,
      profile: profile ?? this.profile,
      verificationComplete: verificationComplete ?? this.verificationComplete,
    );
  }

  factory SignupFlowState.fromSocialLogin(SocialLoginResult result) {
    return SignupFlowState(
      signupToken: result.credentialForNextStep,
      profile: SignupProfileDraft.fromSocialLogin(result),
    );
  }
}
