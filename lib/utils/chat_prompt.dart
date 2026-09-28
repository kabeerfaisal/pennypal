/// Builds the prompt sent to Groq and decides when the app should answer
/// locally instead of calling the model.
class ChatPrompt {
  ChatPrompt._();

  /// Words that signal the question actually needs the user's money data.
  static const List<String> _moneyWords = [
    'budget',
    'spend',
    'spent',
    'spending',
    'expense',
    'expenses',
    'save',
    'saving',
    'savings',
    'goal',
    'goals',
    'money',
    'income',
    'salary',
    'earn',
    'afford',
    'cheap',
    'expensive',
    'price',
    'cost',
    'costs',
    'bill',
    'bills',
    'limit',
    'limits',
    'remaining',
    'balance',
    'category',
    'categories',
    'invest',
    'investment',
    'loan',
    'debt',
    'discount',
    'purchase',
    'buy',
    'shopping',
    'cash',
    'wallet',
    'rent',
    'broke',
    'spends',
    'left',
    'plan',
    'deposit',
  ];

  /// Phrases that are pure greetings with no actual question attached.
  static const Set<String> _smallTalk = {
    'hallo',
    'hello',
    'hi',
    'hii',
    'hey',
    'heya',
    'yo',
    'hiya',
    'ok',
    'okay',
    'sup',
    'gm',
    'gn',
    'good morning',
    'good evening',
    'good afternoon',
    'how are you',
    'how r u',
    'how are u',
    'how ru',
    'whats up',
    "what's up",
    'kya haal',
    'kya hal',
    'kya hua',
    'assalam o alaikum',
    'assalamualaikum',
    'salaam',
    'salam',
    'namaste',
    'ji',
    'bhai',
    'yaar',
    'thanks',
    'thank you',
    'ta',
    'shukriya',
    'bye',
    'goodbye',
    'see you',
    'test',
    'testing',
  };

  /// True when the question plausibly needs the live finance numbers.
  static bool isFinanceRelated(String text) {
    final q = ' ${_normalise(text)} ';
    for (final w in _moneyWords) {
      if (q.contains(' $w ') ||
          q.contains(' ${w}s ') ||
          q.contains(' $w.') ||
          q.contains(' $w?')) {
        return true;
      }
    }
    // A bare number usually means "how much of this do I have / spend".
    return RegExp(r'\d').hasMatch(text);
  }

  /// True when the message is only a greeting / pleasantry, so the model does
  /// not need to be involved at all.
  static bool isSmallTalk(String text) {
    final n = _normalise(text);
    if (n.isEmpty) return false;
    if (_smallTalk.contains(n)) return true;
    // "hi there", "hello, how are you?" and similar short pleasantries.
    if (n.split(' ').length <= 4) {
      final words = n.split(' ').where((w) => w.isNotEmpty).toSet();
      if (words.isNotEmpty && words.every((w) => _greetingWords.contains(w))) {
        return true;
      }
    }
    return false;
  }

  static const Set<String> _greetingWords = {
    'hi',
    'hii',
    'hello',
    'hallo',
    'hey',
    'heya',
    'yo',
    'hiya',
    'there',
    'how',
    'are',
    'you',
    'r',
    'u',
    'ru',
    'whats',
    'what',
    'up',
    's',
    'am',
    'i',
    'ok',
    'okay',
    'sup',
    'good',
    'morning',
    'evening',
    'afternoon',
    'night',
    'and',
    'a',
    'the',
    'to',
    'me',
    'is',
    'it',
    'going',
    'on',
    'doing',
    'well',
    'fine',
    'yes',
    'no',
    'assalam',
    'alaikum',
    'salam',
    'namaste',
    'ji',
    'bhai',
    'yaar',
    'thanks',
    'thank',
    'ta',
    'shukriya',
    'bye',
    'see',
    'test',
    'testing',
    'kya',
    'haal',
    'hua',
    'huaa',
  };

  /// A short, question-free greeting reply. Keeps the app feeling instant and
  /// stops the model from volunteering budget advice on "hello".
  static String smallTalkReply(String text) {
    final n = _normalise(text);
    if (n.contains('thank')) {
      return 'Happy to help 💚 Ask me anything, anytime.';
    }
    if (n.contains('bye') || n.contains('see you') || n == 'ok') {
      return 'See you 💚';
    }
    if (n.contains('how are') ||
        n.contains('how r') ||
        n.contains('kya haal')) {
      return 'Doing well, thanks for asking 💚 What can I help you with?';
    }
    return 'Hi! 💚 What would you like to know?';
  }

  /// Builds the final user turn.
  ///
  /// GPT-OSS is instructed by Groq to keep every instruction inside the user
  /// message rather than a system prompt, so the rules live here too.
  static String build({required String question, required String snapshot}) {
    final buffer = StringBuffer()
      ..writeln(
        'You are PennyPal AI, a personal finance assistant inside a '
        'student budgeting app.',
      )
      ..writeln()
      ..writeln('Follow these rules exactly:')
      ..writeln(
        '1. Answer ONLY the question that was asked. If it does not '
        'ask for advice, do not give any.',
      )
      ..writeln(
        '2. Never volunteer the budget, totals, or spending figures '
        'unless the question is about them.',
      )
      ..writeln(
        '3. Never invent amounts. If the numbers you were given are '
        'not enough to answer, say so plainly.',
      )
      ..writeln(
        '4. Keep it short: one to three sentences, unless the student '
        'explicitly asks for a plan, list, or detailed breakdown.',
      )
      ..writeln('5. Be warm and natural, like a helpful friend, not a report.');

    if (isFinanceRelated(question)) {
      buffer
        ..writeln()
        ..writeln('Live numbers for this student:')
        ..writeln(snapshot);
    }

    buffer
      ..writeln()
      ..writeln('Student question: $question')
      ..writeln()
      ..write('Answer that question only.');

    return buffer.toString();
  }

  static String _normalise(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s.]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
