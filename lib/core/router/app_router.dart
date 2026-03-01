import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/find_id_screen.dart';
import '../../features/auth/presentation/screens/find_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/signup_verification_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/link/presentation/screens/add_link_screen.dart';
import '../../features/link/presentation/screens/edit_link_screen.dart';
import '../../features/onboarding/presentation/screens/category_selection_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation.startsWith('/signup');
      final isFindRoute =
          state.matchedLocation.startsWith('/find-id') ||
          state.matchedLocation.startsWith('/find-password');
      final isAuthRoute = isLoginRoute || isSignupRoute || isFindRoute;

      // If not logged in and trying to access protected route
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // If logged in and trying to access auth routes
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            name: 'signup-verify',
            builder: (context, state) {
              final extra = state.extra as Map<String, String>?;
              return SignupVerificationScreen(
                username: extra?['username'] ?? '',
                email: extra?['email'] ?? '',
                password: extra?['password'] ?? '',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/find-id',
        name: 'find-id',
        builder: (context, state) => const FindIdScreen(),
      ),
      GoRoute(
        path: '/find-password',
        name: 'find-password',
        builder: (context, state) => const FindPasswordScreen(),
      ),

      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const CategorySelectionScreen(),
      ),

      // Main routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/add-link',
        name: 'add-link',
        builder: (context, state) => const AddLinkScreen(),
      ),
      GoRoute(
        path: '/edit-link/:linkId',
        name: 'edit-link',
        builder: (context, state) {
          final linkId = state.pathParameters['linkId']!;
          return EditLinkScreen(linkId: linkId);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('홈으로 이동'),
            ),
          ],
        ),
      ),
    ),
  );
});
