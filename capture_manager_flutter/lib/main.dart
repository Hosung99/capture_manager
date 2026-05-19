import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [dbProvider.overrideWithValue(db)],
      child: const CaptureManagerApp(),
    ),
  );
}
