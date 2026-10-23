enum SamSamExpression { happy, excited, thinking, sad, surprised }

enum SamSamGesture { wave, point, read, walk, jump }

class SamSamFact {
  const SamSamFact({
    required this.message,
    required this.reference,
    required this.expression,
  });

  final String message;
  final String reference;
  final SamSamExpression expression;

  String get question => 'Tell me more about $reference';
}

class SamSamStoryMoment {
  const SamSamStoryMoment({
    required this.title,
    required this.message,
    required this.reference,
    required this.expression,
  });

  final String title;
  final String message;
  final String reference;
  final SamSamExpression expression;

  String get question => 'Tell me the story of $title';
}

abstract final class SamSamFacts {
  static const facts = <SamSamFact>[
    SamSamFact(
      message: 'The book of Psalms is a collection of 150 songs and prayers.',
      reference: 'Psalm 150',
      expression: SamSamExpression.excited,
    ),
    SamSamFact(
      message: 'Psalm 23 describes God as a caring shepherd.',
      reference: 'Psalm 23:1-4',
      expression: SamSamExpression.happy,
    ),
    SamSamFact(
      message: 'Psalm 119 has 176 verses, more than any other Bible chapter.',
      reference: 'Psalm 119:1-8',
      expression: SamSamExpression.surprised,
    ),
    SamSamFact(
      message:
          'Psalm 117 is the shortest chapter in the Bible, with two verses.',
      reference: 'Psalm 117:1-2',
      expression: SamSamExpression.excited,
    ),
    SamSamFact(
      message: 'Psalm 51 is a prayer asking God for mercy and a clean heart.',
      reference: 'Psalm 51:10-12',
      expression: SamSamExpression.thinking,
    ),
    SamSamFact(
      message: 'Psalm 150 invites everything that breathes to praise God.',
      reference: 'Psalm 150:6',
      expression: SamSamExpression.happy,
    ),
    SamSamFact(
      message:
          'Psalm 121 says our help comes from the Lord, maker of heaven and earth.',
      reference: 'Psalm 121:1-2',
      expression: SamSamExpression.happy,
    ),
  ];

  static const stories = <SamSamStoryMoment>[
    SamSamStoryMoment(
      title: 'Noah and the ark',
      message:
          'Noah trusted God and built an ark. His family and the animals were kept safe through the flood.',
      reference: 'Genesis 6–9',
      expression: SamSamExpression.thinking,
    ),
    SamSamStoryMoment(
      title: 'Joseph forgives his brothers',
      message:
          'After many hard years in Egypt, Joseph forgave the brothers who had sold him and helped save their family from famine.',
      reference: 'Genesis 45:1–15',
      expression: SamSamExpression.happy,
    ),
    SamSamStoryMoment(
      title: 'Moses leads Israel through the sea',
      message:
          'When Israel was trapped between the sea and Pharaoh’s army, God made a way through the water.',
      reference: 'Exodus 14',
      expression: SamSamExpression.surprised,
    ),
    SamSamStoryMoment(
      title: 'David faces Goliath',
      message:
          'David faced the giant Goliath, trusting that the battle belonged to the Lord rather than relying on armor.',
      reference: '1 Samuel 17',
      expression: SamSamExpression.excited,
    ),
    SamSamStoryMoment(
      title: 'Daniel in the lions’ den',
      message:
          'Daniel kept praying to God even when it was forbidden. God shut the lions’ mouths and protected him.',
      reference: 'Daniel 6',
      expression: SamSamExpression.surprised,
    ),
    SamSamStoryMoment(
      title: 'The good Samaritan',
      message:
          'Jesus told of a Samaritan who stopped to care for an injured stranger, showing what it means to love our neighbor.',
      reference: 'Luke 10:25–37',
      expression: SamSamExpression.happy,
    ),
    SamSamStoryMoment(
      title: 'The lost son comes home',
      message:
          'A father welcomed his returning son with compassion. Jesus used this story to show the joy of forgiveness.',
      reference: 'Luke 15:11–32',
      expression: SamSamExpression.happy,
    ),
    SamSamStoryMoment(
      title: 'Jesus calms the storm',
      message:
          'When a storm frightened the disciples, Jesus calmed the wind and waves and asked them to trust him.',
      reference: 'Mark 4:35–41',
      expression: SamSamExpression.surprised,
    ),
    SamSamStoryMoment(
      title: 'Jesus feeds the crowd',
      message:
          'Jesus gave thanks for five loaves and two fish, and the food was shared with thousands of people.',
      reference: 'John 6:1–14',
      expression: SamSamExpression.excited,
    ),
    SamSamStoryMoment(
      title: 'Jesus is alive',
      message:
          'On the third day, Jesus rose from the dead. The women at the tomb were the first to hear the good news.',
      reference: 'Luke 24:1–12',
      expression: SamSamExpression.excited,
    ),
  ];
}
