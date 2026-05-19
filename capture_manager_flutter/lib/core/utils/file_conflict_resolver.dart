import 'dart:io';
import 'package:path/path.dart' as p;

/// Port of FileOrganizer.resolveNameConflict from Swift.
/// Returns a path that does not exist, appending (1), (2), etc. if needed.
String resolveNameConflict(String destinationPath) {
  if (!File(destinationPath).existsSync()) return destinationPath;

  final dir = p.dirname(destinationPath);
  final ext = p.extension(destinationPath);
  final nameWithoutExt = p.basenameWithoutExtension(destinationPath);

  var counter = 1;
  String candidate;
  do {
    final newName = ext.isEmpty
        ? '$nameWithoutExt ($counter)'
        : '$nameWithoutExt ($counter)$ext';
    candidate = p.join(dir, newName);
    counter++;
  } while (File(candidate).existsSync());

  return candidate;
}
