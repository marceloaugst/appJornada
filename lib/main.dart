import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/journey_provider.dart';
import 'providers/auth_provider.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
  );

  runApp(const JornadaApp());
}

class JornadaApp extends StatelessWidget {
  const JornadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
      ],
      child: CupertinoApp.router(
        title: 'Jornada App',
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.systemBlue,
          barBackgroundColor: CupertinoColors.systemBackground,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.label,
          ),
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
