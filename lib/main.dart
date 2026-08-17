import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Auth wrapper
import './auth/auth_wrapper.dart';
import './core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartClinicApp());
}

class SmartClinicApp extends StatefulWidget {
  const SmartClinicApp({super.key});

  @override
  State<SmartClinicApp> createState() => _SmartClinicAppState();
}

class _SmartClinicAppState extends State<SmartClinicApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Clinic App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthWrapper(
        isDarkMode: isDarkMode,
        onThemeToggle: toggleTheme,
      ),
    );
  }
}
