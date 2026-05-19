import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';
import 'providers/app_providers.dart';

class CaptureManagerApp extends ConsumerStatefulWidget {
  const CaptureManagerApp({super.key});

  @override
  ConsumerState<CaptureManagerApp> createState() => _CaptureManagerAppState();
}

class _CaptureManagerAppState extends ConsumerState<CaptureManagerApp> {
  @override
  void initState() {
    super.initState();
    // Wire background→main isolate message callback for Android
    registerBackgroundDataCallback(ref);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appInitProvider);

    return MaterialApp(
      title: 'CaptureManager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
