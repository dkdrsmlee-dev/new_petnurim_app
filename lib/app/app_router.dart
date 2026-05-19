import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_start_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/signup/complete_screen.dart';
import '../features/signup/profile_screen.dart';
import '../features/signup/terms_screen.dart';
import '../features/signup/verify_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/webview/address_webview_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.authStart,
        name: AppRouteNames.authStart,
        builder: (context, state) => const AuthStartScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupTerms,
        name: AppRouteNames.signupTerms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupVerify,
        name: AppRouteNames.signupVerify,
        builder: (context, state) => const VerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupProfile,
        name: AppRouteNames.signupProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupComplete,
        name: AppRouteNames.signupComplete,
        builder: (context, state) => const CompleteScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressWebView,
        name: AppRouteNames.addressWebView,
        builder: (context, state) => const AddressWebViewScreen(),
      ),
    ],
  );
});
