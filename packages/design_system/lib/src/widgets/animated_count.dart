import 'package:flutter/material.dart';

import '../tokens.dart';

/// A number that counts from its old value to its new one.
///
/// The Today figures are doors; when a job finishes and a figure moves, the
/// clerk should *feel* it move, not watch it snap. Under reduce-motion the new
/// value is shown instantly — motion announces a change, it never blocks one.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = StarMotion.standard,
  });

  final int value;
  final String Function(int value) format;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = _controller.drive(Tween<double>(begin: 0, end: 1));
    _controller.value = 1; // First paint shows the real value, no count-up.
  }

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    if (widget.value == _to) return;

    // The count animates from the value we are currently *showing*, so a rapid
    // sequence of changes never jumps backwards.
    _from = _to;
    _to = widget.value;

    final reduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduce) {
      _controller.value = 1;
      return;
    }
    _controller
      ..duration = widget.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final current = (_from + (_to - _from) * _animation.value).round();
        return Text(
          widget.format(current),
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        );
      },
    );
  }
}
