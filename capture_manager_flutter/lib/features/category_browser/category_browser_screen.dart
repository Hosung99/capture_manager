import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../services/file_organizer_service.dart';

// Currently selected category ID; null = all captures
final _selectedCategoryProvider = StateProvider<int?>((ref) => null);

final _capturesByCategoryProvider =
    StreamProvider.family<List<CaptureItem>, int?>((ref, categoryId) {
  final dao = ref.watch(captureItemsDaoProvider);
  if (categoryId == null) return dao.watchAll();
  return dao.watchByCategory(categoryId);
});

class CategoryBrowserScreen extends ConsumerWidget {
  const CategoryBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (categories) => _BrowserLayout(categories: categories),
    );
  }
}

class _BrowserLayout extends ConsumerWidget {
  final List<Category> categories;
  const _BrowserLayout({required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(_selectedCategoryProvider);
    final capturesAsync =
        ref.watch(_capturesByCategoryProvider(selectedId));

    final isWide = MediaQuery.sizeOf(context).width > 600;
    final captureWidget = capturesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (captures) =>
          _CaptureGrid(captures: captures, categories: categories),
    );

    if (isWide) {
      return Row(
        children: [
          SizedBox(
            width: 180,
            child: _CategorySidebar(
              categories: categories,
              selectedId: selectedId,
              onSelect: (id) =>
                  ref.read(_selectedCategoryProvider.notifier).state = id,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: captureWidget),
        ],
      );
    }

    return Column(
      children: [
        _CategoryChips(
          categories: categories,
          selectedId: selectedId,
          onSelect: (id) =>
              ref.read(_selectedCategoryProvider.notifier).state = id,
        ),
        const Divider(height: 1),
        Expanded(child: captureWidget),
      ],
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _CategorySidebar({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.grid_view, size: 18),
          title: const Text('전체', style: TextStyle(fontSize: 13)),
          selected: selectedId == null,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          onTap: () => onSelect(null),
          dense: true,
        ),
        const Divider(height: 1),
        ...categories.map(
          (c) => ListTile(
            leading: Icon(_materialIcon(c.icon), size: 18),
            title: Text(c.localizedName,
                style: const TextStyle(fontSize: 13)),
            selected: selectedId == c.id,
            selectedTileColor:
                Theme.of(context).colorScheme.primaryContainer,
            onTap: () => onSelect(c.id),
            dense: true,
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final int? selectedId;
  final void Function(int?) onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          ChoiceChip(
            label: const Text('전체'),
            selected: selectedId == null,
            onSelected: (_) => onSelect(null),
          ),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(c.localizedName),
                selected: selectedId == c.id,
                onSelected: (_) => onSelect(c.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureGrid extends ConsumerWidget {
  final List<CaptureItem> captures;
  final List<Category> categories;

  const _CaptureGrid({
    required this.captures,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (captures.isEmpty) {
      return Center(
        child: Text(
          '캡처 없음',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: captures.length,
      itemBuilder: (context, i) => _GridItem(
        item: captures[i],
        categories: categories,
        onReclassify: (categoryName) async {
          final settings =
              await ref.read(settingsDaoProvider).get();
          if (settings == null) return;
          try {
            final organizer = FileOrganizerService();
            final newPath = await organizer.reclassifyFile(
              currentPath: captures[i].currentPath,
              outputDir: settings.outputDirectoryPath,
              newCategoryName: categoryName,
            );
            final matched =
                categories.where((c) => c.name == categoryName).firstOrNull;
            await ref.read(captureItemsDaoProvider).updateItem(
              captures[i].toCompanion(true).copyWith(
                    currentPath: Value(newPath),
                    categoryId: Value(matched?.id),
                    isMoved: const Value(true),
                  ),
            );
          } catch (_) {}
        },
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final CaptureItem item;
  final List<Category> categories;
  final void Function(String categoryName)? onReclassify;

  const _GridItem({
    required this.item,
    required this.categories,
    this.onReclassify,
  });

  @override
  Widget build(BuildContext context) {
    final category =
        categories.where((c) => c.id == item.categoryId).firstOrNull;

    return GestureDetector(
      onSecondaryTapUp: (d) => _showMenu(context, d.globalPosition),
      onLongPressStart: (d) => _showMenu(context, d.globalPosition),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _thumbnail()),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null)
                    Text(
                      category.localizedName,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final data = item.thumbnailData;
    if (data != null && data.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(data),
        fit: BoxFit.cover,
      );
    }
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 32),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        ...categories.map(
          (c) => PopupMenuItem(
            value: c.name,
            child: Text('${c.localizedName}(으)로 이동'),
          ),
        ),
      ],
    );
    if (result != null) onReclassify?.call(result);
  }
}

IconData _materialIcon(String sfSymbol) {
  return switch (sfSymbol) {
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
