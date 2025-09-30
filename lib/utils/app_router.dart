import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/journey_provider.dart';
import '../screens/sign_in_screen.dart';
import '../screens/company_screen.dart';
import '../screens/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
        redirect: (context, state) {
          final authProvider = context.read<AuthProvider>();
          final journeyProvider = context.read<JourneyProvider>();

          if (!authProvider.isLoaded) return null;

          if (authProvider.isLoggedIn) {
            if (journeyProvider.isJourneyStarted) {
              return '/home';
            }
            return '/home';
          }

          return null;
        },
      ),
      GoRoute(
        path: '/company',
        name: 'company',
        builder: (context, state) => const CompanyScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        redirect: (context, state) {
          final authProvider = context.read<AuthProvider>();

          if (!authProvider.isLoggedIn) {
            return '/';
          }

          return null;
        },
      ),
    ],
  );
}
