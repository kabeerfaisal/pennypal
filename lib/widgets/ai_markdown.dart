import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// Renders an AI reply as markdown, themed for a chat bubble.
///
/// Exists as its own widget so the markdown layout can be tested without
/// standing up Firebase, which the chat screen depends on.
class AiMarkdown extends StatelessWidget {
  final String data;
  final Color color;
  final Color codeBackground;
  final ValueChanged<String>? onLinkTap;

  const AiMarkdown({
    super.key,
    required this.data,
    required this.color,
    required this.codeBackground,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: TextStyle(color: color, fontSize: 14.5, height: 1.5),
      listBullet: TextStyle(color: color, fontSize: 14.5),
      h1: TextStyle(
        color: color,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h2: TextStyle(
        color: color,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      h3: TextStyle(
        color: color,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      em: TextStyle(color: color, fontStyle: FontStyle.italic),
      strong: TextStyle(color: color, fontWeight: FontWeight.w700),
      a: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
      code: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: codeBackground,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      tableBorder: TableBorder.all(color: Colors.black12),
      tableHead: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
      ),
      tableBody: TextStyle(color: color, fontSize: 13.5),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      // blockSpacing also separates list items, so keep it small and give
      // headings their breathing room through padding instead.
      blockSpacing: 4,
      listIndent: 20,
      listBulletPadding: const EdgeInsets.only(right: 2),
      pPadding: const EdgeInsets.only(top: 2),
      h1Padding: const EdgeInsets.only(top: 14),
      h2Padding: const EdgeInsets.only(top: 14),
      h3Padding: const EdgeInsets.only(top: 12),
    );

    return MarkdownBody(
      data: data,
      selectable: true,
      // LLMs separate list lines with one newline, not a blank line, so plain
      // line breaks have to be honoured.
      softLineBreak: true,
      shrinkWrap: true,
      styleSheet: sheet,
      onTapLink: (text, href, title) {
        if (href != null) onLinkTap?.call(href);
      },
      builders: {'pre': _WrappingCodeBlock(color: color)},
    );
  }
}

/// Renders fenced code blocks as wrapping text rather than the package default
/// of a horizontally scrollable box, which fights with the chat ListView.
class _WrappingCodeBlock extends MarkdownElementBuilder {
  final Color color;
  _WrappingCodeBlock({required this.color});

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    // MarkdownBody pins fitContent to true, so block children are laid out
    // with a start alignment and would otherwise shrink-wrap. Claiming the
    // full width keeps the code block flush with the rest of the bubble.
    return SizedBox(
      width: double.infinity,
      child: Text(
        text.text.trimRight(),
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }
}
