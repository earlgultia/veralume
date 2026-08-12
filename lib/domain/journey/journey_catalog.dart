import '../../data/models/journey_models.dart';

const dailyLights = <DailyLight>[
  DailyLight(
    PassageReference(19, 119, startVerse: 105),
    'God’s Word may not reveal the whole road at once. It gives light for the faithful next step.',
  ),
  DailyLight(
    PassageReference(43, 8, startVerse: 12),
    'Following Jesus is an invitation to walk in light, even when the way ahead feels uncertain.',
  ),
  DailyLight(
    PassageReference(20, 3, startVerse: 5, endVerse: 6),
    'Trust can begin before every question is answered. Bring God the path you cannot yet see.',
  ),
  DailyLight(
    PassageReference(19, 23, startVerse: 1, endVerse: 3),
    'Rest is part of the journey. The Shepherd leads with care, not hurry.',
  ),
  DailyLight(
    PassageReference(23, 41, startVerse: 10),
    'Courage is not the absence of fear; it is remembering who remains with you.',
  ),
  DailyLight(
    PassageReference(50, 4, startVerse: 6, endVerse: 7),
    'Prayer makes room to place what you carry into God’s care and receive peace for today.',
  ),
  DailyLight(
    PassageReference(40, 11, startVerse: 28, endVerse: 30),
    'You do not need to carry every burden alone. Christ welcomes the weary with gentleness.',
  ),
  DailyLight(
    PassageReference(45, 8, startVerse: 28),
    'Even unfinished seasons can be held within God’s patient and purposeful care.',
  ),
  DailyLight(
    PassageReference(25, 3, startVerse: 22, endVerse: 23),
    'Each morning is evidence that mercy has not run out. Today can begin again.',
  ),
  DailyLight(
    PassageReference(58, 11, startVerse: 1),
    'Faith takes the next faithful step while hope learns to see beyond the visible.',
  ),
  DailyLight(
    PassageReference(59, 1, startVerse: 5),
    'Wisdom begins with an honest request. You are invited to ask, listen, and keep walking.',
  ),
  DailyLight(
    PassageReference(62, 4, startVerse: 9, endVerse: 11),
    'God’s love is not merely an idea to understand; it becomes a way of living toward others.',
  ),
  DailyLight(
    PassageReference(51, 3, startVerse: 15),
    'Let Christ’s peace have a voice in your decisions, relationships, and pace today.',
  ),
  DailyLight(
    PassageReference(19, 46, startVerse: 1),
    'A refuge is not a denial of trouble. It is a secure place from which to face it.',
  ),
];

const verseConnections = <VerseConnection>[
  VerseConnection(
    PassageReference(43, 3, startVerse: 16),
    PassageReference(45, 5, startVerse: 8),
    'Similar Theme',
  ),
  VerseConnection(
    PassageReference(43, 3, startVerse: 16),
    PassageReference(62, 4, startVerse: 9),
    'Related Passage',
  ),
  VerseConnection(
    PassageReference(43, 3, startVerse: 16),
    PassageReference(49, 2, startVerse: 4, endVerse: 5),
    'Same Topic',
  ),
  VerseConnection(
    PassageReference(19, 23, startVerse: 1),
    PassageReference(43, 10, startVerse: 11),
    'New Testament Connection',
  ),
  VerseConnection(
    PassageReference(23, 53, startVerse: 5),
    PassageReference(60, 2, startVerse: 24),
    'Prophecy / Fulfillment',
  ),
  VerseConnection(
    PassageReference(40, 22, startVerse: 37),
    PassageReference(5, 6, startVerse: 5),
    'Old Testament Connection',
  ),
  VerseConnection(
    PassageReference(50, 4, startVerse: 6),
    PassageReference(60, 5, startVerse: 7),
    'Similar Theme',
  ),
  VerseConnection(
    PassageReference(45, 8, startVerse: 28),
    PassageReference(1, 50, startVerse: 20),
    'Related Passage',
  ),
  VerseConnection(
    PassageReference(46, 13, startVerse: 4),
    PassageReference(62, 4, startVerse: 7),
    'Same Topic',
  ),
  VerseConnection(
    PassageReference(20, 3, startVerse: 5),
    PassageReference(59, 1, startVerse: 5),
    'Cross Reference',
  ),
];

const guidedJourneys = <GuidedJourney>[
  GuidedJourney(
    id: 'anxious',
    title: 'When You’re Anxious',
    theme: 'Peace',
    description:
        'Walk through Scripture when worry feels heavy and remember that you are not carrying it alone.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(19, 23),
        'Notice the quiet ways the Shepherd provides and leads.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(40, 6, startVerse: 25, endVerse: 34),
        'Name tomorrow’s worries, then return gently to today.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(50, 4, startVerse: 4, endVerse: 9),
        'Bring one specific concern to God in prayer.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(23, 41, startVerse: 10),
        'Read slowly and notice each promise of God’s presence.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(19, 46),
        'Be still for a moment before moving on.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(60, 5, startVerse: 7),
        'What burden can you place into God’s care today?',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(43, 14, startVerse: 27),
        'Receive Christ’s peace without forcing yourself to feel differently.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'hope',
    title: 'When You Need Hope',
    theme: 'Hope',
    description:
        'Remember God’s presence and promises through difficult seasons.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(19, 42, startVerse: 5),
        'Speak honestly to your soul while continuing to hope.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(25, 3, startVerse: 21, endVerse: 24),
        'Mercy meets you again this morning.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(45, 5, startVerse: 1, endVerse: 5),
        'Hope can grow through endurance, one step at a time.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(45, 8, startVerse: 18, endVerse: 25),
        'Wait with patience for what is not yet visible.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(45, 15, startVerse: 13),
        'Ask God to fill the space where hope feels thin.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(58, 6, startVerse: 19),
        'Picture hope as an anchor holding steady.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(66, 21, startVerse: 1, endVerse: 5),
        'Let Scripture widen your view beyond the present moment.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'strength',
    title: 'When You Need Strength',
    theme: 'Strength',
    description:
        'Find courage rooted in God’s presence rather than your own reserves.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(23, 40, startVerse: 28, endVerse: 31),
        'Waiting can be a place where strength is renewed.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(6, 1, startVerse: 9),
        'Take courage from the One who goes with you.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(19, 18, startVerse: 1, endVerse: 3),
        'Name the images of safety you find in this passage.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(47, 12, startVerse: 9, endVerse: 10),
        'Strength and weakness can exist in the same honest prayer.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(49, 6, startVerse: 10, endVerse: 11),
        'Stand in strength received, not manufactured.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(50, 4, startVerse: 13),
        'Read this within the surrounding passage of contentment.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(19, 121),
        'Notice every way God is described as your keeper.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'forgive',
    title: 'Learning to Forgive',
    theme: 'Forgiveness',
    description:
        'Explore grace, truth, boundaries, and the patient work of forgiveness.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(40, 18, startVerse: 21, endVerse: 22),
        'Forgiveness is a continuing posture, not simple arithmetic.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(49, 4, startVerse: 31, endVerse: 32),
        'Notice what Scripture invites you to release and practice.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(51, 3, startVerse: 12, endVerse: 14),
        'Compassion and patience make room for forgiveness.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(42, 6, startVerse: 27, endVerse: 36),
        'Ask what merciful love could look like with wisdom and truth.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(1, 50, startVerse: 15, endVerse: 21),
        'Joseph names harm truthfully while refusing revenge.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(51, 3, startVerse: 15),
        'Let peace guide the next conversation or boundary.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(19, 103, startVerse: 8, endVerse: 12),
        'Rest in the breadth of God’s mercy toward you.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'faith',
    title: 'Growing in Faith',
    theme: 'Faith',
    description:
        'Practice trust through listening, obedience, patience, and prayer.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(58, 11, startVerse: 1, endVerse: 6),
        'Faith trusts God’s character beyond what can be seen.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(45, 10, startVerse: 17),
        'Make room to hear before trying to achieve.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(59, 1, startVerse: 2, endVerse: 6),
        'Ask for wisdom in the place where endurance is forming.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(41, 9, startVerse: 23, endVerse: 24),
        'Bring both belief and doubt honestly to Jesus.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(20, 3, startVerse: 5, endVerse: 6),
        'Entrust one uncertain path to God.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(48, 5, startVerse: 22, endVerse: 25),
        'Keep in step; growth is lived one step at a time.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(61, 1, startVerse: 5, endVerse: 8),
        'Consider which quality faith is inviting you to cultivate next.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'jesus',
    title: 'Following Jesus',
    theme: 'Discipleship',
    description:
        'Listen to Jesus’ invitation and walk through the shape of discipleship.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(40, 4, startVerse: 18, endVerse: 22),
        'Hear the invitation to follow before the call to accomplish.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(40, 5, startVerse: 1, endVerse: 12),
        'Which blessing meets the season you are in?',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(41, 8, startVerse: 34, endVerse: 37),
        'Following Jesus reshapes what we call gain and loss.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(42, 10, startVerse: 38, endVerse: 42),
        'Choose presence with Jesus amid necessary activity.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(43, 13, startVerse: 12, endVerse: 17),
        'Look for one quiet way to serve someone today.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(43, 15, startVerse: 1, endVerse: 8),
        'Fruit grows from abiding, not frantic effort.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(40, 28, startVerse: 18, endVerse: 20),
        'Remember that the One who sends you also remains with you.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'lost',
    title: 'When You Feel Lost',
    theme: 'Guidance',
    description:
        'Find a steady path through Scripture when direction is difficult to see.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(19, 119, startVerse: 105),
        'Ask only for enough light to take the next faithful step.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(20, 3, startVerse: 5, endVerse: 6),
        'Offer God the path that you cannot straighten alone.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(23, 30, startVerse: 20, endVerse: 21),
        'Practice listening for the quiet direction of wisdom.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(19, 25, startVerse: 4, endVerse: 5),
        'Turn the need for direction into a simple prayer.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(42, 15, startVerse: 3, endVerse: 7),
        'Remember the searching love of the Shepherd.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(43, 14, startVerse: 5, endVerse: 6),
        'Let Jesus be more than a map: remain close to the Way.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(19, 139, startVerse: 23, endVerse: 24),
        'Invite God to examine and lead your inner life.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'knowing-god',
    title: 'Knowing God',
    theme: 'God’s Character',
    description:
        'Slow down with passages that reveal God’s character, presence, and love.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(2, 34, startVerse: 5, endVerse: 7),
        'Notice the qualities God uses to describe himself.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(19, 103, startVerse: 1, endVerse: 14),
        'Remember both God’s mercy and his knowledge of your frailty.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(23, 40, startVerse: 25, endVerse: 31),
        'Let the greatness of God enlarge your hope.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(43, 1, startVerse: 14, endVerse: 18),
        'Look at how Jesus makes God known.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(43, 10, startVerse: 11),
        'Receive the care of the Good Shepherd.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(62, 4, startVerse: 7, endVerse: 12),
        'God’s love becomes visible in how we love one another.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(45, 8, startVerse: 31, endVerse: 39),
        'Rest in the love from which nothing can separate you.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'peace',
    title: 'Finding Peace',
    theme: 'Peace',
    description:
        'Make room for the peace of Christ in your mind, body, and relationships.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(43, 14, startVerse: 27),
        'Receive peace as a gift rather than a feeling to force.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(19, 4, startVerse: 6, endVerse: 8),
        'Bring your concerns into the presence of God, then rest.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(23, 26, startVerse: 3, endVerse: 4),
        'Let a steadfast mind return again to trust.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(50, 4, startVerse: 4, endVerse: 9),
        'Practice the movement from prayer toward guarded peace.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(51, 3, startVerse: 12, endVerse: 15),
        'Consider how peace can guide the way you relate to others.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(41, 4, startVerse: 35, endVerse: 41),
        'Notice who is present with you in the storm.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(19, 131),
        'Let your soul become quiet without needing every answer.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'fear',
    title: 'Overcoming Fear',
    theme: 'Courage',
    description:
        'Walk toward courage by remembering God’s nearness and faithful care.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(19, 27, startVerse: 1),
        'Name what fear says, then answer with what is true of God.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(23, 41, startVerse: 10, endVerse: 13),
        'Hold onto every promise of presence and help.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(6, 1, startVerse: 7, endVerse: 9),
        'Courage grows alongside attention to God’s Word.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(19, 56, startVerse: 3, endVerse: 4),
        'Turn the moment of fear into a moment of trust.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(40, 10, startVerse: 26, endVerse: 31),
        'Remember that you are fully seen and deeply valued.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(55, 1, startVerse: 7),
        'Ask how power, love, and self-control can shape your response.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(62, 4, startVerse: 16, endVerse: 18),
        'Let mature love loosen fear’s hold.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'gratitude',
    title: 'Gratitude',
    theme: 'Thankfulness',
    description: 'Practice noticing grace and responding with a thankful life.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(19, 100),
        'Enter today by naming one reason for gratitude.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(19, 103, startVerse: 1, endVerse: 5),
        'Remember benefits that hurry can make easy to forget.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(42, 17, startVerse: 11, endVerse: 19),
        'Return to Jesus with thanks, as the healed traveler did.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(50, 4, startVerse: 4, endVerse: 7),
        'Let thanksgiving accompany even an unfinished prayer.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(51, 3, startVerse: 15, endVerse: 17),
        'Carry gratitude into words, work, and relationships.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(52, 5, startVerse: 16, endVerse: 18),
        'Notice that thanksgiving can coexist with difficulty.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(59, 1, startVerse: 16, endVerse: 17),
        'Trace every good gift back toward its giver.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'love',
    title: 'Love',
    theme: 'Love',
    description:
        'Explore the patient, truthful, active love revealed in Scripture.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(46, 13, startVerse: 1, endVerse: 7),
        'Choose one quality of love to practice deliberately today.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(43, 3, startVerse: 16, endVerse: 17),
        'Begin with love received before considering love given.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(43, 13, startVerse: 34, endVerse: 35),
        'Ask what Christlike love makes visible.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(45, 12, startVerse: 9, endVerse: 18),
        'Notice how sincere love becomes concrete action.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(62, 3, startVerse: 16, endVerse: 18),
        'Move love from speech alone into truth and action.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(62, 4, startVerse: 7, endVerse: 12),
        'Let God’s love become the source of your love for others.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(51, 3, startVerse: 12, endVerse: 14),
        'Put on love as the bond holding every virtue together.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'wisdom',
    title: 'Wisdom',
    theme: 'Wisdom',
    description: 'Learn to listen, discern, and live wisely before God.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(20, 1, startVerse: 1, endVerse: 7),
        'Wisdom begins with reverence and a willingness to learn.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(20, 3, startVerse: 5, endVerse: 8),
        'Let trust shape both understanding and action.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(20, 4, startVerse: 20, endVerse: 27),
        'Pay attention to the direction of your heart and feet.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(21, 3, startVerse: 1, endVerse: 8),
        'Receive the season you are in without rushing it.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(40, 7, startVerse: 24, endVerse: 27),
        'Wisdom puts the words of Jesus into practice.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(59, 1, startVerse: 5, endVerse: 8),
        'Ask openly for the wisdom you lack.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(59, 3, startVerse: 13, endVerse: 18),
        'Compare restless ambition with the fruit of wisdom from above.',
      ),
    ],
  ),
  GuidedJourney(
    id: 'prayer',
    title: 'Prayer',
    theme: 'Prayer',
    description:
        'Grow in honest, attentive prayer through the words and invitations of Scripture.',
    days: [
      GuidedJourneyDay(
        1,
        PassageReference(40, 6, startVerse: 5, endVerse: 13),
        'Pray slowly through the pattern Jesus gives.',
      ),
      GuidedJourneyDay(
        2,
        PassageReference(19, 13),
        'Bring an honest lament without hiding the hard questions.',
      ),
      GuidedJourneyDay(
        3,
        PassageReference(9, 3, startVerse: 1, endVerse: 10),
        'Like Hannah, pour out what cannot be neatly explained.',
      ),
      GuidedJourneyDay(
        4,
        PassageReference(19, 51, startVerse: 10, endVerse: 12),
        'Ask for renewal in the deepest part of your life.',
      ),
      GuidedJourneyDay(
        5,
        PassageReference(42, 11, startVerse: 5, endVerse: 13),
        'Continue asking while trusting the goodness of the giver.',
      ),
      GuidedJourneyDay(
        6,
        PassageReference(50, 4, startVerse: 6, endVerse: 7),
        'Name each request and surround it with thanksgiving.',
      ),
      GuidedJourneyDay(
        7,
        PassageReference(19, 139, startVerse: 23, endVerse: 24),
        'End with a prayer of openness, examination, and guidance.',
      ),
    ],
  ),
];

DailyLight dailyLightForDate(DateTime date) {
  final dayOrdinal = DateTime.utc(date.year, date.month, date.day);
  final index =
      dayOrdinal.difference(DateTime.utc(2026)).inDays.abs() %
      dailyLights.length;
  return dailyLights[index];
}

String testamentSection(int order) {
  if (order <= 5) return 'Pentateuch';
  if (order <= 17) return 'Historical Books';
  if (order <= 22) return 'Wisdom Books';
  if (order <= 27) return 'Major Prophets';
  if (order <= 39) return 'Minor Prophets';
  if (order <= 43) return 'Gospels';
  if (order == 44) return 'History';
  if (order <= 57) return 'Pauline Epistles';
  if (order <= 65) return 'General Epistles';
  return 'Prophecy';
}
