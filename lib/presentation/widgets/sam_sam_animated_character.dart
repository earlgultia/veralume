import 'package:flutter/material.dart';

class SamSamAnimatedCharacter extends StatefulWidget {
  const SamSamAnimatedCharacter({
    super.key,
    required this.height,
    this.scaleFactor = 1,
    this.semanticsLabel = 'Sam-Sam, interactive Bible companion',
    this.onTap,
    this.onScaleChanged,
    this.onScaleEnd,
  });

  final double height;
  final double scaleFactor;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final ValueChanged<double>? onScaleChanged;
  final ValueChanged<double>? onScaleEnd;

  @override
  State<SamSamAnimatedCharacter> createState() =>
      _SamSamAnimatedCharacterState();
}

class _SamSamAnimatedCharacterState extends State<SamSamAnimatedCharacter> {
  static const _asset = 'assets/images/sam_sam_companion.png';
  double _scaleAtGestureStart = .4;
  double _currentScale = .4;

  void _onScaleStart(ScaleStartDetails details) {
    _scaleAtGestureStart = widget.scaleFactor;
    _currentScale = widget.scaleFactor;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    final scale = (_scaleAtGestureStart * details.scale).clamp(.25, 1.35);
    _currentScale = scale;
    widget.onScaleChanged?.call(scale);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onScaleEnd?.call(_currentScale);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    image: true,
    child: GestureDetector(
      key: const ValueKey('sam-sam-animated-character'),
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        width: widget.height * .665,
        height: widget.height,
        child: Image.asset(
          _asset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    ),
  );
}
