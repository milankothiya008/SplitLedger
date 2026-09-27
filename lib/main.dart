import 'package:SmartSpend/data/app_data.dart';
import 'package:SmartSpend/screens/Wrapper.dart';
import 'package:SmartSpend/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Test-only web config, reusing the Android app's values from google-services.json.
// Replace with a registered Firebase Web app config for production.
const FirebaseOptions webTestOptions = FirebaseOptions(
  apiKey: 'AIzaSyCv8MZN8F6_R0t-Xjo4N-s81teH3B60gG0',
  appId: '1:975237376352:android:274706b169b02a19ab1605',
  messagingSenderId: '975237376352',
  projectId: 'smartspend-e464e',
  authDomain: 'smartspend-e464e.firebaseapp.com',
  storageBucket: 'smartspend-e464e.firebasestorage.app',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: kIsWeb ? webTestOptions : null);

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Preferences unavailable: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider(create: (_) => AppData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'SmartSpend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const Wrapper(),
    );
  }
}
