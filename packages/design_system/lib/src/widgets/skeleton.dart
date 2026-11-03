import 'package:flutter/material.dart';

import '../tokens.dart';

/// A quiet placeholder for content that is still loading.
///
/// A spinner tells the user "wait"; a skeleton tells them "this is a list and it
/// is on its way", which keeps the layout from jumping when the data lands.
class StarSkeleton extends StatefulWidget {
  const StarSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = StarRadius.field,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<StarSkeleton> createState() => _StarSkeletonState();
}

class _StarSkeletonState extends State<StarSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.05 + (_controller.value * 0.05)),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// A column of skeleton rows, sized like the list it stands in for.
class StarSkeletonList extends StatelessWidget {
  const StarSkeletonList({
    super.key,
    this.rows = 4,
    this.rowHeight = 56,
    this.padding = const EdgeInsets.all(StarSpace.md),
  });

  final int rows;
  final double rowHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var i = 0; i < rows; i++)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: padding.horizontal / 2,
              vertical: StarSpace.xs,
            ),
            child: StarSkeleton(height: rowHeight),
          ),
      ],
    );
  }
}
