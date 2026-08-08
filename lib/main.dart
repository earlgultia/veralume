import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VeralumeApp()));
}

class VeralumeApp extends ConsumerWidget {
  const VeralumeApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veralume',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: !settings.loaded
          ? const _SplashScreen()
          : settings.onboarded
          ? const AppShell()
          : const OnboardingScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 72, color: AppTheme.gold),
          SizedBox(height: 18),
          Text('VERALUME', style: TextStyle(fontSize: 28, letterSpacing: 4)),
          SizedBox(height: 8),
          Text('Let His Word be your light.'),
        ],
      ),
    ),
  );
}
