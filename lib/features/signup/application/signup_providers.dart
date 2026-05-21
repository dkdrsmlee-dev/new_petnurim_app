import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../auth/domain/social_login_result.dart';
import '../data/signup_repository.dart';
import '../domain/signup_flow_state.dart';
import '../domain/signup_profile.dart';
import '../domain/signup_terms.dart';

const signupTermsCategories = [
  TermsCategory.signup,
  TermsCategory.security,
  TermsCategory.marketing,
];

final signupRepositoryProvider = Provider<SignupRepository>((ref) {
  return BackendSignupRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final activeTermsProvider = FutureProvider.autoDispose<List<ActiveTerm>>((ref) {
  return ref
      .watch(signupRepositoryProvider)
      .fetchActiveTerms(categories: signupTermsCategories);
});

class SignupFlowController extends Notifier<SignupFlowState> {
  @override
  SignupFlowState build() => const SignupFlowState();

  void startFromSocialLogin(SocialLoginResult result) {
    state = SignupFlowState.fromSocialLogin(result);
  }

  void updateProfile(SignupProfileDraft profile) {
    state = state.copyWith(profile: profile);
  }

  void mergeProfileInit(SignupProfileInit profileInit) {
    state = state.copyWith(profile: profileInit.mergeInto(state.profile));
  }

  void markVerificationComplete() {
    state = state.copyWith(verificationComplete: true);
  }

  void clear() {
    state = const SignupFlowState();
  }
}

final signupFlowProvider =
    NotifierProvider<SignupFlowController, SignupFlowState>(
      SignupFlowController.new,
    );
