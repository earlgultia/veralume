import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/bible_models.dart';
import '../../domain/quiz/bible_quiz.dart';
import '../providers/app_providers.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF24213E), Color(0xFF6B5730)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Icon(
                Icons.auto_stories_rounded,
                size: 76,
                color: AppTheme.gold,
              ),
              const SizedBox(height: 24),
              const Text(
                'VERALUME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 5,
                ),
              ),
              const Text(
                'Let His Word be your light.',
                style: TextStyle(color: Color(0xFFEFE4C7), fontSize: 20),
              ),
              const SizedBox(height: 44),
              for (final item in [
                ('Offline Bible', Icons.offline_bolt),
                ('Search Scripture', Icons.search),
                ('Bookmarks & highlights', Icons.bookmark),
                ('Personal notes', Icons.edit_note),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Icon(item.$2, color: AppTheme.gold),
                      const SizedBox(width: 16),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final s = ref.read(settingsProvider);
                  ref
                      .read(settingsProvider.notifier)
                      .update(s.copyWith(onboarded: true));
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Begin reading'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigate: (i) => setState(() => index = i)),
      const BibleScreen(),
      const SearchScreen(),
      BookmarksScreen(refreshToken: index),
      NotesScreen(refreshToken: index),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories),
              label: 'Bible',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            NavigationDestination(icon: Icon(Icons.edit_note), label: 'Notes'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.highlightTitle = false,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool highlightTitle;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(
            title,
            style: highlightTitle
                ? const TextStyle(
                    color: AppTheme.gold,
                    fontFamily: 'serif',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 5.2,
                  )
                : null,
          ),
          actions: actions,
          backgroundColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          sliver: SliverToBoxAdapter(child: child),
        ),
      ],
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return PageFrame(
      title: 'VERALUME',
      highlightTitle: true,
      child: FutureBuilder(
        future: Future.wait([repo.dailyVerse(DateTime.now()), repo.history()]),
        builder: (context, snapshot) {
          final daily = snapshot.hasData
              ? snapshot.data![0] as BibleVerse
              : null;
          final history = snapshot.hasData
              ? snapshot.data![1] as List<BibleVerse>
              : <BibleVerse>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHero(greeting: greeting),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ContinueReading(
                  verse: history.first,
                  onTap: () => openReader(
                    context,
                    ref,
                    history.first.bookId,
                    history.first.chapter,
                    focusVerse: history.first.number,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const _HomeHeading('Daily light', 'A verse selected for today'),
              const SizedBox(height: 12),
              _DailyVerseCard(verse: daily),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Explore',
                'Everything works completely offline',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final half = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _HomeAction(
                        half,
                        'Read Bible',
                        'Books & chapters',
                        Icons.auto_stories_rounded,
                        () => onNavigate(1),
                      ),
                      _HomeAction(
                        half,
                        'Search',
                        'Find Scripture',
                        Icons.manage_search_rounded,
                        () => onNavigate(2),
                      ),
                      _HomeAction(
                        half,
                        'Saved',
                        'Bookmarks & highlights',
                        Icons.bookmarks_rounded,
                        () => onNavigate(3),
                      ),
                      _HomeAction(
                        half,
                        'Notes',
                        'Personal reflections',
                        Icons.edit_note_rounded,
                        () => onNavigate(4),
                      ),
                      _HomeAction(
                        constraints.maxWidth,
                        'Bible Stories',
                        '22 Scripture stories · completely offline',
                        Icons.menu_book_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BibleStoriesScreen(),
                          ),
                        ),
                        featured: true,
                      ),
                      _HomeAction(
                        constraints.maxWidth,
                        'Offline Bible Quiz',
                        'Easy, medium, or hard · 10 questions',
                        Icons.quiz_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BibleQuizScreen(),
                          ),
                        ),
                        featured: true,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              const _HomeHeading(
                'Recently read',
                'Return to your latest passages',
              ),
              const SizedBox(height: 8),
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (history.isEmpty)
                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: AppTheme.gold),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text('Your opened passages will appear here.'),
                      ),
                      IconButton(
                        tooltip: 'Read Bible',
                        onPressed: () => onNavigate(1),
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                )
              else
                for (final verse in history.take(4))
                  _RecentPassage(
                    verse: verse,
                    onTap: () => openReader(
                      context,
                      ref,
                      verse.bookId,
                      verse.chapter,
                      focusVerse: verse.number,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _StoryPassage {
  const _StoryPassage(
    this.bookOrder,
    this.chapter,
    this.startVerse,
    this.label,
  );
  final int bookOrder, chapter, startVerse;
  final String label;
}

class _BibleStory {
  const _BibleStory(
    this.title,
    this.subtitle,
    this.summary,
    this.icon,
    this.passages,
  );
  final String title, subtitle, summary;
  final IconData icon;
  final List<_StoryPassage> passages;
}

const _bibleStories = <_BibleStory>[
  _BibleStory(
    'Noah and the Flood',
    'Faith, judgment, and God’s covenant',
    'When violence filled the earth, Noah trusted God and built the ark. God preserved Noah’s family and the animals through the flood, then placed the rainbow in the sky as the sign of his covenant with every living creature.',
    Icons.water_rounded,
    [
      _StoryPassage(1, 6, 9, 'Genesis 6:9–22 · The ark is commanded'),
      _StoryPassage(1, 7, 1, 'Genesis 7 · The flood comes'),
      _StoryPassage(1, 8, 1, 'Genesis 8 · The waters recede'),
      _StoryPassage(1, 9, 1, 'Genesis 9:1–17 · God’s covenant'),
    ],
  ),
  _BibleStory(
    'David and Goliath',
    'Courage rooted in trust in God',
    'The Philistine champion Goliath terrified Israel’s army, but young David faced him without armor. Trusting in the Lord rather than weapons or size, David defeated Goliath with a sling and a stone.',
    Icons.shield_rounded,
    [_StoryPassage(9, 17, 1, '1 Samuel 17 · David faces Goliath')],
  ),
  _BibleStory(
    'Daniel in the Lions’ Den',
    'Faithfulness under pressure',
    'Daniel continued praying to God even after a royal decree made it illegal. He was thrown into a den of lions, but God sent an angel to keep him safe, showing the king that the living God delivers those who trust him.',
    Icons.pets_rounded,
    [_StoryPassage(27, 6, 1, 'Daniel 6 · God rescues Daniel')],
  ),
  _BibleStory(
    'The Birth of Jesus',
    'The promised Savior is born',
    'Mary and Joseph traveled to Bethlehem, where Jesus was born and laid in a manger. Angels announced good news of great joy to nearby shepherds: the promised Savior and Lord had come.',
    Icons.nightlight_round,
    [
      _StoryPassage(40, 1, 18, 'Matthew 1:18–25 · Joseph’s obedience'),
      _StoryPassage(42, 2, 1, 'Luke 2:1–20 · Jesus is born'),
    ],
  ),
  _BibleStory(
    'Jesus Calms the Storm',
    'Peace in the middle of fear',
    'A violent storm overwhelmed the disciples’ boat while Jesus slept. When they cried out, Jesus rebuked the wind and waves, and the sea became calm. The disciples marveled that even nature obeyed him.',
    Icons.storm_rounded,
    [_StoryPassage(41, 4, 35, 'Mark 4:35–41 · The storm is stilled')],
  ),
  _BibleStory(
    'The Good Samaritan',
    'What it means to love your neighbor',
    'Jesus told of a wounded traveler ignored by respected passersby but helped generously by a Samaritan. The story teaches that mercy crosses social boundaries and that loving a neighbor is something we actively do.',
    Icons.volunteer_activism_rounded,
    [_StoryPassage(42, 10, 25, 'Luke 10:25–37 · A neighbor shows mercy')],
  ),
  _BibleStory(
    'The Prodigal Son',
    'The Father’s welcoming grace',
    'A younger son wasted his inheritance and returned home expecting to be treated as a servant. His father ran to welcome him and celebrated his return, revealing God’s joy when the lost repent and come home.',
    Icons.home_rounded,
    [_StoryPassage(42, 15, 11, 'Luke 15:11–32 · The lost son returns')],
  ),
  _BibleStory(
    'The Resurrection of Jesus',
    'The empty tomb and risen Lord',
    'On the first day of the week, Jesus’ followers found the tomb empty. Jesus rose from the dead as he had promised, appeared to his disciples, and turned their grief into hope and a mission to share the good news.',
    Icons.wb_sunny_rounded,
    [_StoryPassage(43, 20, 1, 'John 20 · Jesus rises and appears')],
  ),
  _BibleStory(
    'The Creation',
    'God creates the heavens and the earth',
    'God brought light, order, and life into being, forming the world and every living creature. Humanity was made in God’s image and entrusted with caring for creation, and God rested after completing his work.',
    Icons.public_rounded,
    [
      _StoryPassage(1, 1, 1, 'Genesis 1 · God creates the world'),
      _StoryPassage(1, 2, 1, 'Genesis 2 · Life in the garden'),
    ],
  ),
  _BibleStory(
    'Abraham Trusts God',
    'A promise, a journey, and tested faith',
    'God called Abram to leave his homeland and promised to make him a blessing to all nations. Years later, Abraham’s trust was tested on Mount Moriah, where God provided a ram in place of Isaac.',
    Icons.route_rounded,
    [
      _StoryPassage(1, 12, 1, 'Genesis 12:1–9 · Abram is called'),
      _StoryPassage(1, 22, 1, 'Genesis 22:1–19 · Abraham is tested'),
    ],
  ),
  _BibleStory(
    'Joseph Forgives His Brothers',
    'God brings good through hardship',
    'Joseph’s jealous brothers sold him into slavery, but God remained with him and raised him to authority in Egypt. During famine, Joseph revealed himself to his brothers and chose forgiveness, recognizing that God had used his suffering to save many lives.',
    Icons.handshake_rounded,
    [
      _StoryPassage(1, 37, 1, 'Genesis 37 · Joseph is sold'),
      _StoryPassage(1, 45, 1, 'Genesis 45 · Joseph reveals himself'),
    ],
  ),
  _BibleStory(
    'Moses and the Red Sea',
    'God delivers Israel from Egypt',
    'Trapped between Pharaoh’s army and the sea, the Israelites were afraid. God opened a path through the waters, led his people safely across on dry ground, and delivered them from their pursuers.',
    Icons.waves_rounded,
    [_StoryPassage(2, 14, 1, 'Exodus 14 · Israel crosses the sea')],
  ),
  _BibleStory(
    'The Walls of Jericho',
    'Obedience before an impossible city',
    'Israel followed God’s unusual instructions by marching around Jericho for seven days. When the priests sounded their trumpets and the people shouted, the walls fell and the city was opened before them.',
    Icons.location_city_rounded,
    [_StoryPassage(6, 6, 1, 'Joshua 6 · The walls fall')],
  ),
  _BibleStory(
    'Gideon’s Small Army',
    'God’s strength, not human numbers',
    'God called the hesitant Gideon to rescue Israel from Midian, then reduced his army to only three hundred men. Their surprising victory made clear that Israel had been delivered by God rather than by military strength.',
    Icons.groups_rounded,
    [
      _StoryPassage(7, 6, 11, 'Judges 6:11–40 · Gideon is called'),
      _StoryPassage(7, 7, 1, 'Judges 7 · Three hundred men'),
    ],
  ),
  _BibleStory(
    'Elijah on Mount Carmel',
    'The Lord answers by fire',
    'Elijah challenged the prophets of Baal before the people of Israel. After their altar remained silent, Elijah prayed and the Lord consumed his water-soaked sacrifice with fire, turning the people’s hearts back to God.',
    Icons.local_fire_department_rounded,
    [_StoryPassage(11, 18, 17, '1 Kings 18:17–40 · God answers Elijah')],
  ),
  _BibleStory(
    'Queen Esther’s Courage',
    'Risking everything to save her people',
    'When a plot threatened the Jewish people, Esther chose to approach the king even though doing so could cost her life. Through courage, wisdom, and fasting, she exposed the plot and helped bring deliverance to her people.',
    Icons.workspace_premium_rounded,
    [
      _StoryPassage(17, 4, 1, 'Esther 4 · Esther chooses courage'),
      _StoryPassage(17, 7, 1, 'Esther 7 · The plot is exposed'),
    ],
  ),
  _BibleStory(
    'The Fiery Furnace',
    'Faith that would not bow',
    'Shadrach, Meshach, and Abednego refused to worship the king’s golden image. They were thrown into a blazing furnace, but God preserved them, and the king saw a fourth figure walking with them in the fire.',
    Icons.whatshot_rounded,
    [_StoryPassage(27, 3, 1, 'Daniel 3 · God protects his servants')],
  ),
  _BibleStory(
    'Jonah and the Great Fish',
    'Running from God and learning mercy',
    'Jonah fled from God’s call to warn Nineveh, but a storm and a great fish turned him back. Nineveh repented when Jonah preached, and God used the prophet’s anger to teach him about compassion and mercy.',
    Icons.sailing_rounded,
    [
      _StoryPassage(32, 1, 1, 'Jonah 1 · Jonah runs away'),
      _StoryPassage(32, 2, 1, 'Jonah 2 · Jonah prays'),
      _StoryPassage(32, 3, 1, 'Jonah 3 · Nineveh repents'),
      _StoryPassage(32, 4, 1, 'Jonah 4 · God teaches mercy'),
    ],
  ),
  _BibleStory(
    'Jesus Feeds Five Thousand',
    'A small offering becomes enough',
    'A large crowd followed Jesus into a remote place. With five loaves and two fish, Jesus gave thanks and fed everyone until they were satisfied, with twelve baskets of pieces left over.',
    Icons.restaurant_rounded,
    [_StoryPassage(41, 6, 30, 'Mark 6:30–44 · Jesus feeds the crowd')],
  ),
  _BibleStory(
    'Jesus and Zacchaeus',
    'A changed life welcomes salvation',
    'Zacchaeus climbed a tree to see Jesus above the crowd. Jesus called him down and entered his home, and the tax collector responded with repentance, generosity, and a promise to repay those he had cheated.',
    Icons.park_rounded,
    [_StoryPassage(42, 19, 1, 'Luke 19:1–10 · Jesus seeks the lost')],
  ),
  _BibleStory(
    'The Day of Pentecost',
    'The Holy Spirit empowers the church',
    'As the disciples gathered in Jerusalem, the Holy Spirit came with the sound of a rushing wind and tongues like fire. They spoke in other languages, Peter proclaimed Jesus, and thousands received the message and were baptized.',
    Icons.air_rounded,
    [_StoryPassage(44, 2, 1, 'Acts 2 · The Holy Spirit is given')],
  ),
  _BibleStory(
    'Saul Meets Jesus',
    'A persecutor becomes a witness',
    'While traveling to arrest believers in Damascus, Saul was stopped by a light from heaven and encountered the risen Jesus. After Ananias prayed for him, Saul regained his sight, was baptized, and began proclaiming Jesus.',
    Icons.flash_on_rounded,
    [_StoryPassage(44, 9, 1, 'Acts 9:1–31 · Saul’s life is changed')],
  ),
];

class BibleStoriesScreen extends StatelessWidget {
  const BibleStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bible Stories')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.offline_bolt_rounded, color: AppTheme.gold),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All stories and Scripture passages are available offline.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < _bibleStories.length; index++) ...[
          Builder(
            builder: (context) {
              final story = _bibleStories[index];
              return GlassCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _BibleStoryScreen(story: story),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(story.icon, color: AppTheme.gold),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(story.subtitle),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              );
            },
          ),
          if (index != _bibleStories.length - 1) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _BibleStoryScreen extends ConsumerWidget {
  const _BibleStoryScreen({required this.story});
  final _BibleStory story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    final books = repo.books(ref.watch(settingsProvider).defaultVersionId);
    return Scaffold(
      appBar: AppBar(title: const Text('Bible Story')),
      body: FutureBuilder<List<BibleBook>>(
        future: books,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
          children: [
            Icon(story.icon, size: 58, color: AppTheme.gold),
            const SizedBox(height: 18),
            Text(
              story.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              story.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppTheme.gold),
            ),
            const SizedBox(height: 28),
            Text(
              story.summary,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.65,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Read the event in Scripture',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              const Text('The Scripture passages could not be loaded.')
            else if (!snapshot.hasData)
              const Center(child: CircularProgressIndicator())
            else
              for (final passage in story.passages)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      final matches = snapshot.data!.where(
                        (book) => book.order == passage.bookOrder,
                      );
                      if (matches.isNotEmpty) {
                        openReader(
                          context,
                          ref,
                          matches.first.id,
                          passage.chapter,
                          focusVerse: passage.startVerse,
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: Text(passage.label),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.greeting});
  final String greeting;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.gold.withValues(alpha: .30),
          Theme.of(context).colorScheme.primary.withValues(alpha: .14),
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -12,
          top: -18,
          child: Icon(
            Icons.light_mode_rounded,
            size: 118,
            color: AppTheme.gold.withValues(alpha: .12),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppTheme.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  greeting.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Let His Word\nbe your light.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Scripture, reflection, and growth—wherever you are.'),
          ],
        ),
      ],
    ),
  );
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 2),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _DailyVerseCard extends StatelessWidget {
  const _DailyVerseCard({required this.verse});
  final BibleVerse? verse;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: verse == null
        ? const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.format_quote_rounded, color: AppTheme.gold),
              const SizedBox(height: 8),
              Text(
                verse!.text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.48,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(width: 24, height: 2, color: AppTheme.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${verse!.reference} · ${verse!.versionAbbreviation}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
  );
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading({required this.verse, required this.onTap});
  final BibleVerse verse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: AppTheme.gold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CONTINUE READING',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                verse.reference,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(verse.versionAbbreviation),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ],
    ),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction(
    this.width,
    this.title,
    this.subtitle,
    this.icon,
    this.onTap, {
    this.featured = false,
  });
  final double width;
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool featured;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: GlassCard(
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: featured
                  ? AppTheme.gold.withValues(alpha: .22)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: featured ? AppTheme.gold : null),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecentPassage extends StatelessWidget {
  const _RecentPassage({required this.verse, required this.onTap});
  final BibleVerse verse;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '${verse.chapter}',
        style: const TextStyle(
          color: AppTheme.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    title: Text(
      verse.reference,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(verse.text, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class LegacyHomeScreen extends ConsumerWidget {
  const LegacyHomeScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(bibleRepositoryProvider);
    return PageFrame(
      title: 'Veralume',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let His Word be your light.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 22),
          FutureBuilder(
            future: repo.dailyVerse(DateTime.now()),
            builder: (c, s) => GlassCard(
              child: s.hasData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VERSE OF THE DAY',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“${s.data!.text}”',
                          style: Theme.of(c).textTheme.titleLarge?.copyWith(
                            height: 1.45,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${s.data!.reference} · ${s.data!.versionAbbreviation}',
                        ),
                      ],
                    )
                  : const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          const SizedBox(height: 26),
          Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Quick('Read Bible', Icons.auto_stories, () => onNavigate(1)),
              _Quick('Search', Icons.search, () => onNavigate(2)),
              _Quick('Bookmarks', Icons.bookmark, () => onNavigate(3)),
              _Quick('Notes', Icons.edit_note, () => onNavigate(4)),
              _Quick(
                'Bible Quiz',
                Icons.quiz_outlined,
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BibleQuizScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Recently read', style: Theme.of(context).textTheme.titleLarge),
          FutureBuilder(
            future: repo.history(),
            builder: (c, s) => Column(
              children: (s.data ?? [])
                  .take(5)
                  .map(
                    (v) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(v.reference),
                      subtitle: Text(
                        v.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => openReader(
                        c,
                        ref,
                        v.bookId,
                        v.chapter,
                        focusVerse: v.number,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick(this.label, this.icon, this.tap);
  final String label;
  final IconData icon;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon),
    label: Text(label),
    onPressed: tap,
    padding: const EdgeInsets.all(10),
  );
}

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  int? versionId;
  BibleBook? book;
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(bibleRepositoryProvider);
    return PageFrame(
      title: 'Bible',
      child: FutureBuilder(
        future: repo.versions(),
        builder: (c, vs) {
          if (!vs.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final preferredVersion = ref.read(settingsProvider).defaultVersionId;
          versionId ??=
              vs.data!.any((version) => version.id == preferredVersion)
              ? preferredVersion
              : vs.data!.first.id;
          return Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: versionId,
                decoration: const InputDecoration(labelText: 'Bible version'),
                items: vs.data!
                    .map(
                      (v) => DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.name} (${v.abbreviation})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  versionId = v;
                  book = null;
                }),
              ),
              const SizedBox(height: 16),
              FutureBuilder(
                future: repo.books(versionId!),
                builder: (c, bs) {
                  if (!bs.hasData) return const LinearProgressIndicator();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final testament in ['OT', 'NT']) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 18, bottom: 8),
                          child: Text(
                            testament == 'OT'
                                ? 'Old Testament'
                                : 'New Testament',
                            style: Theme.of(c).textTheme.titleLarge,
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: bs.data!
                              .where((b) => b.testament == testament)
                              .length,
                          itemBuilder: (c, i) {
                            final b = bs.data!
                                .where((x) => x.testament == testament)
                                .elementAt(i);
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _chapters(c, b),
                                child: Center(
                                  child: Text(
                                    b.name,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _chapters(BuildContext context, BibleBook b) async {
    final count = await ref.read(bibleRepositoryProvider).chapterCount(b.id);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.name, style: Theme.of(c).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: count,
                  itemBuilder: (c, i) => _NumberButton(
                    key: ValueKey('pick-chapter-${i + 1}'),
                    label: '${i + 1}',
                    onPressed: () {
                      Navigator.pop(c);
                      _verses(context, b, i + 1);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verses(
    BuildContext context,
    BibleBook book,
    int chapter,
  ) async {
    final verses = await ref
        .read(bibleRepositoryProvider)
        .chapter(book.id, chapter);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${book.name} $chapter',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a verse',
                style: Theme.of(sheetContext).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('read-whole-chapter'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openReader(context, ref, book.id, chapter);
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Read whole chapter'),
              ),
              const SizedBox(height: 16),
              if (verses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No verses found in this chapter.'),
                  ),
                )
              else
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: verses.length,
                    itemBuilder: (gridContext, index) {
                      final verse = verses[index];
                      return _NumberButton(
                        key: ValueKey('pick-verse-${verse.number}'),
                        label: '${verse.number}',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          openReader(
                            context,
                            ref,
                            book.id,
                            chapter,
                            focusVerse: verse.number,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  const _NumberButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openReader(
  BuildContext context,
  WidgetRef ref,
  int bookId,
  int chapter, {
  int? focusVerse,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) =>
        ReaderScreen(bookId: bookId, chapter: chapter, focusVerse: focusVerse),
  ),
);

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.focusVerse,
  });
  final int bookId, chapter;
  final int? focusVerse;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late int chapter = widget.chapter;
  late int bookId = widget.bookId;
  final Set<int> selected = {};
  bool? _lastFullScreen;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _recordedPassages = {};
  bool _focusApplied = false;

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(bibleRepositoryProvider),
        settings = ref.watch(settingsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_lastFullScreen != settings.fullScreen) {
      _lastFullScreen = settings.fullScreen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setEnabledSystemUIMode(
          settings.fullScreen
              ? SystemUiMode.immersiveSticky
              : SystemUiMode.edgeToEdge,
        );
      });
    }
    return FutureBuilder(
      future: Future.wait([
        repo.chapter(bookId, chapter),
        repo.highlightsForChapter(bookId, chapter),
      ]),
      builder: (c, s) {
        if (s.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('This chapter could not be opened.\n${s.error}'),
            ),
          );
        }
        if (!s.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final verses = s.data![0] as List<BibleVerse>,
            highlights = s.data![1] as Map<int, String>;
        if (verses.isNotEmpty && _recordedPassages.add('$bookId:$chapter')) {
          repo.addHistory(verses.first.id);
        }
        if (!_focusApplied && widget.focusVerse != null && verses.isNotEmpty) {
          _focusApplied = true;
          final index = verses.indexWhere(
            (verse) => verse.number == widget.focusVerse,
          );
          if (index >= 0) {
            selected.add(verses[index].id);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients && verses.length > 1) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent *
                      index /
                      (verses.length - 1),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              }
            });
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(
              verses.isEmpty ? 'Bible' : '${verses.first.bookName} $chapter',
            ),
            actions: [
              FutureBuilder(
                future: repo.versions(),
                builder: (context, snapshot) => PopupMenuButton<int>(
                  tooltip: 'Switch Bible version',
                  icon: const Icon(Icons.translate),
                  itemBuilder: (_) => [
                    for (final version in snapshot.data ?? <BibleVersion>[])
                      PopupMenuItem(
                        value: version.id,
                        child: Text(
                          '${version.name} (${version.abbreviation})',
                        ),
                      ),
                  ],
                  onSelected: (versionId) async {
                    final target = await repo.equivalentBook(bookId, versionId);
                    if (target != null && mounted) {
                      setState(() {
                        bookId = target;
                        selected.clear();
                      });
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: 'Reading settings',
                onPressed: () => _readingSettings(context),
                icon: const Icon(Icons.text_fields),
              ),
            ],
          ),
          body: SelectionArea(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
              itemCount: verses.length,
              itemBuilder: (c, i) {
                final v = verses[i], hex = highlights[v.id];
                return Semantics(
                  label: 'Verse ${v.number}',
                  button: true,
                  child: AnimatedContainer(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 5),
                    decoration: BoxDecoration(
                      color: selected.contains(v.id)
                          ? AppTheme.gold.withValues(alpha: .18)
                          : hex == null
                          ? null
                          : _color(hex).withValues(alpha: .24),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      key: ValueKey('verse-${v.number}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (!selected.add(v.id)) selected.remove(v.id);
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (settings.showVerseNumbers)
                                TextSpan(
                                  text: '${v.number}  ',
                                  style: const TextStyle(
                                    color: AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              TextSpan(text: v.text),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: settings.fontSize,
                            height: settings.lineHeight,
                            fontFamily: settings.serif ? 'serif' : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: selected.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _actions(
                    context,
                    verses
                        .where((verse) => selected.contains(verse.id))
                        .toList(),
                  ),
                  icon: const Icon(Icons.edit),
                  label: Text(
                    selected.length == 1
                        ? '1 verse selected'
                        : '${selected.length} verses selected',
                  ),
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: chapter > 1
                          ? () => setState(() {
                              chapter--;
                              selected.clear();
                            })
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        final count = await repo.chapterCount(bookId);
                        if (chapter < count && mounted) {
                          setState(() {
                            chapter++;
                            selected.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _color(String hex) =>
      Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  Future<void> _actions(
    BuildContext context,
    List<BibleVerse> selectedVerses,
  ) async {
    final repo = ref.read(bibleRepositoryProvider);
    final verseIds = selectedVerses.map((verse) => verse.id);
    final first = selectedVerses.first;
    final last = selectedVerses.last;
    final reference = selectedVerses.length == 1
        ? first.reference
        : '${first.bookName} ${first.chapter}:${first.number}-${last.number}';
    final selectedText = selectedVerses
        .map((verse) => '${verse.number} ${verse.text}')
        .join('\n');
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: Text(
                selectedVerses.length == 1
                    ? 'Toggle bookmark'
                    : 'Toggle bookmarks',
              ),
              onTap: () async {
                await repo.toggleBookmarks(verseIds);
                HapticFeedback.lightImpact();
                if (c.mounted) Navigator.pop(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.highlight),
              title: const Text('Highlight'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final x in ['F6D365', '8ED1B2', '93B8F4', 'D4A5E8'])
                    GestureDetector(
                      onTap: () {
                        repo.setHighlights(verseIds, x);
                        Navigator.pop(c);
                        setState(() {});
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _color(x),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.format_color_reset),
              title: const Text('Remove highlight'),
              onTap: () async {
                await repo.setHighlights(verseIds, null);
                if (c.mounted) Navigator.pop(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Add note'),
              enabled: selectedVerses.length == 1,
              subtitle: selectedVerses.length == 1
                  ? null
                  : const Text('Notes attach to one verse at a time'),
              onTap: selectedVerses.length != 1
                  ? null
                  : () {
                      Navigator.pop(c);
                      _note(context, first);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '$reference — $selectedText (${first.versionAbbreviation})',
                  ),
                );
                Navigator.pop(c);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                final box = context.findRenderObject() as RenderBox?;
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '$reference\n$selectedText\n${first.versionAbbreviation}',
                    sharePositionOrigin: box == null
                        ? null
                        : box.localToGlobal(Offset.zero) & box.size,
                  ),
                );
                Navigator.pop(c);
              },
            ),
          ],
        ),
      ),
    );
    if (mounted) setState(selected.clear);
  }

  Future<void> _note(BuildContext context, BibleVerse v) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Note on ${v.reference}'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Write your reflection…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(bibleRepositoryProvider)
                    .saveNote(v.id, controller.text.trim());
              }
              Navigator.pop(c);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _readingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => Consumer(
        builder: (c, ref, _) {
          final s = ref.watch(settingsProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Text size ${s.fontSize.round()}',
                    style: Theme.of(c).textTheme.titleMedium,
                  ),
                  Slider(
                    value: s.fontSize,
                    min: 14,
                    max: 32,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(fontSize: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Serif reading font'),
                    value: s.serif,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(serif: v)),
                  ),
                  SwitchListTile(
                    title: const Text('Verse numbers'),
                    value: s.showVerseNumbers,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(showVerseNumbers: v)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  List<BibleVerse>? results;
  bool loading = false;
  int? versionId;
  int? bookId;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> run() async {
    setState(() => loading = true);
    try {
      results = await ref
          .read(bibleRepositoryProvider)
          .search(controller.text, versionId: versionId, bookId: bookId);
    } catch (_) {
      results = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Search Scripture',
    child: Column(
      children: [
        FutureBuilder(
          future: ref.read(bibleRepositoryProvider).versions(),
          builder: (context, snapshot) => DropdownButtonFormField<int?>(
            initialValue: versionId,
            decoration: const InputDecoration(labelText: 'Translation'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All versions')),
              for (final version in snapshot.data ?? <BibleVersion>[])
                DropdownMenuItem(
                  value: version.id,
                  child: Text('${version.name} (${version.abbreviation})'),
                ),
            ],
            onChanged: (value) => setState(() {
              versionId = value;
              bookId = null;
            }),
          ),
        ),
        if (versionId != null) ...[
          const SizedBox(height: 10),
          FutureBuilder(
            future: ref.read(bibleRepositoryProvider).books(versionId!),
            builder: (context, snapshot) => DropdownButtonFormField<int?>(
              initialValue: bookId,
              decoration: const InputDecoration(labelText: 'Book'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All books')),
                for (final book in snapshot.data ?? <BibleBook>[])
                  DropdownMenuItem(value: book.id, child: Text(book.name)),
              ],
              onChanged: (value) => setState(() => bookId = value),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => run(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Love, faith, salvation…',
            suffixIcon: IconButton(
              onPressed: run,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        if (results != null && !loading && results!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 56),
                SizedBox(height: 12),
                Text('No verses found. Try another word or phrase.'),
              ],
            ),
          ),
        if (results != null)
          for (final v in results!)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              title: Text('${v.reference} · ${v.versionAbbreviation}'),
              subtitle: Text(
                v.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => openReader(
                context,
                ref,
                v.bookId,
                v.chapter,
                focusVerse: v.number,
              ),
            ),
      ],
    ),
  );
}

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key, this.refreshToken = 0});
  final int refreshToken;
  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  final searchController = TextEditingController();
  bool showHighlights = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Saved Scripture',
    child: Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.bookmark),
              label: Text('Bookmarks'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.highlight),
              label: Text('Highlights'),
            ),
          ],
          selected: {showHighlights},
          onSelectionChanged: (value) =>
              setState(() => showHighlights = value.first),
        ),
        const SizedBox(height: 14),
        if (!showHighlights)
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search bookmarks',
            ),
          ),
        const SizedBox(height: 12),
        if (showHighlights) _highlightList(context) else _bookmarkList(context),
      ],
    ),
  );

  Widget _bookmarkList(BuildContext context) => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .bookmarks(query: searchController.text),
    builder: (c, s) {
      final items = s.data ?? <BibleVerse>[];
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        return const _Empty(
          icon: Icons.bookmark_outline,
          title: 'No bookmarks found',
          message: 'Select a verse while reading to save it here.',
        );
      }
      return Column(
        children: [
          for (final verse in items)
            Dismissible(
              key: ValueKey('bookmark-${verse.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(c),
              onDismissed: (_) =>
                  ref.read(bibleRepositoryProvider).toggleBookmark(verse.id),
              child: _verseTile(c, verse),
            ),
        ],
      );
    },
  );

  Widget _highlightList(BuildContext context) => FutureBuilder(
    future: ref.read(bibleRepositoryProvider).highlights(),
    builder: (c, s) {
      final items = s.data ?? <SavedVerse>[];
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (items.isEmpty) {
        return const _Empty(
          icon: Icons.highlight,
          title: 'No highlights yet',
          message: 'Select verses in the reader and choose a highlight color.',
        );
      }
      return Column(
        children: [
          for (final saved in items)
            Dismissible(
              key: ValueKey('highlight-${saved.id}'),
              direction: DismissDirection.endToStart,
              background: _deleteBackground(c),
              onDismissed: (_) => ref
                  .read(bibleRepositoryProvider)
                  .setHighlight(saved.verse.id, null),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 5,
                      color: Color(int.parse('FF${saved.color}', radix: 16)),
                    ),
                  ),
                ),
                child: _verseTile(c, saved.verse),
              ),
            ),
        ],
      );
    },
  );

  Widget _deleteBackground(BuildContext context) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.all(20),
    color: Theme.of(context).colorScheme.errorContainer,
    child: const Icon(Icons.delete),
  );

  Widget _verseTile(BuildContext context, BibleVerse verse) => ListTile(
    title: Text('${verse.reference} · ${verse.versionAbbreviation}'),
    subtitle: Text(verse.text, maxLines: 3, overflow: TextOverflow.ellipsis),
    onTap: () => openReader(
      context,
      ref,
      verse.bookId,
      verse.chapter,
      focusVerse: verse.number,
    ),
  );
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key, this.refreshToken = 0});
  final int refreshToken;
  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Notes',
    child: Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search notes',
          ),
        ),
        const SizedBox(height: 12),
        _notesList(),
      ],
    ),
  );

  Widget _notesList() => FutureBuilder(
    future: ref
        .read(bibleRepositoryProvider)
        .notes(query: searchController.text),
    builder: (c, s) {
      if (s.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = s.data ?? [];
      if (items.isEmpty) {
        return const _Empty(
          icon: Icons.edit_note,
          title: 'No notes yet',
          message: 'Select a verse and add a personal reflection.',
        );
      }
      return Column(
        children: [
          for (final n in items) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              onTap: () => openReader(
                c,
                ref,
                n.verse.bookId,
                n.verse.chapter,
                focusVerse: n.verse.number,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.verse.reference,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(n.content ?? ''),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit note',
                    onPressed: () => _editNote(c, n),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete note',
                    onPressed: () async {
                      await ref.read(bibleRepositoryProvider).deleteNote(n.id);
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    },
  );

  Future<void> _editNote(BuildContext context, SavedVerse note) async {
    final controller = TextEditingController(text: note.content);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Edit ${note.verse.reference}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 7,
          decoration: const InputDecoration(hintText: 'Write your reflection…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isNotEmpty) {
                await ref
                    .read(bibleRepositoryProvider)
                    .saveNote(note.verse.id, content, id: note.id);
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted) setState(() {});
  }
}

class BibleQuizScreen extends ConsumerStatefulWidget {
  const BibleQuizScreen({super.key});

  @override
  ConsumerState<BibleQuizScreen> createState() => _BibleQuizScreenState();
}

class _BibleQuizScreenState extends ConsumerState<BibleQuizScreen> {
  QuizDifficulty? difficulty;
  List<BibleQuizQuestion> questions = const [];
  int current = 0;
  int score = 0;
  String? selected;
  bool loading = false;
  String? error;

  Future<void> _start(QuizDifficulty value) async {
    setState(() {
      difficulty = value;
      loading = true;
      error = null;
      current = 0;
      score = 0;
      selected = null;
    });
    try {
      final versionId = ref.read(settingsProvider).defaultVersionId;
      final verses = await ref
          .read(bibleRepositoryProvider)
          .randomVerses(versionId);
      final generated = BibleQuizFactory().create(verses, value);
      if (!mounted) return;
      setState(() {
        questions = generated;
        loading = false;
        if (generated.isEmpty) {
          error = 'Not enough Scripture data was available for this quiz.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'The offline quiz could not be prepared. Please try again.';
      });
    }
  }

  void _answer(String value) {
    if (selected != null) return;
    setState(() {
      selected = value;
      if (value == questions[current].answer) score++;
    });
  }

  void _next() {
    if (current + 1 == questions.length) {
      setState(() => current = questions.length);
    } else {
      setState(() {
        current++;
        selected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageFrame(
      title: 'Offline Bible Quiz',
      actions: [
        if (difficulty != null)
          IconButton(
            tooltip: 'Choose difficulty',
            onPressed: () => setState(() {
              difficulty = null;
              questions = const [];
              selected = null;
            }),
            icon: const Icon(Icons.tune),
          ),
      ],
      child: _content(context),
    ),
  );

  Widget _content(BuildContext context) {
    if (difficulty == null) return _difficultyPicker(context);
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return _Empty(
        icon: Icons.error_outline,
        title: 'Quiz unavailable',
        message: error!,
      );
    }
    if (current >= questions.length) return _results(context);
    final question = questions[current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Question ${current + 1} of ${questions.length}'),
            Text('Score $score', style: const TextStyle(color: AppTheme.gold)),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: (current + 1) / questions.length),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '“${question.passage}”',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QuizOption(
              text: option,
              selected: selected == option,
              correct: selected == null ? null : option == question.answer,
              onTap: () => _answer(option),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            selected == question.answer
                ? 'Correct!'
                : 'The correct answer is ${question.answer}.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected == question.answer
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.reference,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('quiz-next'),
            onPressed: _next,
            child: Text(
              current + 1 == questions.length ? 'See results' : 'Next question',
            ),
          ),
        ],
      ],
    );
  }

  Widget _difficultyPicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Choose your challenge',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Every round is generated randomly from your default offline Bible version.',
      ),
      const SizedBox(height: 24),
      _DifficultyCard(
        title: 'Easy',
        subtitle: 'Identify the Bible book from a verse.',
        icon: Icons.light_mode_outlined,
        onTap: () => _start(QuizDifficulty.easy),
      ),
      _DifficultyCard(
        title: 'Medium',
        subtitle: 'Choose the exact chapter and verse reference.',
        icon: Icons.auto_awesome_outlined,
        onTap: () => _start(QuizDifficulty.medium),
      ),
      _DifficultyCard(
        title: 'Hard',
        subtitle: 'Complete a missing word from Scripture.',
        icon: Icons.local_fire_department_outlined,
        onTap: () => _start(QuizDifficulty.hard),
      ),
    ],
  );

  Widget _results(BuildContext context) {
    final percentage = questions.isEmpty
        ? 0
        : (score * 100 ~/ questions.length);
    return GlassCard(
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 72,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz complete',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '$score / ${questions.length}',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text('$percentage% correct'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _start(difficulty!),
            icon: const Icon(Icons.shuffle),
            label: const Text('Play another random quiz'),
          ),
          TextButton(
            onPressed: () => setState(() {
              difficulty = null;
              questions = const [];
            }),
            child: const Text('Change difficulty'),
          ),
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 36, color: AppTheme.gold),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.text,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = correct == true
        ? Colors.green
        : selected && correct == false
        ? Theme.of(context).colorScheme.error
        : null;
    return Semantics(
      button: true,
      selected: selected,
      label: text,
      child: OutlinedButton(
        onPressed: correct == null ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          alignment: Alignment.centerLeft,
          foregroundColor: color,
          side: color == null ? null : BorderSide(color: color, width: 2),
        ),
        child: Text(text),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider),
        notifier = ref.read(settingsProvider.notifier);
    return PageFrame(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Section('Appearance'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {s.themeMode},
            onSelectionChanged: (v) =>
                notifier.update(s.copyWith(themeMode: v.first)),
          ),
          const _Section('Reading'),
          ListTile(
            title: Text('Font size · ${s.fontSize.round()}'),
            subtitle: Slider(
              value: s.fontSize,
              min: 14,
              max: 32,
              onChanged: (v) => notifier.update(s.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: Text('Line spacing · ${s.lineHeight.toStringAsFixed(1)}'),
            subtitle: Slider(
              value: s.lineHeight,
              min: 1.2,
              max: 2.1,
              onChanged: (v) => notifier.update(s.copyWith(lineHeight: v)),
            ),
          ),
          SwitchListTile(
            title: const Text('Serif reading font'),
            value: s.serif,
            onChanged: (v) => notifier.update(s.copyWith(serif: v)),
          ),
          SwitchListTile(
            title: const Text('Show verse numbers'),
            value: s.showVerseNumbers,
            onChanged: (v) => notifier.update(s.copyWith(showVerseNumbers: v)),
          ),
          SwitchListTile(
            title: const Text('Full-screen reading'),
            subtitle: const Text('Hide system bars while reading Scripture'),
            value: s.fullScreen,
            onChanged: (v) => notifier.update(s.copyWith(fullScreen: v)),
          ),
          const _Section('Bible'),
          FutureBuilder(
            future: ref.read(bibleRepositoryProvider).versions(),
            builder: (context, snapshot) => DropdownButtonFormField<int>(
              initialValue:
                  snapshot.data?.any(
                        (version) => version.id == s.defaultVersionId,
                      ) ==
                      true
                  ? s.defaultVersionId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Default Bible version',
              ),
              items: [
                for (final version in snapshot.data ?? <BibleVersion>[])
                  DropdownMenuItem(
                    value: version.id,
                    child: Text('${version.name} (${version.abbreviation})'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  notifier.update(s.copyWith(defaultVersionId: value));
                }
              },
            ),
          ),
          const _Section('Data'),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Clear reading history'),
            onTap: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Clear history?'),
                content: const Text(
                  'Bookmarks, highlights, and notes will remain.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      ref.read(bibleRepositoryProvider).clearHistory();
                      Navigator.pop(c);
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
          const _Section('About'),
          const ListTile(
            leading: Icon(Icons.auto_stories),
            title: Text('Veralume'),
            subtitle: Text(
              'Truth · Light · Scripture\n'
              'Version 1.4.2\n'
              'ArkByte Technologies',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Developers'),
            subtitle: Text(
              'EARL GULTIA\n'
              'KRISTELLE JOYCE QUIJANO\n'
              'MILES GULTIA\n'
              'ARVEY OCIONES',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.offline_bolt),
            title: Text('Offline by design'),
            subtitle: Text(
              'Bible reading, search, and personal data remain on this device.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Bundled translations'),
            subtitle: Text(
              'ASV, KJV, Tagalog Ang Biblia, Open Ang Salita ng Diyos, Open Ang Pulong sa Dios, Balaan nga Bibliya, MBB-CEB, and CebBugna. See README for licensing notes.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.gold,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        Icon(icon, size: 64, color: AppTheme.gold),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
