import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

class CaptureRowWidget extends StatelessWidget {
  final CaptureItem item;
  final List<Category> categories;
  final void Function(CaptureItem, String categoryName)? onMove;
  final void Function(CaptureItem)? onRevealInFinder;

  const CaptureRowWidget({
    super.key,
    required this.item,
    required this.categories,
    this.onMove,
    this.onRevealInFinder,
  });

  @override
  Widget build(BuildContext context) {
    return ContextMenuRegion(
      menuItems: _buildMenuItems(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            _thumbnail(),
            const SizedBox(width: 10),
            Expanded(child: _info(context)),
            _confidenceBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    final data = item.thumbnailData;
    if (data != null && data.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          Uint8List.fromList(data),
          width: 44,
          height: 44,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 20),
    );
  }

  Widget _info(BuildContext context) {
    final category =
        categories.where((c) => c.id == item.categoryId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fileName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (category != null) ...[
              Text(
                category.localizedName,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _confidenceBadge(BuildContext context) {
    final pct = (item.confidenceScore * 100).round();
    final color = item.confidenceScore >= 0.6
        ? Colors.green
        : item.confidenceScore >= 0.3
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuItem(
        value: '__reveal__',
        child: const Row(
          children: [
            Icon(Icons.folder_open, size: 16),
            SizedBox(width: 8),
            Text('Finder에서 보기'),
          ],
        ),
      ),
      if (categories.isNotEmpty) const PopupMenuDivider(),
      ...categories.map(
        (c) => PopupMenuItem(
          value: c.name,
          child: Row(
            children: [
              const Icon(Icons.drive_file_move_outline, size: 16),
              const SizedBox(width: 8),
              Text('${c.localizedName}(으)로 이동'),
            ],
          ),
        ),
      ),
    ];
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${dt.month}/${dt.day}';
  }
}

// Thin context-menu wrapper that works on both macOS (right-click) and Android (long-press)
class ContextMenuRegion extends StatelessWidget {
  final List<PopupMenuEntry<String>> menuItems;
  final Widget child;
  final void Function(String)? onSelected;

  const ContextMenuRegion({
    super.key,
    required this.menuItems,
    required this.child,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (d) => _show(context, d.globalPosition),
      onLongPressStart: (d) => _show(context, d.globalPosition),
      child: child,
    );
  }

  Future<void> _show(BuildContext context, Offset position) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: menuItems,
    );
    if (result != null) onSelected?.call(result);
  }
}
