import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('overridden in main');
});
