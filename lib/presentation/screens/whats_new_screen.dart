import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const _features = <(IconData, String, String)>[
    (
      Icons.nightlight_round,
      'Quiet Reading',
      'A peaceful, distraction-free way to read Scripture at night.',
    ),
    (
      Icons.history_rounded,
      'Last Light',
      'Return to the passage where you ended your nighttime reading.',
    ),
    (
      Icons.bedtime_outlined,
      'End My Reading',
      'Finish with Scripture, reflection, or a simple good-night moment.',
    ),
    (
      Icons.wb_sunny_outlined,
      'Morning Return',
      'Begin your day by returning to the Word you read the night before.',
    ),
    (
      Icons.tonality_rounded,
      'Warm Reading',
      'A softer nighttime appearance for a calmer experience.',
    ),
    (
      Icons.edit_note_rounded,
      'Context Slider',
      'Expand a single verse into its surrounding passage.',
    ),
    (
      Icons.touch_app_rounded,
      'Quick Context',
      'See the verses before and after without leaving the Bible reader.',
    ),
    (
      Icons.text_fields_rounded,
      'Key Words',
      'Quickly identify important words within the selected passage.',
    ),
    (
      Icons.swipe_rounded,
      'Give Me a Verse',
      'Find an encouraging Scripture based on what you are experiencing.',
    ),
    (
      Icons.history_rounded,
      'Better Bible Study',
      'Move naturally between Scripture, Connections, Focus, Reflection, and David.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('What’s New')),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.gold.withValues(alpha: .12),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          children: [
            Semantics(
              header: true,
              child: Text(
                'VERALUME 1.4.8',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quiet Light',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Read the Word. Quiet your heart. Rest in His presence.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            for (final feature in _features) ...[
              GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(feature.$1, color: AppTheme.gold),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(feature.$3, style: const TextStyle(height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            const Text(
              'Simple  •  Beautiful  •  Private  •  Offline  •  Meaningful',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
