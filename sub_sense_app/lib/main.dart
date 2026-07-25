import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/analysis_provider.dart';
import 'theme/app_colors.dart';
import 'widgets/nav_shell.dart';
import 'screens/upload_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/simulator_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
      ],
      child: const SubSenseApp(),
    ),
  );
}

class SubSenseApp extends StatelessWidget {
  const SubSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          surface: AppColors.paper,
          primary: AppColors.ink,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnalysisProvider>(context);

    Widget currentBody;
    switch (provider.activeTabIndex) {
      case 0:
        currentBody = const UploadScreen();
        break;
      case 1:
        currentBody = const DashboardScreen();
        break;
      case 2:
        currentBody = const SubscriptionsScreen();
        break;
      case 3:
        currentBody = const SimulatorScreen();
        break;
      case 4:
        currentBody = const Center(child: Text('Actions (Phase 6)'));
        break;
      case 5:
        currentBody = const Center(child: Text('AI Coach (Phase 6)'));
        break;
      default:
        currentBody = const UploadScreen();
    }

    return NavShell(body: currentBody);
  }
}
