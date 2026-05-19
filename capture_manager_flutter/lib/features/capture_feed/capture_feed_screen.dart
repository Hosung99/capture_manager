import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../services/file_organizer_service.dart';
import '../shared/capture_row_widget.dart';

class CaptureFeedScreen extends ConsumerWidget {
  const CaptureFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturesAsync = ref.watch(recentCapturesProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final monitor = ref.watch(screenshotMonitorProvider);

    return Column(
      children: [
        _MonitoringHeader(monitor: monitor),
        const Divider(height: 1),
        Expanded(
          child: capturesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (captures) {
              if (captures.isEmpty) return const _EmptyState();
              return categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => ListView.separated(
                  itemCount: captures.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 66),
                  itemBuilder: (context, i) {
                    final item = captures[i];
                    return CaptureRowWidget(
                      item: item,
                      categories: categories,
                      onRevealInFinder: (_) {},
                      onMove: (capture, categoryName) async {
                        final settings =
                            await ref.read(settingsDaoProvider).get();
                        if (settings == null) return;
                        try {
                          final organizer = FileOrganizerService();
                          final newPath = await organizer.reclassifyFile(
                            currentPath: capture.currentPath,
                            outputDir: settings.outputDirectoryPath,
                            newCategoryName: categoryName,
                          );
                          final matched = categories
                              .where((c) => c.name == categoryName)
                              .firstOrNull;
                          await ref.read(captureItemsDaoProvider).updateItem(
                            capture.toCompanion(true).copyWith(
                                  currentPath: Value(newPath),
                                  categoryId: Value(matched?.id),
                                  isMoved: const Value(true),
                                ),
                          );
                        } catch (_) {}
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonitoringHeader extends StatelessWidget {
  final dynamic monitor;
  const _MonitoringHeader({required this.monitor});

  @override
  Widget build(BuildContext context) {
    final isMonitoring = monitor.isMonitoring as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isMonitoring ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isMonitoring ? '모니터링 중' : '일시정지',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isMonitoring ? Icons.pause_circle : Icons.play_circle,
              size: 20,
            ),
            onPressed: () {
              if (isMonitoring) {
                monitor.stopMonitoring();
              }
              // Resume is handled in settings screen (path needed)
            },
            tooltip: isMonitoring ? '일시정지' : '재개',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.camera_enhance_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '캡처된 이미지가 없습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '스크린샷을 찍으면 자동으로 분류됩니다',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
