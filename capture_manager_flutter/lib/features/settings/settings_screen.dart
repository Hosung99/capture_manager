import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/categories_dao.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '일반'),
              Tab(text: '카테고리'),
              Tab(text: 'AI'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralTab(),
            _CategoryTab(),
            _AiTab(),
          ],
        ),
      ),
    );
  }
}

// ── General Tab ────────────────────────────────────────────────────────────

class _GeneralTab extends ConsumerWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (settings) {
        if (settings == null) return const SizedBox.shrink();
        return _GeneralForm(settings: settings);
      },
    );
  }
}

class _GeneralForm extends ConsumerStatefulWidget {
  final AppSetting settings;
  const _GeneralForm({required this.settings});

  @override
  ConsumerState<_GeneralForm> createState() => _GeneralFormState();
}

class _GeneralFormState extends ConsumerState<_GeneralForm> {
  late bool _autoMove;
  late bool _monitoringEnabled;

  @override
  void initState() {
    super.initState();
    _autoMove = widget.settings.autoMoveEnabled;
    _monitoringEnabled = widget.settings.isMonitoringEnabled;
  }

  Future<void> _pickDirectory({required bool isSource}) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: isSource ? '소스 폴더 선택' : '출력 폴더 선택',
    );
    if (dir == null) return;

    final dao = ref.read(settingsDaoProvider);
    await dao.upsert(
      isSource
          ? AppSettingsCompanion(sourceDirectoryPath: Value(dir))
          : AppSettingsCompanion(outputDirectoryPath: Value(dir)),
    );
  }

  Future<void> _save() async {
    final dao = ref.read(settingsDaoProvider);
    await dao.upsert(
      AppSettingsCompanion(
        autoMoveEnabled: Value(_autoMove),
        isMonitoringEnabled: Value(_monitoringEnabled),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source directory
        _DirectoryTile(
          label: '스크린샷 소스 폴더',
          path: widget.settings.sourceDirectoryPath,
          onTap: () => _pickDirectory(isSource: true),
        ),
        const SizedBox(height: 12),
        // Output directory
        _DirectoryTile(
          label: '출력 폴더',
          path: widget.settings.outputDirectoryPath,
          onTap: () => _pickDirectory(isSource: false),
        ),
        const Divider(height: 32),
        SwitchListTile(
          title: const Text('자동 이동'),
          subtitle: const Text('신뢰도 임계값 이상이면 자동으로 파일 이동'),
          value: _autoMove,
          onChanged: (v) {
            setState(() => _autoMove = v);
            _save();
          },
        ),
        SwitchListTile(
          title: const Text('모니터링 활성화'),
          value: _monitoringEnabled,
          onChanged: (v) {
            setState(() => _monitoringEnabled = v);
            _save();
            final monitor = ref.read(screenshotMonitorProvider);
            if (v) {
              monitor.startMonitoring(widget.settings.sourceDirectoryPath);
            } else {
              monitor.stopMonitoring();
            }
          },
        ),
      ],
    );
  }
}

class _DirectoryTile extends StatelessWidget {
  final String label;
  final String path;
  final VoidCallback onTap;

  const _DirectoryTile({
    required this.label,
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    path.isEmpty ? '선택 안 됨' : path,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Category Tab ───────────────────────────────────────────────────────────

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (categories) => _CategoryList(categories: categories),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final List<Category> categories;
  const _CategoryList({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return ListTile(
          leading: Icon(_materialIcon(cat.icon), size: 18),
          title: Text(cat.localizedName),
          subtitle: Text(
            '키워드 ${cat.keywordList.length}개',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: cat.isDefault
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    await ref
                        .read(categoriesDaoProvider)
                        .deleteCategory(cat.id);
                  },
                ),
          onTap: () => _showKeywordEditor(context, ref, cat),
        );
      },
    );
  }

  Future<void> _showKeywordEditor(
    BuildContext context,
    WidgetRef ref,
    Category cat,
  ) async {
    final controller =
        TextEditingController(text: cat.keywordList.join(', '));

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${cat.localizedName} 키워드'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '쉼표로 구분 (예: Figma, Sketch)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final keywords = controller.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              await ref.read(categoriesDaoProvider).updateCategory(
                    cat
                        .toCompanion(true)
                        .copyWith(keywords: Value(keywords.join(','))),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

// ── AI Tab ─────────────────────────────────────────────────────────────────

class _AiTab extends ConsumerWidget {
  const _AiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (settings) {
        if (settings == null) return const SizedBox.shrink();
        return _AiForm(settings: settings);
      },
    );
  }
}

class _AiForm extends ConsumerStatefulWidget {
  final AppSetting settings;
  const _AiForm({required this.settings});

  @override
  ConsumerState<_AiForm> createState() => _AiFormState();
}

class _AiFormState extends ConsumerState<_AiForm> {
  late double _threshold;

  @override
  void initState() {
    super.initState();
    _threshold = widget.settings.confidenceThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('분류 신뢰도 임계값',
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '이 값 이상일 때만 자동으로 파일을 이동합니다: ${(_threshold * 100).round()}%',
          style:
              const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Slider(
          value: _threshold,
          min: 0.3,
          max: 0.9,
          divisions: 12,
          label: '${(_threshold * 100).round()}%',
          onChanged: (v) => setState(() => _threshold = v),
          onChangeEnd: (v) async {
            await ref.read(settingsDaoProvider).upsert(
                  AppSettingsCompanion(
                      confidenceThreshold: Value(v)),
                );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('30%', style: TextStyle(fontSize: 11, color: Colors.grey)),
            Text('90%', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

IconData _materialIcon(String icon) {
  return switch (icon) {
    'code' => Icons.code,
    'chat_bubble' => Icons.chat_bubble,
    'language' => Icons.language,
    'brush' => Icons.brush,
    'description' => Icons.description,
    'terminal' => Icons.terminal,
    'photo' => Icons.photo,
    'play_circle' => Icons.play_circle,
    _ => Icons.grid_view,
  };
}
