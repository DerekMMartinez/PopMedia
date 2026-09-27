import 'package:flutter/material.dart';

class AsyncListBuilder<T> extends StatelessWidget {
  final Future<List<T>> future;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Axis scrollDirection;
  final double? height;
  final String emptyMessage;

  const AsyncListBuilder({
    super.key,
    required this.future,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.height,
    this.emptyMessage = 'No items found.',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        final listView = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Consume horizontal scroll gestures (fixes macOS back swipe)
            return scrollDirection == Axis.horizontal &&
                notification.metrics.axis == Axis.horizontal;
          },
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: scrollDirection,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) =>
                itemBuilder(context, snapshot.data![index]),
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(height: 10);
            },
          )
        );

        if (scrollDirection == Axis.horizontal && height != null) {
          return SizedBox(height: height, child: listView);
        }

        return listView;
      },
    );
  }
}
