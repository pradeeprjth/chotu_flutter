import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'theme_provider.dart';
import 'router.dart';
import '../core/providers/notification_provider.dart';

class ChotuApp extends ConsumerStatefulWidget {
  const ChotuApp({super.key});

  @override
  ConsumerState<ChotuApp> createState() => _ChotuAppState();
}

class _ChotuAppState extends ConsumerState<ChotuApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    final router = ref.read(routerProvider);
    final notifier = ref.read(notificationProvider.notifier);

    // Set the router for navigation
    notifier.setRouter(router);

    // Initialize notification service
    await notifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Chotu - Instant Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
