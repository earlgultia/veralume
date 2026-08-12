import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const _features = <(IconData, String, String)>[
    (
      Icons.route_rounded,
      'Walk Through the Word',
      'Bible Journey is a new way to explore Scripture and follow your progress through the Bible.',
    ),
    (
      Icons.light_mode_rounded,
      'Your Light for Today',
      'Receive a daily Scripture and a clearly labeled reflection, available completely offline.',
    ),
    (
      Icons.hub_rounded,
      'Verse Connections',
      'Discover curated passages connected to what you are reading.',
    ),
    (
      Icons.psychology_alt_rounded,
      'David Remembers',
      'David can help you revisit local reading history, bookmarks, highlights, and notes.',
    ),
    (
      Icons.directions_walk_rounded,
      'Walk With Me',
      'Begin guided, offline Bible journeys for real-life seasons and spiritual growth.',
    ),
    (
      Icons.spa_rounded,
      'Journey Milestones',
      'Notice meaningful milestones as you continue through Scripture.',
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
                'VERALUME 1.4.5',
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
              'The Journey Update',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Walk through the Word. One step at a time.',
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
