import '../../data/models/bible_models.dart';
import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/journey_repository.dart';

class SamSamReply {
  const SamSamReply(this.message, {this.verses = const []});
  final String message;
  final List<BibleVerse> verses;
}

typedef _GroundedAnswer = ({
  List<String> triggers,
  String message,
  List<String> references,
});

class SamSamAssistant {
  SamSamAssistant(this.repository, {this.journeyRepository});
  final BibleRepository repository;
  final JourneyRepository? journeyRepository;
  final Map<String, SamSamReply> _cache = {};

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

  Future<SamSamReply> ask(
    String question,
    int versionId, {
    String language = 'English',
    List<String> conversation = const [],
  }) async {
    final responseLanguage = language == _english
        ? _detectLanguage(question, conversation)
        : language;
    final rawLower = question
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final normalized = _normalizeQuestion(question);
    final lower = normalized.replaceAll(RegExp(r'\s+'), ' ');
    final earlierQuestions = conversation
        .where((message) => message.trim().isNotEmpty)
        .toList();
    final previousQuestion = earlierQuestions.isEmpty
        ? null
        : earlierQuestions.last;
    final isFollowUp = previousQuestion != null && _isFollowUp(rawLower);
    final interpretedQuestion = isFollowUp
        ? '${_normalizeQuestion(previousQuestion)} $lower'
        : lower;
    if (_isLocalContextQuestion(lower) && journeyRepository != null) {
      return _answerFromLocalContext(lower, versionId, responseLanguage);
    }
    final cacheKey =
        '$versionId:$responseLanguage:${interpretedQuestion.toLowerCase()}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    final reply = await _answer(
      interpretedQuestion,
      versionId,
      language: responseLanguage,
      followUp: isFollowUp,
    );
    if (_cache.length >= 50) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = reply;
    return reply;
  }

  static const _languageAliases = <String, String>{
    'diyos': 'god',
    'panginoon': 'god',
    'hesus': 'jesus',
    'kristo': 'christ',
    'dasal': 'prayer',
    'magdasal': 'pray',
    'panalangin': 'prayer',
    'pag ibig': 'love',
    'pag-ibig': 'love',
    'mahal': 'love',
    'pag asa': 'hope',
    'pag-asa': 'hope',
    'pag asa sa diyos': 'hope god',
    'takot': 'anxiety',
    'natatakot': 'anxiety',
    'kaba': 'anxiety',
    'kinakabahan': 'anxiety',
    'nag aalala': 'worry',
    'nag-aalala': 'worry',
    'malungkot': 'sad',
    'lungkot': 'sad',
    'pagod': 'tired',
    'patawad': 'forgiveness',
    'magpatawad': 'forgive',
    'kasalanan': 'sin',
    'kapatawaran': 'forgiveness',
    'sino si hesus': 'who is jesus',
    'sino si moses': 'moses',
    'sino si noah': 'noah',
    'ginoo': 'god',
    'gugma': 'love',
    'higugma': 'love',
    'paglaum': 'hope',
    'pag-ampo': 'prayer',
    'ampo': 'prayer',
    'mag ampo': 'pray',
    'mag-ampo': 'pray',
    'kahadlok': 'anxiety',
    'nahadlok': 'anxiety',
    'kabalaka': 'anxiety',
    'nabalaka': 'anxiety',
    'naguol': 'sad',
    'guol': 'sad',
    'kapoy': 'tired',
    'pasaylo': 'forgiveness',
    'pasayloa': 'forgive',
    'sala': 'sin',
    'kinsa si hesus': 'who is jesus',
    'kinsa si moses': 'moses',
    'kinsa si noah': 'noah',
    'unsa ang gugma': 'love',
    'unsaon pag ampo': 'how do i pray',
    'unsaon pag-ampo': 'how do i pray',
    'unsa akong gibasa gahapon': 'what did i read yesterday',
    'unsa akong gibasa karon': 'what did i read today',
    'ano binasa ko kahapon': 'what did i read yesterday',
    'ano binasa ko ngayon': 'what did i read today',
    'juan': 'john',
    'mateo': 'matthew',
    'marcos': 'mark',
    'lucas': 'luke',
    'salmo': 'psalm',
    'mga awit': 'psalms',
    'mga taga roma': 'romans',
    'mga taga ro-ma': 'romans',
    '1 corinto': '1 corinthians',
    '2 corinto': '2 corinthians',
    'efeso': 'ephesians',
    'filipos': 'philippians',
    'genesis': 'genesis',
  };

  static const _english = 'English';

  String _detectLanguage(String question, List<String> conversation) {
    final candidates = [question, ...conversation.reversed];
    const tagalog = [
      'kinakabahan',
      'nag-aalala',
      'nag aalala',
      'malungkot',
      'pagod',
      'patawad',
      'kasalanan',
      'panalangin',
      'magdasal',
      'diyos',
      'panginoon',
      'hesus',
      'bakit',
      'paano',
      'kahapon',
      'ngayon',
      'magpakamatay',
      'natatakot',
      'nalulungkot',
    ];
    const bisaya = [
      'nabalaka',
      'kabalaka',
      'naguol',
      'kapoy',
      'pasaylo',
      'pag-ampo',
      'mag-ampo',
      'gugma',
      'paglaum',
      'ginoo',
      'kinsa',
      'unsa',
      'ngano',
      'gahapon',
      'magpakamatay',
      'mabuhi',
      'nahadlok',
    ];
    for (final candidate in candidates) {
      final value = candidate.toLowerCase();
      if (tagalog.any(value.contains)) return 'Tagalog';
      if (bisaya.any(value.contains)) return 'Bisaya';
    }
    return _english;
  }

  String _normalizeQuestion(String value) {
    var normalized = value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final alias
        in _languageAliases.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length))) {
      normalized = normalized.replaceAll(
        RegExp(r'(^|[^a-z])' + RegExp.escape(alias) + r'(?=[^a-z]|$)'),
        ' ${_languageAliases[alias]} ',
      );
    }
    return _correctTopicTypos(
      normalized,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _correctTopicTypos(String value) {
    final vocabulary = {
      ..._answers
          .expand((answer) => answer.triggers)
          .expand((trigger) => trigger.split(RegExp(r'[^a-z]+'))),
      'about',
      'jesus',
      'moses',
      'noah',
      'hope',
      'love',
      'pray',
      'fear',
      'hello',
      'thanks',
      'thank',
      'goodbye',
      'greetings',
      'anxious',
      'worried',
      'forgiveness',
      'scripture',
    }.where((word) => word.length >= 4);
    return value.replaceAllMapped(RegExp(r'[a-z]+'), (match) {
      final part = match.group(0)!;
      if (part.length < 4) return part;
      var nearest = part;
      final maxDistance = part.length >= 6 ? 2 : 1;
      var bestDistance = maxDistance + 1;
      var ambiguous = false;
      for (final candidate in vocabulary) {
        if ((candidate.length - part.length).abs() > maxDistance) continue;
        final distance = _editDistance(part, candidate, maxDistance);
        if (distance > maxDistance) continue;
        if (distance < bestDistance) {
          nearest = candidate;
          bestDistance = distance;
          ambiguous = false;
        } else if (distance == bestDistance && candidate != nearest) {
          ambiguous = true;
        }
      }
      return bestDistance > maxDistance || ambiguous ? part : nearest;
    });
  }

  int _editDistance(String left, String right, int cutoff) {
    if ((left.length - right.length).abs() > cutoff) return cutoff + 1;
    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var i = 1; i <= left.length; i++) {
      final current = List<int>.filled(right.length + 1, cutoff + 1);
      current[0] = i;
      var rowMinimum = current[0];
      for (var j = 1; j <= right.length; j++) {
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + (left[i - 1] == right[j - 1] ? 0 : 1),
        ].reduce((a, b) => a < b ? a : b);
        if (current[j] < rowMinimum) rowMinimum = current[j];
      }
      if (rowMinimum > cutoff) return cutoff + 1;
      previous = current;
    }
    return previous.last;
  }

  bool _isFollowUp(String value) => {
    'why',
    'how',
    'tell me more',
    'more',
    'what else',
    'and',
    'why is that',
    'explain more',
    'what does it mean',
    'what does that mean',
    'explain it',
    'explain that',
    'explain it simply',
    'in simple words',
    'say more',
    'unsa pa',
    'ngano',
    'nganong ingon ana',
    'unsa pasabot',
    'bakit',
    'paano',
    'dagdag pa',
    'ano pa',
  }.contains(value.replaceAll(RegExp(r'[?!.,]+$'), '').trim());

  String _followUpPrefix(String language) => switch (language) {
    'Tagalog' => 'Tungkol sa nauna mong tanong: ',
    'Bisaya' => 'Mahitungod sa imong pangutana ganina: ',
    _ => 'About your earlier question: ',
  };

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

  Future<SamSamReply> _answerFromLocalContext(
    String query,
    int versionId,
    String language,
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
          return SamSamReply(
            _localized(
              language,
              query.contains('yesterday')
                  ? 'I don’t see a meaningful Scripture reading session from yesterday on this device.'
                  : 'I don’t see a meaningful Scripture reading session from today yet.',
            ),
          );
        }
        final label = query.contains('yesterday') ? 'Yesterday' : 'Today';
        return SamSamReply('$label you read ${_summarizeHistory(history)}.');
      }
      final context = await journey.userReadingContext(versionId);
      if (context.recentlyRead.isEmpty) {
        return SamSamReply(
          _localized(
            language,
            'Your local Journey does not have a meaningful reading session yet. Open a passage and spend a little time reading it.',
          ),
        );
      }
      return SamSamReply(
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
      return SamSamReply(
        _localized(
          language,
          'I couldn’t find a matching bookmark, highlight, or note stored on this device. I won’t invent a saved passage.',
        ),
      );
    }
    final kinds = filtered.map((item) => item.kind).toSet().join(', ');
    return SamSamReply(
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

  Future<SamSamReply> _answer(
    String question,
    int versionId, {
    required String language,
    required bool followUp,
  }) async {
    final query = question.trim();
    if (query.isEmpty) {
      return SamSamReply(
        _localized(language, 'What would you like to explore in the Bible?'),
      );
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
      'magpakamatay',
      'magpakamatay na',
      'dili na ko ganahan mabuhi',
      'di na ko ganahan mabuhi',
    ])) {
      return SamSamReply(switch (language) {
        'Tagalog' =>
          'Ikinalulungkot ko na matindi ang sakit na nararamdaman mo. Tumawag ngayon sa emergency services o crisis line sa inyong lugar. Sabihan ang isang taong pinagkakatiwalaan mo at hilinging samahan ka. Huwag mag-isa kung maaari mong saktan ang sarili mo. Kailangan mo ng tulong ng tao ngayon.',
        'Bisaya' =>
          'Nasubo ko nga grabe ang imong kasakit. Tawag dayon sa emergency services o crisis line sa inyong lugar. Sultihi ang kasaligan nga tawo ug hangyoa nga magpabilin uban nimo. Ayaw pag-inusara kon basin pasakitan nimo ang imong kaugalingon. Kinahanglan nimo og tabang sa tawo karon.',
        _ =>
          'I’m very sorry you are in so much pain. Please call emergency services or a crisis line now. Tell a trusted person and ask them to stay with you. Do not stay alone if you may hurt yourself. I can share Bible verses, but you need help from a person right now.',
      }, verses: await _loadReferences(['Psalm 34:18', 'Romans 8:38-39'], versionId));
    }
    if (words.any({'hi', 'hello', 'hey', 'greetings'}.contains)) {
      return SamSamReply(
        _localized(
          language,
          'Hello! I’m glad you are here. Ask me about a Bible person or story. You can also ask for verses about your life, or type a verse like John 3:16.',
        ),
      );
    }
    if (_containsAny(lower, [
      'good morning',
      'good afternoon',
      'good evening',
    ])) {
      return SamSamReply(
        _localized(
          language,
          'Hello! I hope you are having a good day. What would you like to find in the Bible?',
        ),
      );
    }
    if (_containsAny(lower, ['how are you', 'how are u'])) {
      return SamSamReply(
        _localized(
          language,
          'I’m ready to help you with the Bible. What are you thinking or feeling today?',
        ),
      );
    }
    if (words.any({'thanks', 'thank', 'thankyou', 'salamat'}.contains)) {
      return SamSamReply(
        _localized(
          language,
          'You’re welcome! You can ask me another Bible question at any time.',
        ),
      );
    }
    if (words.any({'bye', 'goodbye', 'paalam'}.contains) ||
        lower.contains('see you') ||
        lower.contains('amping')) {
      return SamSamReply(
        _localized(
          language,
          'Goodbye for now. I hope God’s Word gives you wisdom, courage, and peace.',
        ),
      );
    }
    if (_containsAny(lower, [
      'what can you do',
      'help me',
      'how do i use',
      'help',
    ])) {
      return SamSamReply(
        _localized(
          language,
          'I can find Bible verses, explain Bible people and stories, and share verses for how you feel. Try: “Romans 8:28,” “Who was Moses?”, “verses about worry,” or “tell me about David and Saul.”',
        ),
      );
    }

    final reference = _reference.firstMatch(query);
    if (reference != null) {
      final verses = await _lookupReference(reference, versionId);
      if (verses.isNotEmpty) {
        return SamSamReply(
          'Here is the passage you asked for.',
          verses: verses,
        );
      }
    }

    if (_isAboutDavid(lower)) {
      final specific = await _groundedAnswer(
        lower,
        versionId,
        language: language,
        davidOnly: true,
      );
      if (specific != null) return specific;
      return SamSamReply(
        _localized(
          language,
          'I’m Sam-Sam, an offline Bible companion inspired by the Psalms. I can help you explore Scripture and Bible stories.',
        ),
        verses: await _loadReferences([
          '1 Samuel 16:12-13',
          'Acts 13:22',
        ], versionId),
      );
    }

    final grounded = await _groundedAnswer(
      lower,
      versionId,
      language: language,
    );
    if (grounded != null) {
      return followUp
          ? SamSamReply(
              '${_followUpPrefix(language)}${grounded.message}',
              verses: grounded.verses,
            )
          : grounded;
    }

    final keywords = _topicWords(lower);
    final results = await _searchKeywords(keywords, versionId);
    if (results.isNotEmpty) {
      return SamSamReply(
        followUp
            ? '${_followUpPrefix(language)}${_localized(language, 'I found these verses in your chosen Bible version. Please read the full chapter to understand them better.')}'
            : _localized(
                language,
                'I found these verses in your chosen Bible version. Please read the full chapter to understand them better.',
              ),
        verses: results,
      );
    }
    return SamSamReply(
      _localized(
        language,
        'I can’t answer that from my offline Bible guide. When you’re online, I can help with more topics. Offline, try asking about a Bible verse, story, or topic.',
      ),
    );
  }

  Future<SamSamReply?> _groundedAnswer(
    String query,
    int versionId, {
    required String language,
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
        return SamSamReply(
          _localized(language, answer.message, triggers: answer.triggers),
          verses: await _loadReferences(answer.references, versionId),
        );
      }
    }
    return null;
  }

  String _localized(
    String language,
    String english, {
    List<String> triggers = const [],
  }) {
    if (language == _english) return english;
    if (english.startsWith('Hello! I’m glad')) {
      return language == 'Tagalog'
          ? 'Kumusta! Masaya akong narito ka. Magtanong tungkol sa tao o kuwento sa Biblia, humingi ng mga talata para sa pinagdaraanan mo, o mag-type ng sanggunian gaya ng Juan 3:16.'
          : 'Kumusta! Nalipay ko nga ania ka. Pangutana bahin sa tawo o sugilanon sa Biblia, pangayo og mga bersikulo para sa imong kahimtang, o isulat ang reperensiya sama sa Juan 3:16.';
    }
    if (english.startsWith('Hello! I hope')) {
      return language == 'Tagalog'
          ? 'Kumusta! Sana ay maganda ang araw mo. Ano ang gusto mong hanapin sa Biblia?'
          : 'Kumusta! Hinaot maayo ang imong adlaw. Unsa ang gusto nimong pangitaon sa Biblia?';
    }
    if (english.startsWith('I’m ready to help')) {
      return language == 'Tagalog'
          ? 'Handa akong tumulong sa pag-aaral ng Biblia. Ano ang iniisip o nararamdaman mo ngayon?'
          : 'Andam ko motabang sa pagtuon sa Biblia. Unsa ang imong gihunahuna o gibati karon?';
    }
    if (english.startsWith('You’re welcome!')) {
      return language == 'Tagalog'
          ? 'Walang anuman! Maaari kang magtanong ulit tungkol sa Biblia anumang oras.'
          : 'Walay sapayan! Pwede ka mangutana pag-usab bahin sa Biblia bisan kanus-a.';
    }
    if (english.startsWith('Goodbye for now.')) {
      return language == 'Tagalog'
          ? 'Paalam muna. Nawa’y bigyan ka ng Salita ng Diyos ng karunungan, tapang, at kapayapaan.'
          : 'Amping sa pagkakaron. Hinaot hatagan ka sa Pulong sa Diyos og kaalam, kaisog, ug kalinaw.';
    }
    if (english.startsWith('I can find Bible verses')) {
      return language == 'Tagalog'
          ? 'Makakahanap ako ng mga talata, makapagpapaliwanag tungkol sa mga tao at kuwento sa Biblia, at makapagbabahagi ng mga talata para sa nararamdaman mo. Subukan: “Juan 3:16,” “Sino si Moises?” o “mga talata tungkol sa pag-aalala.”'
          : 'Makapangita ko og mga bersikulo, makapasabot bahin sa mga tawo ug sugilanon sa Biblia, ug makahatag og mga bersikulo para sa imong gibati. Sulayi: “Juan 3:16,” “Kinsa si Moises?” o “mga bersikulo bahin sa kabalaka.”';
    }
    if (english.startsWith('I did not understand that')) {
      return language == 'Tagalog'
          ? 'Hindi ko lubos na naunawaan. Subukan ang maikling paksa, pangalan ng tao, kuwento, o sanggunian gaya ng Roma 8:28. Maaari mo ring itanong, “Ano ang kaya mong gawin?”'
          : 'Wala ko makasabot pag-ayo. Sulayi ang mubo nga topiko, ngalan sa tawo, sugilanon, o reperensiya sama sa Roma 8:28. Pwede usab ka mangutana, “Unsa ang imong matabang?”';
    }
    final theme = triggers.join(' ');
    if (language == 'Tagalog') {
      if (_containsAny(theme, ['anxious', 'anxiety', 'worried', 'worry'])) {
        return 'Ikinalulungkot kong nababalisa ka. Sabihin mo sa Diyos ang bumabagabag sa iyo at harapin ang bawat araw nang paisa-isa. Makakatulong ding makipag-usap sa taong pinagkakatiwalaan mo. (Filipos 4:6-7; Mateo 6:34)';
      }
      if (_containsAny(theme, ['sad', 'grief', 'brokenhearted'])) {
        return 'Ikinalulungkot ko ang pinagdaraanan mo. Malapit ang Diyos sa mga may bagbag na puso. Hindi mo kailangang harapin ito nang mag-isa—magsabi sa taong pinagkakatiwalaan mo. (Awit 34:18; Mateo 5:4)';
      }
      if (_containsAny(theme, ['pray', 'prayer'])) {
        return 'Maaaring maging simple at tapat ang panalangin. Magpasalamat sa Diyos, humingi ng tulong at kapatawaran, at ipanalangin ang ibang tao. (Mateo 6:9-13; Filipos 4:6-7)';
      }
      if (_containsAny(theme, ['forgive', 'forgiveness', 'forgiven'])) {
        return 'Maawain at handang magpatawad ang Diyos. Ipinapayo ng Biblia na aminin ang kasalanan, tanggapin ang kapatawaran ng Diyos, at magpatawad din sa iba. (1 Juan 1:9; Efeso 4:32)';
      }
      if (_containsAny(theme, ['hope', 'hopeless'])) {
        return 'Ang pag-asa sa Biblia ay pagtitiwala sa Diyos kahit mahirap ang kalagayan. Nagbibigay siya ng lakas, kaaliwan, at pag-asa para sa hinaharap. (Roma 15:13)';
      }
      if (_containsAny(theme, ['love'])) {
        return 'Itinuturo ng Biblia na matiyaga at mabait ang pag-ibig. Nagsasabi ito ng katotohanan at nagmamalasakit sa kapwa. (1 Corinto 13:4-7)';
      }
      if (_containsAny(theme, ['jesus christ', 'who is jesus'])) {
        return 'Itinuturo ng Bagong Tipan na si Jesus ang Anak ng Diyos at Tagapagligtas. Itinuro niya sa mga tao ang tungkol sa Diyos, namatay sa krus, at muling nabuhay. (Juan 3:16; 1 Corinto 15:3-4)';
      }
      if (_containsAny(theme, ['creation', 'created the world'])) {
        return 'Sinasabi sa Genesis na nilikha ng Diyos ang langit at lupa, pati ang mga halaman, hayop, at tao. Nilikha niya ang tao ayon sa kanyang larawan. (Genesis 1:1-3, 26-27)';
      }
      if (_containsAny(theme, ['goliath'])) {
        return 'Batang pastol si David. Nagtiwala siya sa Diyos at tinalo si Goliat gamit ang tirador at bato. Sinabi niyang mula sa Diyos ang tagumpay. (1 Samuel 17:45-50)';
      }
      if (_containsAny(theme, ['moses'])) {
        return 'Tinawag ng Diyos si Moises upang pangunahan ang Israel palabas sa pagkaalipin sa Ehipto. Sa pamamagitan din ni Moises ibinigay ng Diyos ang Sampung Utos. (Exodo 3:9-10; 20:1-3)';
      }
      if (_containsAny(theme, ['noah', 'flood', 'ark'])) {
        return 'Nagtiwala si Noe sa Diyos at gumawa ng arka. Iningatan ng Diyos si Noe at ang kanyang pamilya sa baha. Pagkatapos, naging tanda ng pangako ng Diyos ang bahaghari. (Genesis 6:13-14; 9:12-13)';
      }
      return 'Nauunawaan ko ang tanong mo. Narito ang gabay ng Biblia: $english';
    }
    if (language == 'Bisaya') {
      if (_containsAny(theme, ['anxious', 'anxiety', 'worried', 'worry'])) {
        return 'Pasayloa nga nabalaka ka. Isulti sa Diyos ang imong gikabalak-an ug atubanga ang matag adlaw sa hinay-hinay. Makatabang usab ang pagpakigsulti sa kasaligan nga tawo. (Filipos 4:6-7; Mateo 6:34)';
      }
      if (_containsAny(theme, ['sad', 'grief', 'brokenhearted'])) {
        return 'Nasubo ko sa imong giantos. Duol ang Diyos sa mga dugmok ug kasingkasing. Dili nimo kinahanglan atubangon kini nga ikaw ra—pakigsulti sa kasaligan nga tawo. (Salmo 34:18; Mateo 5:4)';
      }
      if (_containsAny(theme, ['pray', 'prayer'])) {
        return 'Mahimong yano ug kinasingkasing ang pag-ampo. Pagpasalamat sa Diyos, pangayo og tabang ug pasaylo, ug iampo ang ubang tawo. (Mateo 6:9-13; Filipos 4:6-7)';
      }
      if (_containsAny(theme, ['forgive', 'forgiveness', 'forgiven'])) {
        return 'Maloloy-on ug andam mopasaylo ang Diyos. Tudloan kita sa Biblia sa pag-angkon sa sala, pagdawat sa pasaylo sa Diyos, ug pagpasaylo sa uban. (1 Juan 1:9; Efeso 4:32)';
      }
      if (_containsAny(theme, ['hope', 'hopeless'])) {
        return 'Ang paglaum sa Biblia mao ang pagsalig sa Diyos bisan lisod ang kahimtang. Siya mohatag og kusog, kahupayan, ug paglaum sa umaabot. (Roma 15:13)';
      }
      if (_containsAny(theme, ['love'])) {
        return 'Ang gugma mapailubon ug maluluy-on sumala sa Biblia. Nagsulti kini sa tinuod ug nagpakabana sa uban. (1 Corinto 13:4-7)';
      }
      if (_containsAny(theme, ['jesus christ', 'who is jesus'])) {
        return 'Ang Bag-ong Tugon nagtudlo nga si Jesus Anak sa Diyos ug Manluluwas. Nagtudlo siya bahin sa Diyos, namatay sa krus, ug nabanhaw. (Juan 3:16; 1 Corinto 15:3-4)';
      }
      if (_containsAny(theme, ['creation', 'created the world'])) {
        return 'Sumala sa Genesis, gibuhat sa Diyos ang langit ug yuta, mga tanom, mananap, ug mga tawo. Gibuhat niya ang tawo sumala sa iyang dagway. (Genesis 1:1-3, 26-27)';
      }
      if (_containsAny(theme, ['goliath'])) {
        return 'Batang magbalantay og karnero si David. Misalig siya sa Diyos ug gipildi si Goliat gamit ang lambuyog ug bato. Miingon siya nga ang kadaogan gikan sa Diyos. (1 Samuel 17:45-50)';
      }
      if (_containsAny(theme, ['moses'])) {
        return 'Gitawag sa Diyos si Moises aron pangunahan ang Israel paggawas sa pagkaulipon sa Ehipto. Pinaagi usab kang Moises gihatag sa Diyos ang Napulo ka Sugo. (Exodo 3:9-10; 20:1-3)';
      }
      if (_containsAny(theme, ['noah', 'flood', 'ark'])) {
        return 'Misalig si Noe sa Diyos ug naghimo og arka. Gipanalipdan sa Diyos si Noe ug ang iyang pamilya panahon sa baha. Human niini, nahimong timaan sa saad sa Diyos ang balangaw. (Genesis 6:13-14; 9:12-13)';
      }
      return 'Nasabtan nako ang imong pangutana. Mao kini ang giya sa Biblia: $english';
    }
    return english;
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
