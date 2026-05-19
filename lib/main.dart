import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'repositories/service_locator.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/student_home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (ServiceLocator.useFirebase) {
    try {
      // Tries to initialize standard default firebase options.
      // If the user runs FlutterFire configure, this will connect automatically.
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("Firebase failed to initialize. Make sure google-services.json is present. Error: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Campus Helper',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Supports both light & dark mode dynamically
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If loading auth state, show a splash progress indicator
    if (authProvider.isLoading && authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initializing Campus Helper...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      final user = authProvider.currentUser!;
      if (user.role == UserRole.admin) {
        return const AdminHomeScreen();
      } else {
        return const StudentHomeScreen();
      }
    }

    // Default to login if not authenticated
    return const LoginScreen();
  }
}
