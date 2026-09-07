import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/recipe_provider.dart';
import 'services/user_service.dart';
import 'services/review_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<UserService>(create: (_) => UserService()),
        Provider<ReviewService>(create: (_) => ReviewService()),
        ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(userService: ctx.read<UserService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, RecipeProvider>(
          create: (_) => RecipeProvider(),
          update: (_, auth, recipeProvider) =>
              (recipeProvider ?? RecipeProvider())..updateUser(auth.user?.uid),
        ),
      ],
      child: Consumer2<ThemeController, AuthProvider>(
        builder: (context, themeController, auth, _) {
          // Keep ThemeController updated if user doc specifies a theme mode
          if (auth.isAuthenticated && !auth.isAnonymous && auth.themeMode.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              themeController.syncFromUserDoc(auth.themeMode);
            });
          }

          return MaterialApp(
            title: 'Recipe App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
