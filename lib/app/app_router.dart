import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_start_screen.dart';
import '../features/home/home_screen.dart';
import '../features/member/my/my_info_screen.dart';
import '../features/member/my/withdraw_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/signup/complete_screen.dart';
import '../features/signup/profile_screen.dart';
import '../features/signup/terms_screen.dart';
import '../features/signup/verify_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/webview/address_webview_screen.dart';
import '../features/member/my/customer_center_screen.dart';
import '../features/member/my/my_pet_list_screen.dart';
import '../features/member/my/my_pet_detail_screen.dart';
import '../features/member/my/my_pet_edit_screen.dart';
import '../features/member/my/my_pet_add_screen.dart';
import '../features/member/my/my_pet_detail_form_screen.dart';
import '../features/member/my/my_pet_breed_select_screen.dart';
import '../features/member/my/my_pet_story_form_screen.dart';
import '../features/member/my/my_pet_health_form_screen.dart';
import '../features/member/my/my_pet_add_complete_screen.dart';
import '../features/notification/notification_screen.dart';
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
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = tabStr != null ? int.tryParse(tabStr) : null;
          return HomeScreen(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: AppRoutes.myInfo,
        name: AppRouteNames.myInfo,
        builder: (context, state) => const MyInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.myWithdraw,
        name: AppRouteNames.myWithdraw,
        builder: (context, state) => const WithdrawScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressWebView,
        name: AppRouteNames.addressWebView,
        builder: (context, state) => const AddressWebViewScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerCenter,
        name: AppRouteNames.customerCenter,
        builder: (context, state) => const CustomerCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.myPetList,
        name: AppRouteNames.myPetList,
        builder: (context, state) => const MyPetListScreen(),
      ),
      GoRoute(
        path: AppRoutes.myPetAdd,
        name: AppRouteNames.myPetAdd,
        builder: (context, state) => const MyPetAddScreen(),
      ),
      GoRoute(
        path: AppRoutes.myPetDetailForm,
        name: AppRouteNames.myPetDetailForm,
        builder: (context, state) {
          final petType = state.uri.queryParameters['petType'] ?? 'DOG';
          return MyPetDetailFormScreen(petType: petType);
        },
      ),
      GoRoute(
        path: AppRoutes.myPetBreedSelect,
        name: AppRouteNames.myPetBreedSelect,
        builder: (context, state) {
          final petType = state.uri.queryParameters['petType'] ?? 'DOG';
          return MyPetBreedSelectScreen(petType: petType);
        },
      ),
      GoRoute(
        path: AppRoutes.myPetStoryForm,
        name: AppRouteNames.myPetStoryForm,
        builder: (context, state) {
          final petType = state.uri.queryParameters['petType'] ?? 'DOG';
          final name = state.uri.queryParameters['name'] ?? '';
          final breed = state.uri.queryParameters['breed'];
          final breedId = state.uri.queryParameters['breedId'];
          final profileImagePath = state.uri.queryParameters['profileImagePath'];
          return MyPetStoryFormScreen(
            petType: petType,
            name: name,
            breed: breed,
            breedId: breedId,
            profileImagePath: profileImagePath,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myPetHealthForm,
        name: AppRouteNames.myPetHealthForm,
        builder: (context, state) {
          final petType = state.uri.queryParameters['petType'] ?? 'DOG';
          final name = state.uri.queryParameters['name'] ?? '';
          final breed = state.uri.queryParameters['breed'];
          final breedId = state.uri.queryParameters['breedId'];
          final profileImagePath = state.uri.queryParameters['profileImagePath'];
          final age = int.tryParse(state.uri.queryParameters['age'] ?? '1') ?? 1;
          final dateBecameFamily = state.uri.queryParameters['dateBecameFamily'];
          final gender = state.uri.queryParameters['gender'] ?? 'MALE';
          return MyPetHealthFormScreen(
            petType: petType,
            name: name,
            breed: breed,
            breedId: breedId,
            profileImagePath: profileImagePath,
            age: age,
            dateBecameFamily: dateBecameFamily,
            gender: gender,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myPetAddComplete,
        name: AppRouteNames.myPetAddComplete,
        builder: (context, state) {
          final myPetId = state.uri.queryParameters['myPetId'] ?? '';
          return MyPetAddCompleteScreen(myPetId: myPetId);
        },
      ),
      GoRoute(
        path: AppRoutes.myPetDetail,
        name: AppRouteNames.myPetDetail,
        builder: (context, state) {
          final myPetId = state.pathParameters['myPetId'] ?? '';
          return MyPetDetailScreen(myPetId: myPetId);
        },
      ),
      GoRoute(
        path: AppRoutes.myPetEdit,
        name: AppRouteNames.myPetEdit,
        builder: (context, state) {
          final myPetId = state.pathParameters['myPetId'] ?? '';
          return MyPetEditScreen(myPetId: myPetId);
        },
      ),
      GoRoute(
        path: AppRoutes.notificationCenter,
        name: AppRouteNames.notificationCenter,
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
});
