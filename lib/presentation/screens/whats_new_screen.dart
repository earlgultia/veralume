import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass_card.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  static const _features = <(IconData, String, String)>[
    (
      Icons.psychology_alt_rounded,
      'Sam-Sam · connected conversations',
      'Online replies now take priority when internet access and secure AI configuration are available. The offline Bible guide remains available without a connection.',
    ),
    (
      Icons.calendar_month_rounded,
      'Faith Calendar',
      'Plan recurring devotionals, prayer time, Bible study, church, and personal faith events. Your schedule stays on this device.',
    ),
    (
      Icons.smart_toy_rounded,
      'A companion that fits',
      'Sam-Sam starts small, can be resized, and can be turned on or off in Settings.',
    ),
    (
      Icons.notifications_active_outlined,
      'Today’s Word reminder',
      'Improved mobile notification permission and schedule handling for the daily Scripture reminder.',
    ),
    (
      Icons.palette_outlined,
      'Theme picker',
      'Choose a color palette from a convenient theme-selection modal.',
    ),
    (
      Icons.auto_stories_rounded,
      'Stories and Bible quiz',
      'Clearer story cards, Scripture references, quiz progress, and answer feedback.',
    ),
    (
      Icons.wb_sunny_rounded,
      'Daily Devotional',
      'Begin the day grounded in a Bible verse, a short reflection, a practical lesson, and a prayer.',
    ),
    (
      Icons.volunteer_activism_rounded,
      'Prayer Journal',
      'Bring your worries into prayer, keep entries dated, and mark prayers answered. Entries stay on your device.',
    ),
    (
      Icons.blur_on_rounded,
      'Veralume UI 2.0',
      'A calmer, clearer Bible-reading experience with refined surfaces, smoother transitions, and polished Sam-Sam motion.',
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
                'VERALUME 1.5.4 • FAITH OVER FEAR',
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
              'COURAGE ROOTED IN SCRIPTURE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan your rhythm, find courage in Scripture, and make Veralume feel more like yours.',
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
              'Courage  •  Scripture  •  Prayer  •  Hope',
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
