import 'package:flutter/material.dart';

class FadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
    this.beginOffset = const Offset(-0.3, 0),
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeSlideAnimation> createState() => _FadeSlideAnimationState();
}

class _FadeSlideAnimationState extends State<FadeSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _fade = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
