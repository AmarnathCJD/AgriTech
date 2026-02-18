import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/location_provider.dart';
import 'providers/crop_planning_provider.dart';
import 'providers/harvest_provider.dart';
import 'services/auth_service.dart';
import 'providers/chat_provider.dart';
import 'providers/localization_provider.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

import 'services/price_alert_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await PriceAlertService().init();

  await AuthService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CropPlanningProvider()),
        ChangeNotifierProvider(create: (_) => HarvestProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
      ],
      child: const AgriTechApp(),
    ),
  );
}

class AgriTechApp extends StatelessWidget {
  const AgriTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Farmora',
          debugShowCheckedModeBanner: false,
          theme: AgriTheme.themeData,
          locale: provider.currentLocale,
          home: const LoginScreen(),
          // home: const HomeScreen(),
        );
      },
    );
  }
}
