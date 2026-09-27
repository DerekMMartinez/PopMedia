import 'package:flutter/material.dart';

class GridListBuilder<T> extends StatefulWidget {
  final Future<List<T>>? future;
  final List<T>? items;
  final Widget Function(BuildContext context, T item) itemBuilder;

  final String emptyMessage;

  final int? maxRows;

  final double? cardHeight;


  const GridListBuilder({
    super.key,
    this.future,
    this.items,
    required this.itemBuilder,
    this.emptyMessage = 'No items found.',
    this.maxRows,
    this.cardHeight,
  }) : assert(future != null || items != null,
            'Either future or items must be provided');

  @override
  State<GridListBuilder<T>> createState() => _GridListBuilderState<T>();
}

class _GridListBuilderState<T> extends State<GridListBuilder<T>> {
  late Future<List<T>>? _future;
  late List<T>? _items;
  

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _future = widget.future;
  }

  @override
  Widget build(BuildContext context) {
    if (_items != null) {
      return _buildWrap(_items!);
    }

    // FutureBuilder only triggered once
    return FutureBuilder<List<T>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(widget.emptyMessage));
        }

        return _buildWrap(snapshot.data!);
      },
    );
  }

  Widget _buildWrap(List<T> list) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      final isDesktop = maxWidth >= 600;
      final spacing = 8.0;
      final minCardWidth = isDesktop ? 150 : 100;

      int itemsPerRow = (maxWidth / (minCardWidth + spacing)).floor().clamp(1, 100);

      List<T> visibleItems = [];
      int currentRow = 0;
      int index = 0;
      int maxRows = widget.maxRows ?? 1000;

      while (currentRow < maxRows && index < list.length) {
        int itemsLeft = list.length - index;
        int takeCount = itemsLeft >= itemsPerRow ? itemsPerRow : itemsLeft;

        visibleItems.addAll(list.getRange(index, index + takeCount));
        index += takeCount;
        currentRow++;
      }

      return SizedBox(
        width: maxWidth,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: visibleItems.map((item) {
            return SizedBox(
              width: (maxWidth - spacing * (itemsPerRow - 1)) / itemsPerRow,
              height: widget.cardHeight ?? 185,
              child: widget.itemBuilder(context, item),
            );
          }).toList(),
        ),
      );
    },
  );
}
}