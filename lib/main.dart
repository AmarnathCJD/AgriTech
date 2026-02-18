import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'providers/crop_planning_provider.dart';
import 'providers/harvest_provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart'; // Ensure this file exists
import 'theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  await AuthService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CropPlanningProvider()),
        ChangeNotifierProvider(create: (_) => HarvestProvider()),
      ],
      child: const AgriTechApp(),
    ),
  );
}

class AgriTechApp extends StatelessWidget {
  const AgriTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmora',
      debugShowCheckedModeBanner: false,
      theme: AgriTheme.themeData,
      home: const LoginScreen(),
    );
  }
}
