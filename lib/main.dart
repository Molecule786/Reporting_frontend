import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/unified_admin_screen.dart';
import 'screens/unified_employee_screen.dart';
import 'screens/edit_profile_screen.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const WorkFlowProApp());
}

class WorkFlowProApp extends StatelessWidget {
  const WorkFlowProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Molecule - WorkFlow Pro',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
      theme: AppTheme.themeData,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Force welcome screen for root and any unknown routes
        if (settings.name == '/' || settings.name == null || settings.name == '') {
          return MaterialPageRoute(builder: (context) => const WelcomeScreen());
        }
        
        // Handle other routes
        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(builder: (context) => const WelcomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignupScreen());
          case '/forgot-password':
            return MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (context) => const UnifiedEmployeeScreen());
          case '/admin':
            return MaterialPageRoute(builder: (context) => const UnifiedAdminScreen());
          case '/edit-profile':
            return MaterialPageRoute(builder: (context) => const EditProfileScreen());
          default:
            // For any unknown route, redirect to welcome
            return MaterialPageRoute(builder: (context) => const WelcomeScreen());
        }
      },
    );
  }
}
