import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/assistant/sam_sam_companion.dart';
import 'sam_sam_animated_character.dart';

class SamSamPopOut extends StatefulWidget {
  const SamSamPopOut({
    super.key,
    required this.onAsk,
    this.initialScale = .4,
    this.onScaleChanged,
  });

  final ValueChanged<String> onAsk;
  final double initialScale;
  final ValueChanged<double>? onScaleChanged;

  @override
  SamSamPopOutState createState() => SamSamPopOutState();
}

class SamSamPopOutState extends State<SamSamPopOut> {
  Timer? _bubbleTimer;
  Timer? _nextBubbleTimer;
  bool _visible = true;
  bool _bubbleVisible = true;
  bool _showGreeting = true;
  late double _characterScale = widget.initialScale;
  int _tipIndex = -1;

  static final _tips =
      <({String title, String message, String reference, String question})>[
        (
          title: 'Checking in',
          message:
              'How are you doing today? I’m here with you. Want to tell me what’s on your heart?',
          reference: '',
          question: '',
        ),
        (
          title: 'A gentle reminder',
          message:
              'Take a quiet moment with the Bible today. Even a few verses can bring light and encouragement.',
          reference: 'Psalm 119:105',
          question: 'Help me reflect on Psalm 119:105',
        ),
        for (final fact in SamSamFacts.facts)
          (
            title: 'Bible fact',
            message: fact.message,
            reference: fact.reference,
            question: fact.question,
          ),
        for (final story in SamSamFacts.stories)
          (
            title: 'Bible story · ${story.title}',
            message: story.message,
            reference: story.reference,
            question: story.question,
          ),
      ];

  @override
  void initState() {
    super.initState();
    _scheduleBubbleCycle();
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _nextBubbleTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SamSamPopOut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialScale != widget.initialScale) {
      _characterScale = widget.initialScale;
    }
  }

  bool get isVisible => _visible;
  bool get isBubbleVisible => _bubbleVisible;
  double get characterScale => _characterScale;

  void updateCharacterScale(double scale) {
    final boundedScale = scale.clamp(.25, 1.35);
    setState(() => _characterScale = boundedScale);
  }

  void _finishCharacterScale(double scale) {
    widget.onScaleChanged?.call(scale.clamp(.25, 1.35));
  }

  void _scheduleBubbleCycle() {
    _bubbleTimer?.cancel();
    _nextBubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || !_visible) return;
      setState(() => _bubbleVisible = false);
      _nextBubbleTimer = Timer(const Duration(seconds: 50), _showNextBubble);
    });
  }

  void _showNextBubble() {
    if (!mounted || !_visible) return;
    setState(() {
      _tipIndex = (_tipIndex + 1) % _tips.length;
      _showGreeting = false;
      _bubbleVisible = true;
    });
    _scheduleBubbleCycle();
  }

  void _showNextTip() {
    if (!mounted) return;
    setState(() {
      _tipIndex = (_tipIndex + 1) % _tips.length;
      _showGreeting = false;
      _bubbleVisible = true;
    });
    _scheduleBubbleCycle();
  }

  void _tapSamSam() {
    setState(() {
      _bubbleVisible = true;
      if (_showGreeting || _tipIndex < 0) {
        _tipIndex = 0;
        _showGreeting = false;
      } else {
        _tipIndex = (_tipIndex + 1) % _tips.length;
      }
    });
    _scheduleBubbleCycle();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return '$timeOfDay! I’m Sam-Sam. How are you doing today? Let’s make a little time for God’s Word together.';
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_visible && !_bubbleVisible,
    child: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_visible) return const SizedBox.expand();

          final height = math.min(244.0, constraints.maxHeight * .36);
          final characterHeight = height * _characterScale;
          final characterWidth = characterHeight * .665;
          final sideBubbleWidth = constraints.maxWidth - characterWidth - 34;
          final showBubbleBeside = sideBubbleWidth >= 120;
          final bubbleWidth = showBubbleBeside
              ? math.min(188.0, sideBubbleWidth)
              : math.max(120.0, constraints.maxWidth - 24);
          final tip = _showGreeting ? null : _tips[_tipIndex];
          final hasReference = tip?.reference.isNotEmpty ?? false;
          final hasQuestion = tip?.question.isNotEmpty ?? false;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: 8,
                bottom: 2,
                child: SamSamAnimatedCharacter(
                  key: const ValueKey('sam-sam-pop-out-character'),
                  height: characterHeight,
                  scaleFactor: _characterScale,
                  semanticsLabel:
                      'Sam-Sam. Tap to see another Bible fact or story. Pinch to resize.',
                  onTap: _tapSamSam,
                  onScaleChanged: updateCharacterScale,
                  onScaleEnd: _finishCharacterScale,
                ),
              ),
              if (_bubbleVisible)
                Positioned(
                  right: showBubbleBeside ? characterWidth + 24 : 12,
                  bottom: showBubbleBeside
                      ? characterHeight * .4
                      : characterHeight + 10,
                  width: bubbleWidth,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: .94 + (value * .06),
                        alignment: Alignment.bottomRight,
                        child: child,
                      ),
                    ),
                    child: _SpeechBubble(
                      bubbleKey: const ValueKey('sam-sam-thought-bubble'),
                      title: tip?.title ?? 'A little hello',
                      message: tip?.message ?? _greeting,
                      reference: hasReference ? tip!.reference : null,
                      question: hasQuestion ? tip!.question : null,
                      onNext: _showNextTip,
                      onAsk: widget.onAsk,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.bubbleKey,
    required this.title,
    required this.message,
    required this.onNext,
    required this.onAsk,
    this.reference,
    this.question,
  });

  final Key bubbleKey;
  final String title;
  final String message;
  final String? reference;
  final String? question;
  final VoidCallback onNext;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            key: bubbleKey,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: .18),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sam-Sam is thinking...',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (reference != null)
                        Text(
                          reference!,
                          style: const TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onNext,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            alignment: Alignment.centerLeft,
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text(
                            'Another',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      if (question != null)
                        IconButton(
                          tooltip: 'Chat with Sam-Sam',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onAsk(question!),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
