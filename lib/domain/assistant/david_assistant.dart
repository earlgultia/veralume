import '../../data/models/bible_models.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/journey_repository.dart';

class DavidReply {
  const DavidReply(this.message, {this.verses = const []});
  final String message;
  final List<BibleVerse> verses;
}

typedef _GroundedAnswer = ({
  List<String> triggers,
  String message,
  List<String> references,
});

class DavidAssistant {
  DavidAssistant(this.repository, {this.journeyRepository});
  final BibleRepository repository;
  final JourneyRepository? journeyRepository;
  final Map<String, DavidReply> _cache = {};

  static final _reference = RegExp(
    r'\b((?:[1-3]\s*)?[a-z]+(?:\s+[a-z]+)?)\s+(\d{1,3})(?::(\d{1,3})(?:\s*[-–]\s*(\d{1,3}))?)?\b',
    caseSensitive: false,
  );

  static const _answers = <_GroundedAnswer>[
    (
      triggers: [
        'wolf in sheep',
        'wolves in sheep',
        'sheep clothing',
        "sheep's clothing",
        'sheeps clothing',
        'false prophet',
      ],
      message:
          'Jesus said to be careful of false teachers. They may look good, but their actions show who they really are.',
      references: ['Matthew 7:15-20'],
    ),
    (
      triggers: ['goliath'],
      message:
          'David was a young shepherd. He trusted God and defeated Goliath with a sling and a stone. David said the victory came from God.',
      references: ['1 Samuel 17:45-50'],
    ),
    (
      triggers: ['david and saul', 'king saul'],
      message:
          'David served King Saul. Later, Saul tried to kill him. David had chances to kill Saul, but he did not. He let God judge Saul.',
      references: ['1 Samuel 18:10-12', '1 Samuel 24:6-7'],
    ),
    (
      triggers: ['bathsheba', 'uriah'],
      message:
          'David did a very wrong thing with Bathsheba. He also planned the death of her husband, Uriah. Nathan spoke to David about his sin. David admitted it, but his actions still caused great pain.',
      references: ['2 Samuel 11:2-5', '2 Samuel 12:7-13'],
    ),
    (
      triggers: ['david king', 'king david', 'david reign', 'anointed david'],
      message:
          'God chose David when he was young. Later, David became king of Israel. He was king for forty years and made Jerusalem his main city.',
      references: ['1 Samuel 16:12-13', '2 Samuel 5:3-5'],
    ),
    (
      triggers: ['psalm', 'psalms'],
      message:
          'The Psalms are songs and prayers. They speak about joy, sadness, fear, saying sorry, and trusting God. David wrote many of them.',
      references: ['Psalm 23:1-4', 'Psalm 51:10-12'],
    ),
    (
      triggers: ['who is jesus', 'tell me about jesus', 'jesus christ'],
      message:
          'The New Testament says Jesus is the Son of God and the promised Savior. He taught people about God. He died on the cross and rose from the dead.',
      references: ['Matthew 1:21', 'John 3:16', '1 Corinthians 15:3-4'],
    ),
    (
      triggers: ['creation', 'created the world', 'beginning of the world'],
      message:
          'Genesis says God made heaven and earth. He made plants, animals, and people. He made people in his image.',
      references: ['Genesis 1:1-3', 'Genesis 1:26-27'],
    ),
    (
      triggers: ['noah', 'the flood', 'ark'],
      message:
          'Noah trusted God and built the ark. God kept Noah and his family safe during the flood. Afterward, the rainbow became a sign of God’s promise.',
      references: ['Genesis 6:13-14', 'Genesis 9:12-13'],
    ),
    (
      triggers: ['abraham'],
      message:
          'God told Abraham to leave his country. God promised to make a great nation from his family. Abraham trusted God’s promise.',
      references: ['Genesis 12:1-3', 'Genesis 15:5-6'],
    ),
    (
      triggers: ['moses', 'ten commandments', 'exodus from egypt'],
      message:
          'God called Moses to lead Israel out of slavery in Egypt. God also gave the Ten Commandments through Moses.',
      references: ['Exodus 3:9-10', 'Exodus 20:1-3'],
    ),
    (
      triggers: ['daniel', 'lions den', 'lion’s den', "lion's den"],
      message:
          'Daniel kept praying to God, even when the law said he could not. He was thrown into a den of lions, but God kept him safe.',
      references: ['Daniel 6:10', 'Daniel 6:21-23'],
    ),
    (
      triggers: ['jonah', 'great fish', 'big fish'],
      message:
          'Jonah ran away from God’s command. A great fish swallowed him. Jonah prayed, and God gave him another chance. The story shows that God is kind to people who turn back to him.',
      references: ['Jonah 1:17', 'Jonah 3:1-3', 'Jonah 4:2'],
    ),
    (
      triggers: [
        'apostle paul',
        'who is paul',
        'tell me about paul',
        'saul of tarsus',
      ],
      message:
          'Paul first hurt Christians. Then he met Jesus and changed his life. He traveled to many places to tell people the good news about Jesus.',
      references: ['Acts 9:3-6', 'Acts 9:15'],
    ),
    (
      triggers: ['born', 'birth of jesus', 'nativity'],
      message:
          'Jesus was born in Bethlehem. Angels told the shepherds that the Savior had been born.',
      references: ['Luke 2:6-11'],
    ),
    (
      triggers: [
        'crucifixion',
        'cross of jesus',
        'jesus die',
        'death of jesus',
      ],
      message:
          'Jesus died on a cross. The New Testament says he died so our sins can be forgiven and we can come close to God.',
      references: ['Luke 23:33-34', 'Romans 5:8'],
    ),
    (
      triggers: ['resurrection', 'rose again', 'empty tomb'],
      message:
          'The Gospels say Jesus rose from the dead. His new life gives Christians hope.',
      references: ['Matthew 28:5-6', '1 Corinthians 15:20-22'],
    ),
    (
      triggers: ['holy spirit'],
      message:
          'The Holy Spirit is God with his people. He teaches, guides, and helps believers live in a good way.',
      references: ['John 14:26', 'Acts 1:8', 'Galatians 5:22-23'],
    ),
    (
      triggers: ['saved', 'salvation', 'how to be saved'],
      message:
          'The New Testament says being saved is a gift from God. We receive it by trusting Jesus. We cannot earn it by doing good things.',
      references: ['John 3:16', 'Ephesians 2:8-10', 'Romans 10:9-10'],
    ),
    (
      triggers: ['forgive', 'forgiveness', 'forgiven'],
      message:
          'God is kind and ready to forgive. The Bible tells us to admit our sins, receive God’s forgiveness, and forgive other people.',
      references: ['1 John 1:9', 'Ephesians 4:32'],
    ),
    (
      triggers: ['pray', 'prayer', 'how do i pray'],
      message:
          'Prayer can be simple and honest. You can thank God, ask for help, ask for forgiveness, and pray for other people.',
      references: ['Matthew 6:6', 'Matthew 6:9-13', 'Philippians 4:6-7'],
    ),
    (
      triggers: [
        'anxious',
        'anxiety',
        'worried',
        'worry',
        'panic',
        'stressed',
        'stress',
      ],
      message:
          'I’m sorry you feel worried. Tell God what is troubling you. Take one day at a time. It may also help to talk with someone you trust.',
      references: ['Philippians 4:6-7', 'Matthew 6:34', '1 Peter 5:7'],
    ),
    (
      triggers: [
        'sad',
        'depressed',
        'brokenhearted',
        'grief',
        'grieving',
        'empty inside',
        'feel empty',
      ],
      message:
          'I’m sorry you feel this pain. The Bible says God is close to people with broken hearts. You do not have to face this alone. Please tell someone you trust. If the sadness is very strong or lasts a long time, please talk with a counselor or doctor.',
      references: ['Psalm 34:18', 'Matthew 5:4', 'Revelation 21:4'],
    ),
    (
      triggers: [
        'lost someone',
        'someone died',
        'death in family',
        'mourning',
        'bereaved',
        'miss them',
      ],
      message:
          'I’m very sorry for your loss. It is okay to cry and feel sad. Even Jesus cried. Please let a trusted person stay close to you. The Bible gives hope that death is not the end.',
      references: ['John 11:33-36', 'Psalm 147:3', '1 Thessalonians 4:13-14'],
    ),
    (
      triggers: ['afraid', 'fear', 'scared'],
      message:
          'It is normal to feel afraid. The Bible says God is with you and will help you. Tell him what you fear.',
      references: ['Psalm 56:3-4', 'Isaiah 41:10', '2 Timothy 1:7'],
    ),
    (
      triggers: ['lonely', 'alone', 'loneliness'],
      message:
          'I’m sorry you feel alone. The Bible says God will not leave you. Please reach out to a safe person who can talk or stay with you.',
      references: ['Psalm 27:10', 'Hebrews 13:5-6'],
    ),
    (
      triggers: [
        'angry',
        'anger',
        'furious',
        'mad at',
        'rage',
        'frustrated',
        'frustration',
      ],
      message:
          'Strong anger can make us act too fast. Stop and take time to calm down. Tell God how you feel. Speak only when you can be honest and kind.',
      references: ['Ephesians 4:26-27', 'James 1:19-20', 'Proverbs 15:1'],
    ),
    (
      triggers: ['guilty', 'guilt', 'ashamed', 'shame', 'regret', 'i sinned'],
      message:
          'Guilt and shame can feel very heavy. You can tell God the truth about what happened. God can forgive you and help you change. If you hurt someone, ask a wise person how to make things right in a safe way.',
      references: ['Psalm 32:3-5', '1 John 1:9', 'Romans 8:1'],
    ),
    (
      triggers: [
        'discouraged',
        'discouragement',
        'want to give up',
        'failure',
        'failed',
      ],
      message:
          'I’m sorry you feel like giving up. This hard time is not your whole story. God can help you when you feel weak. Choose one small next step. Ask someone you trust to encourage you.',
      references: ['Galatians 6:9', '2 Corinthians 4:8-9', 'Isaiah 40:29-31'],
    ),
    (
      triggers: [
        'tired',
        'exhausted',
        'burned out',
        'burnt out',
        'overwhelmed',
        'weary',
      ],
      message:
          'You sound very tired. It is okay to rest. Jesus also told his friends to rest. Do one small thing at a time. Breathe, say a short prayer, and let someone help you.',
      references: ['Matthew 11:28-30', 'Mark 6:31', 'Psalm 23:1-3'],
    ),
    (
      triggers: [
        'confused',
        'confusion',
        'do not know what to do',
        "don't know what to do",
        'uncertain',
      ],
      message:
          'It is hard when you do not know what to do. You do not need to decide too fast. Ask God for wisdom. Read the Bible, talk with a wise person, and take the next good step you can see.',
      references: ['James 1:5', 'Proverbs 11:14', 'Psalm 119:105'],
    ),
    (
      triggers: ['jealous', 'jealousy', 'envy', 'envious', 'comparing myself'],
      message:
          'Comparing yourself with others can take away your peace. Tell God how you feel. Thank him for the good things in your life. Another person’s success does not make you less important.',
      references: [
        'Proverbs 14:30',
        'Galatians 5:25-26',
        '1 Thessalonians 5:18',
      ],
    ),
    (
      triggers: [
        'heartbroken',
        'breakup',
        'relationship ended',
        'rejected',
        'betrayed',
      ],
      message:
          'I’m sorry. A broken relationship can hurt very much. It is okay to feel sad about what you lost. Another person’s choice does not decide your value. Stay close to safe people while you heal.',
      references: ['Psalm 34:18', 'Isaiah 43:1-2', 'Romans 8:38-39'],
    ),
    (
      triggers: [
        'sick',
        'illness',
        'in pain',
        'hurting physically',
        'hospital',
      ],
      message:
          'I’m sorry you are sick or in pain. You can pray and also get medical care. Please talk with a doctor when needed. Tell people you trust how they can help you.',
      references: ['Psalm 41:3', 'Psalm 130:1-2', 'James 5:14-16'],
    ),
    (
      triggers: ['happy', 'joyful', 'excited', 'good news', 'blessed today'],
      message:
          'I’m happy to hear that! Thank God for this good moment. Share the good news with someone. You can also use your joy to help another person.',
      references: ['Psalm 118:24', 'Philippians 4:4', 'James 1:17'],
    ),
    (
      triggers: ['thankful', 'grateful', 'gratitude', 'give thanks'],
      message:
          'Being thankful helps us see God’s goodness. Think of three good things from today. Thank God for each one.',
      references: ['Psalm 100:4-5', '1 Thessalonians 5:16-18'],
    ),
    (
      triggers: ['temptation', 'tempted'],
      message:
          'Everyone faces temptation. Pray and stay alert. Move away from the wrong choice when you can. God can help you choose a better way.',
      references: ['1 Corinthians 10:13', 'Matthew 26:41'],
    ),
    (
      triggers: ['wisdom', 'decision', 'guidance'],
      message:
          'Ask God for wisdom. Trust him, read his Word, and do not make a choice too quickly.',
      references: ['James 1:5', 'Proverbs 3:5-6'],
    ),
    (
      triggers: ['hope', 'hopeless'],
      message:
          'Bible hope means trusting God, even in hard times. God can give you strength, comfort, and hope for the future.',
      references: ['Romans 5:3-5', 'Romans 15:13'],
    ),
    (
      triggers: ['love'],
      message:
          'The Bible says love is patient and kind. Love tells the truth and cares for other people, even when it is hard.',
      references: ['1 Corinthians 13:4-7', '1 John 4:9-11'],
    ),
  ];

  Future<DavidReply> ask(String question, int versionId) async {
    final lower = question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (_isLocalContextQuestion(lower) && journeyRepository != null) {
      return _answerFromLocalContext(lower, versionId);
    }
    final cacheKey = '$versionId:${question.trim().toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    final reply = await _answer(question, versionId);
    if (_cache.length >= 50) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = reply;
    return reply;
  }

  bool _isLocalContextQuestion(String value) =>
      value.contains('what did i read') ||
      value.contains('what have i read') ||
      value.contains('reading history') ||
      value.contains('recently read') ||
      value.contains('my journey') ||
      value.contains('my bookmark') ||
      value.contains('my highlight') ||
      value.contains('my note') ||
      value.contains('did i save') ||
      value.contains('i saved') ||
      value.contains('saved about') ||
      value.contains('saved verse') ||
      value.contains('saved passage');

  Future<DavidReply> _answerFromLocalContext(
    String query,
    int versionId,
  ) async {
    final journey = journeyRepository!;
    if (query.contains('what did i read') ||
        query.contains('what have i read') ||
        query.contains('reading history') ||
        query.contains('recently read') ||
        query.contains('my journey')) {
      if (query.contains('yesterday') || query.contains('today')) {
        final now = DateTime.now();
        final date = query.contains('yesterday')
            ? now.subtract(const Duration(days: 1))
            : now;
        final history = await journey.historyForLocalDate(date, versionId);
        if (history.isEmpty) {
          return DavidReply(
            query.contains('yesterday')
                ? 'I don’t see a meaningful Scripture reading session from yesterday on this device.'
                : 'I don’t see a meaningful Scripture reading session from today yet.',
          );
        }
        final label = query.contains('yesterday') ? 'Yesterday' : 'Today';
        return DavidReply('$label you read ${_summarizeHistory(history)}.');
      }
      final context = await journey.userReadingContext(versionId);
      if (context.recentlyRead.isEmpty) {
        return const DavidReply(
          'Your local Journey does not have a meaningful reading session yet. Open a passage and spend a little time reading it.',
        );
      }
      return DavidReply(
        'Recently you read ${_summarizeHistory(context.recentlyRead)}.',
      );
    }

    final terms = _topicWords(query).where(
      (word) => !{
        'bookmark',
        'bookmarks',
        'did',
        'highlight',
        'highlights',
        'note',
        'notes',
        'save',
        'saved',
        'passage',
        'passages',
      }.contains(word),
    );
    final matches = <LocalSavedPassage>[];
    final seen = <String>{};
    for (final term in terms.take(4)) {
      for (final item in await journey.searchSaved(term, versionId)) {
        final identity = '${item.kind}:${item.verse.id}';
        if (seen.add(identity)) matches.add(item);
      }
    }
    if (matches.isEmpty && terms.isEmpty) {
      matches.addAll(await journey.searchSaved('', versionId));
    }
    final wantedKind = query.contains('bookmark')
        ? 'bookmark'
        : query.contains('highlight')
        ? 'highlight'
        : query.contains('note')
        ? 'note'
        : null;
    final filtered = matches
        .where((item) => wantedKind == null || item.kind == wantedKind)
        .take(8)
        .toList();
    if (filtered.isEmpty) {
      return const DavidReply(
        'I couldn’t find a matching bookmark, highlight, or note stored on this device. I won’t invent a saved passage.',
      );
    }
    final kinds = filtered.map((item) => item.kind).toSet().join(', ');
    return DavidReply(
      'I found these in your local $kinds collection. Your personal reading data stayed on this device.',
      verses: filtered.map((item) => item.verse).toList(),
    );
  }

  String _summarizeHistory(List<LocalReadingHistory> history) {
    final grouped = <String, List<int>>{};
    for (final item in history) {
      grouped.putIfAbsent(item.bookName, () => []).add(item.chapter);
    }
    return grouped.entries
        .map((entry) {
          final chapters = entry.value.toSet().toList()..sort();
          if (chapters.length == 1) return '${entry.key} ${chapters.first}';
          final consecutive = List.generate(
            chapters.length,
            (index) => chapters.first + index,
          );
          return chapters.toString() == consecutive.toString()
              ? '${entry.key} ${chapters.first}–${chapters.last}'
              : '${entry.key} ${chapters.join(', ')}';
        })
        .join('; ');
  }

  Future<DavidReply> _answer(String question, int versionId) async {
    final query = question.trim();
    if (query.isEmpty) {
      return const DavidReply('What would you like to explore in the Bible?');
    }
    final lower = query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = lower
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .split(' ')
        .toSet();

    if (_containsAny(lower, [
      'suicide',
      'kill myself',
      'end my life',
      'self harm',
    ])) {
      return DavidReply(
        'I’m very sorry you are in so much pain. Please call emergency services or a crisis line now. Tell a trusted person and ask them to stay with you. Do not stay alone if you may hurt yourself. I can share Bible verses, but you need help from a person right now.',
        verses: await _loadReferences([
          'Psalm 34:18',
          'Romans 8:38-39',
        ], versionId),
      );
    }
    if (words.any({'hi', 'hello', 'hey', 'greetings'}.contains)) {
      return const DavidReply(
        'Hello! I’m glad you are here. Ask me about a Bible person or story. You can also ask for verses about your life, or type a verse like John 3:16.',
      );
    }
    if (_containsAny(lower, [
      'good morning',
      'good afternoon',
      'good evening',
    ])) {
      return const DavidReply(
        'Hello! I hope you are having a good day. What would you like to find in the Bible?',
      );
    }
    if (_containsAny(lower, ['how are you', 'how are u'])) {
      return const DavidReply(
        'I’m ready to help you with the Bible. What are you thinking or feeling today?',
      );
    }
    if (words.any({'thanks', 'thank', 'thankyou'}.contains)) {
      return const DavidReply(
        'You’re welcome! You can ask me another Bible question at any time.',
      );
    }
    if (words.any({'bye', 'goodbye'}.contains) || lower.contains('see you')) {
      return const DavidReply(
        'Goodbye for now. I hope God’s Word gives you wisdom, courage, and peace.',
      );
    }
    if (_containsAny(lower, [
      'what can you do',
      'help me',
      'how do i use',
      'help',
    ])) {
      return const DavidReply(
        'I can find Bible verses, explain Bible people and stories, and share verses for how you feel. Try: “Romans 8:28,” “Who was Moses?”, “verses about worry,” or “tell me about David and Saul.”',
      );
    }

    final reference = _reference.firstMatch(query);
    if (reference != null) {
      final verses = await _lookupReference(reference, versionId);
      if (verses.isNotEmpty) {
        return DavidReply('Here is the passage you asked for.', verses: verses);
      }
    }

    if (_isAboutDavid(lower)) {
      final specific = await _groundedAnswer(lower, versionId, davidOnly: true);
      if (specific != null) return specific;
      return DavidReply(
        'I’m David, an offline Bible helper. My name comes from David, the shepherd and king in the Bible. I am not the real Bible person. David was brave and trusted God, but he also made serious mistakes and needed God’s mercy.',
        verses: await _loadReferences([
          '1 Samuel 16:12-13',
          'Acts 13:22',
        ], versionId),
      );
    }

    final grounded = await _groundedAnswer(lower, versionId);
    if (grounded != null) return grounded;

    final keywords = _topicWords(lower);
    final results = await _searchKeywords(keywords, versionId);
    if (results.isNotEmpty) {
      return DavidReply(
        'I found these verses in your chosen Bible version. Please read the full chapter to understand them better.',
        verses: results,
      );
    }
    return const DavidReply(
      'I did not understand that. Please use a short Bible topic, a person, a story, or a verse like Romans 8:28. You can also ask, “What can you do?”',
    );
  }

  Future<DavidReply?> _groundedAnswer(
    String query,
    int versionId, {
    bool davidOnly = false,
  }) async {
    for (final answer in _answers) {
      final isDavidAnswer = answer.triggers.any(
        (trigger) =>
            trigger.contains('david') ||
            {
              'goliath',
              'bathsheba',
              'uriah',
              'psalm',
              'psalms',
            }.contains(trigger),
      );
      if ((!davidOnly || isDavidAnswer) &&
          answer.triggers.any(query.contains)) {
        return DavidReply(
          answer.message,
          verses: await _loadReferences(answer.references, versionId),
        );
      }
    }
    return null;
  }

  bool _containsAny(String value, Iterable<String> options) =>
      options.any(value.contains);

  bool _isAboutDavid(String value) =>
      value.contains('david') ||
      value.contains('yourself') ||
      value == 'who are you' ||
      value.contains('about you');

  List<String> _topicWords(String value) {
    const filler = {
      'a',
      'about',
      'and',
      'are',
      'bible',
      'can',
      'could',
      'do',
      'does',
      'find',
      'for',
      'give',
      'help',
      'i',
      'in',
      'is',
      'me',
      'my',
      'of',
      'on',
      'please',
      'say',
      'scripture',
      'show',
      'tell',
      'that',
      'the',
      'to',
      'verse',
      'verses',
      'what',
      'when',
      'where',
      'which',
      'who',
      'why',
      'with',
      'you',
    };
    return value
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !filler.contains(word))
        .toSet()
        .take(5)
        .toList();
  }

  Future<List<BibleVerse>> _searchKeywords(
    List<String> words,
    int versionId,
  ) async {
    if (words.isEmpty) return [];
    return repository.searchAnyTerms(
      words.reversed,
      versionId: versionId,
      limit: 6,
    );
  }

  Future<List<BibleVerse>> _loadReferences(
    List<String> references,
    int versionId,
  ) async {
    final verses = <BibleVerse>[];
    for (final value in references) {
      verses.addAll(
        await _lookupReference(_reference.firstMatch(value)!, versionId),
      );
    }
    return verses;
  }

  Future<List<BibleVerse>> _lookupReference(
    RegExpMatch match,
    int versionId,
  ) async {
    final bookWords = match.group(1)!.trim().split(RegExp(r'\s+'));
    for (var start = 0; start < bookWords.length; start++) {
      final result = await repository.passageByReference(
        bookWords.sublist(start).join(' '),
        int.parse(match.group(2)!),
        startVerse: int.tryParse(match.group(3) ?? ''),
        endVerse: int.tryParse(match.group(4) ?? ''),
        versionId: versionId,
      );
      if (result.isNotEmpty) return result;
    }
    return [];
  }
}
