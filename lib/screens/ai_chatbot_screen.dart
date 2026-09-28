import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../controllers/finance_controller.dart';
import '../services/chat_history_service.dart';
import '../services/groq_service.dart';
import '../services/voice_factory.dart';
import '../services/voice_service.dart';
import '../services/voice_stt_io.dart';
import '../theme/app_theme.dart';
import '../utils/chat_prompt.dart';
import '../widgets/ai_markdown.dart';

class _ChatMessage {
  static int _seq = 0;

  final int id = ++_seq;
  final bool isUser;
  final DateTime sentAt;

  /// Both are appended to in place while the completion streams in.
  String text;
  String reasoning = '';

  _ChatMessage({required this.isUser, this.text = '', DateTime? sentAt})
    : sentAt = sentAt ?? DateTime.now();

  String get thinking => reasoning.trim();
  bool get isStreaming => !isUser && text.isEmpty;
  bool get hasReply => text.trim().isNotEmpty;

  String get clock => DateFormat.jm().format(sentAt);
}

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];

  StreamSubscription<GroqDelta>? _sub;
  Timer? _scrollTimer;
  bool _isLoading = false;
  _ChatMessage? _pending;

  /// Identifies this conversation in Firestore. Stable for the session, so
  /// every turn of one chat lands in the same thread.
  final String _chatId = DateTime.now().microsecondsSinceEpoch.toString();

  late final VoiceService _voice = createVoiceService();
  String _voiceError = '';
  bool _restoring = true;

  bool get _hasKey => GroqService.instance.isConfigured;

  static const String _greeting =
      'Hi! I\'m your PennyPal AI advisor 💚\n\n'
      'Ask me anything about budgeting, saving money, or your expenses!';

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(isUser: false, text: _greeting));

    // Voice results arrive on a platform thread, so every update hops back
    // onto the UI isolate through setState.
    final speech = _voice;
    if (speech is SpeechVoiceService) {
      speech.onResult = (text, isFinal) {
        if (!mounted) return;
        setState(() {
          if (isFinal) _voiceError = '';
          // Appended rather than replaced, so a long dictation is not truncated
          // when a new partial result arrives.
          _msgCtrl.text = _msgCtrl.text.trim().isEmpty
              ? text
              : '${_msgCtrl.text.trimRight()} $text';
          _msgCtrl.selection = TextSelection.collapsed(
            offset: _msgCtrl.text.length,
          );
        });
      };
    }

    _restoreAndInitVoice();
  }

  /// Loads the saved conversation, then sets the microphone up.
  Future<void> _restoreAndInitVoice() async {
    final stored = await ChatHistoryService.instance.load(_chatId);
    if (!mounted) return;
    if (stored.isEmpty) {
      setState(() => _restoring = false);
    } else {
      setState(() {
        _messages
          ..clear()
          ..addAll(
            stored.map(
              (m) =>
                  _ChatMessage(isUser: m.isUser, text: m.content, sentAt: m.at),
            ),
          );
        _restoring = false;
      });
      _scrollToBottom();
    }

    try {
      await _voice.init();
    } catch (e) {
      _voiceError = 'Voice input unavailable: $e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _startVoice() async {
    if (!_voice.isAvailable) {
      setState(() => _voiceError = _voice.lastError);
      return;
    }
    setState(() => _voiceError = '');
    await _voice.start();
    if (mounted) setState(() {});
  }

  Future<void> _stopVoice() async {
    await _voice.stop();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scrollTimer?.cancel();
    _voice.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;

    _msgCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _isLoading = true;
    });
    _scrollToBottom();
    // Written straight away, so a crash or a closed app cannot lose the
    // question the student asked.
    ChatHistoryService.instance.saveTurn(
      chatId: _chatId,
      role: 'user',
      content: text,
    );

    // Without a key the screen still works using on-device numbers.
    if (!_hasKey) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final reply = _localAdvice(text);
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _isLoading = false;
      });
      _save(_chatId, reply);
      _scrollToBottom();
      return;
    }

    // A bare greeting is answered locally so the model cannot turn "hello"
    // into an unsolicited budget lecture.
    if (ChatPrompt.isSmallTalk(text)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      final reply = ChatPrompt.smallTalkReply(text);
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _isLoading = false;
      });
      _save(_chatId, reply);
      _scrollToBottom();
      return;
    }

    final pending = _ChatMessage(isUser: false);
    setState(() => _pending = pending);

    final history = <Map<String, String>>[];
    for (final m in _messages) {
      if (m.isUser) {
        history.add({'role': 'user', 'content': m.text});
      } else if (m.hasReply) {
        history.add({'role': 'assistant', 'content': m.text});
      }
    }

    // GPT-OSS works best with every instruction inside the user turn. The
    // finance snapshot is only attached when the question actually needs it,
    // otherwise the model has nothing to volunteer.
    final snapshot = FinanceController.instance.financeSnapshot();
    history.add({
      'role': 'user',
      'content': ChatPrompt.build(question: text, snapshot: snapshot),
    });

    _sub = GroqService.instance
        .streamChat(messages: history)
        .listen(
          (delta) {
            if (!mounted) return;
            setState(() {
              pending.reasoning += delta.reasoning;
              pending.text += delta.content;
            });
            _scrollToBottom();
          },
          onDone: () => _finish(pending),
          onError: (Object e) => _fail(pending, e),
          cancelOnError: true,
        );
  }

  /// Persists an assistant turn. Fire and forget: the reply is already on
  /// screen, so a write failure must not disturb the conversation.
  void _save(String chatId, String reply) {
    if (reply.trim().isEmpty) return;
    ChatHistoryService.instance.saveTurn(
      chatId: chatId,
      role: 'assistant',
      content: reply,
    );
  }

  void _finish(_ChatMessage pending) {
    _sub?.cancel();
    _sub = null;
    if (!mounted) return;
    final stored = pending.hasReply
        ? pending
        : _ChatMessage(
            isUser: false,
            text: pending.thinking.isEmpty
                ? 'I could not process that.'
                : pending.thinking,
          );
    setState(() {
      _messages.add(stored);
      _pending = null;
      _isLoading = false;
    });
    _save(_chatId, stored.text);
    _scrollToBottom();
  }

  void _fail(_ChatMessage pending, Object error) {
    _sub?.cancel();
    _sub = null;
    if (!mounted) return;
    final reason = error is GroqException
        ? error.message
        : 'Network error: $error';
    // Keep any partial answer that streamed before the failure.
    final stored = pending.hasReply
        ? pending
        : _ChatMessage(isUser: false, text: '$reason\n\n${_localAdvice('')}');
    setState(() {
      _messages.add(stored);
      _pending = null;
      _isLoading = false;
    });
    _save(_chatId, stored.text);
    _scrollToBottom();
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    final pending = _pending;
    setState(() {
      if (pending != null) {
        _messages.add(
          pending.hasReply
              ? pending
              : _ChatMessage(isUser: false, text: 'Stopped.'),
        );
      }
      _pending = null;
      _isLoading = false;
    });
  }

  void _clear() {
    _stop();
    _msgCtrl.clear();
    setState(() {
      _messages
        ..removeRange(1, _messages.length)
        ..add(
          _ChatMessage(
            isUser: false,
            text: 'Fresh start 💚 Ask me anything about your money.',
          ),
        );
    });
    // Wipes the stored thread too, so "new chat" really does start clean on
    // the next device.
    ChatHistoryService.instance.clear(_chatId);
    if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Copied'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _localAdvice(String question) {
    final c = FinanceController.instance;
    final snap = c.financeSnapshot();
    final q = question.toLowerCase();
    if (q.contains('plan') || q.contains('budget')) {
      return 'Budgeting plan from your data: $snap '
          'Keep needs first, then one want, then send the contribution to a goal.';
    }
    if (q.contains('income')) {
      return 'Income this month is ${c.currencySymbol}${c.totalIncome.toStringAsFixed(0)}. $snap';
    }
    if (q.contains('spend') || q.contains('expense')) {
      return 'Spending this month is ${c.currencySymbol}${c.totalExpenses.toStringAsFixed(0)}. $snap';
    }
    if (q.contains('save') || q.contains('goal')) {
      return 'Goals: ${c.savingGoals.map((g) => '${g.title} ${(g.progress * 100).toInt()}%').join(', ')}. $snap';
    }
    return snap;
  }

  /// Streaming fires this on every token, so it is debounced into at most one
  /// scroll per frame budget and skipped while the user is reading upwards.
  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 80), _doScroll);
  }

  void _doScroll() {
    if (!mounted || !_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent - pos.pixels > 240) {
      return; // user scrolled up to re-read, leave them there
    }
    _scrollCtrl.animateTo(
      pos.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <Widget>[
      for (final m in _messages) _bubble(m),
      if (_pending != null) _bubble(_pending!, streaming: true),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('💚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PennyPal AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Financial Advisor',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Tells the student their conversation is kept, which is the point of
          // writing it to Firestore, and saves them wondering where it went.
          if (_restoring)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_messages.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Tooltip(
                message: 'This conversation is saved to your account',
                child: Icon(
                  Icons.cloud_done_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_messages.length > 1)
            IconButton(
              tooltip: 'New chat',
              onPressed: _clear,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasKey) _offlineBanner(cs),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: items.length,
              itemBuilder: (ctx, i) => items[i],
            ),
          ),
          _composer(cs),
        ],
      ),
    );
  }

  Widget _offlineBanner(ColorScheme cs) {
    return Container(
      width: double.infinity,
      color: cs.errorContainer,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.key_off_rounded, size: 16, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Groq not connected — using your local numbers only.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            GroqService.instance.configHint,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: cs.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage msg, {bool streaming = false}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isUser = msg.isUser;
    final waiting = msg.isStreaming;

    final bodyColor = isUser
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);
    final muted = isUser
        ? Colors.white70
        : (isDark ? Colors.white54 : Colors.black54);
    final codeBg = isDark ? const Color(0xFF15151F) : const Color(0xFFF1F3F5);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? cs.primary
              : (Theme.of(context).cardTheme.color ?? Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.thinking.isNotEmpty) _reasoning(msg, streaming, muted),
            if (waiting && msg.thinking.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: _ThinkingDots(),
              ),
            if (msg.text.isNotEmpty)
              if (isUser)
                Text(
                  msg.text,
                  style: TextStyle(
                    color: bodyColor,
                    height: 1.45,
                    fontSize: 14.5,
                  ),
                )
              else
                _answer(
                  msg,
                  streaming: streaming,
                  color: bodyColor,
                  codeBg: codeBg,
                ),
            if (streaming && msg.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: _BlinkingCursor(),
              ),
            if (!waiting) _footer(msg, muted),
          ],
        ),
      ),
    );
  }

  /// Markdown rendering. LLMs answer in markdown, so bold / lists / tables
  /// would otherwise show up as raw asterisks and dashes.
  Widget _answer(
    _ChatMessage msg, {
    required bool streaming,
    required Color color,
    required Color codeBg,
  }) {
    return AiMarkdown(
      data: msg.text,
      color: color,
      codeBackground: codeBg,
      onLinkTap: (href) {
        _copy(href);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Link copied: $href'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
    );
  }

  Widget _footer(_ChatMessage msg, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            msg.clock,
            style: TextStyle(fontSize: 10.5, color: muted, height: 1),
          ),
          if (!msg.isUser) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _copy(msg.text),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.copy_rounded, size: 13, color: muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Collapsible chain of thought. Auto-expands while it streams so the user
  /// sees progress, then stays collapsed once the answer lands.
  Widget _reasoning(_ChatMessage msg, bool streaming, Color muted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Flips once, when streaming ends, so the tile re-creates collapsed
          // without being rebuilt on every single token.
          key: ValueKey('reason-${msg.id}-${streaming ? 'live' : 'done'}'),
          initiallyExpanded: streaming,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 6),
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                streaming
                    ? Icons.psychology_alt_rounded
                    : Icons.psychology_outlined,
                size: 15,
                color: muted,
              ),
              const SizedBox(width: 6),
              Text(
                streaming ? 'Thinking...' : 'Reasoning',
                style: TextStyle(
                  fontSize: 11.5,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.04,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                msg.thinking,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(ColorScheme cs) {
    final listening = _voice.isListening;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.07)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (listening) _listeningStrip(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Hidden rather than shown disabled: a mic that cannot work is
                // worse than no mic, because it looks broken.
                if (_voice.isAvailable) ...[
                  _MicButton(
                    listening: listening,
                    color: cs.primary,
                    onTap: listening ? _stopVoice : _startVoice,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: listening
                          ? 'Listening...'
                          : 'Ask about budgeting, saving...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? _stop : _send,
                  child: CircleAvatar(
                    backgroundColor: _isLoading ? Colors.grey : cs.primary,
                    radius: 24,
                    child: Icon(
                      _isLoading ? Icons.stop_rounded : Icons.send_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Live feedback while the microphone is open, so a student can tell the app
  /// is hearing them rather than guessing.
  Widget _listeningStrip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white70 : AppColors.brand,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _voiceError.isEmpty
                  ? 'Listening — tap the mic again to stop'
                  : _voiceError,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: _voiceError.isEmpty
                    ? (isDark ? Colors.white60 : AppColors.textMuted)
                    : AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The microphone toggle. Sized to 44pt so it is a comfortable tap target.
class _MicButton extends StatelessWidget {
  final bool listening;
  final Color color;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: listening ? 'Stop listening' : 'Talk instead of typing',
      child: Material(
        color: listening
            ? AppColors.expense.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              listening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 21,
              color: listening ? AppColors.expense : color,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders fenced code blocks as wrapping text instead of the package default
/// of a horizontally scrollable box.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 8,
            height: 15,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.4 + 0.6 * _ctrl.value),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: scale.clamp(0.25, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
