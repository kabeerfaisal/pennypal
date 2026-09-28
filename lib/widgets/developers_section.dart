import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Developer {
  final String name;
  final String role;
  final String github;
  final String linkedin;

  const Developer({
    required this.name,
    required this.role,
    required this.github,
    required this.linkedin,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

const List<Developer> kDevelopers = [
  Developer(
    name: 'Muhammad Hashir Edhi',
    role: 'Developer',
    github: 'https://github.com/hashir-build',
    linkedin: 'https://www.linkedin.com/in/muhammad-hashir-247850348/',
  ),
  Developer(
    name: 'Abdul Kabeer',
    role: 'Developer',
    github: 'https://github.com/kabeerfaisal',
    linkedin: 'https://www.linkedin.com/in/kabeersaudagar/',
  ),
  Developer(
    name: 'Muhammad Saad',
    role: 'Developer',
    github: 'https://github.com/MSaad2408b',
    linkedin: 'https://www.linkedin.com/in/muhammad-saad-8a8249340/',
  ),
];

const String kInstitution = 'APTECH GARDEN STUDENTS';

/// Developer credits with tappable GitHub and LinkedIn links.
class DevelopersSection extends StatelessWidget {
  final Color accent;

  const DevelopersSection({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              const Icon(Icons.groups_rounded, size: 34),
              const SizedBox(height: 6),
              Text(
                'Developed by',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kInstitution,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final dev in kDevelopers) ...[
          _DeveloperCard(dev: dev, accent: accent),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final Developer dev;
  final Color accent;

  const _DeveloperCard({required this.dev, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: Text(
                dev.initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accent,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dev.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dev.role,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _LinkButton(
              key: ValueKey('dev-github-${dev.name}'),
              painter: const _GitHubMark(),
              tooltip: 'GitHub',
              color: const Color(0xFF24292F),
              onTap: () => _open(context, dev.github, 'GitHub'),
            ),
            const SizedBox(width: 6),
            _LinkButton(
              key: ValueKey('dev-linkedin-${dev.name}'),
              painter: const _LinkedInMark(),
              tooltip: 'LinkedIn',
              color: const Color(0xFF0A66C2),
              onTap: () => _open(context, dev.linkedin, 'LinkedIn'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url, String label) async {
    // Captured before the await so the async gap cannot outlive the element.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _fail(messenger, 'Invalid $label address');
      return;
    }
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) _fail(messenger, 'Could not open $label');
  }

  void _fail(ScaffoldMessengerState? messenger, String message) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}

class _LinkButton extends StatelessWidget {
  final CustomPainter painter;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _LinkButton({
    super.key,
    required this.painter,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(painter: painter),
          ),
        ),
      ),
    );
  }
}

/// GitHub mark drawn directly so no icon font dependency is needed.
class _GitHubMark extends CustomPainter {
  const _GitHubMark();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s);

    // Octocat body.
    final body = Path()
      ..moveTo(12, 2)
      ..cubicTo(6.48, 2, 2, 6.58, 2, 12.25)
      ..cubicTo(2, 16.9, 4.87, 20.92, 8.8, 22.23)
      ..cubicTo(9.33, 22.32, 9.5, 21.92, 9.5, 21.57)
      ..lineTo(9.5, 19.9)
      ..cubicTo(6.9, 20.4, 6.33, 18.6, 6.33, 18.6)
      ..cubicTo(5.9, 17.5, 5.03, 17.28, 5.03, 17.28)
      ..cubicTo(3.92, 16.87, 5.07, 16.88, 5.07, 16.88)
      ..cubicTo(6.28, 16.97, 6.95, 18.15, 6.95, 18.15)
      ..cubicTo(7.95, 19.85, 9.5, 19.23, 10.02, 18.87)
      ..cubicTo(10.15, 18.36, 10.42, 18.02, 10.72, 17.82)
      ..cubicTo(8.35, 17.52, 5.9, 16.62, 5.9, 12.42)
      ..cubicTo(5.9, 11.4, 6.23, 10.53, 6.78, 9.87)
      ..cubicTo(6.7, 9.5, 6.5, 8.55, 6.87, 7.32)
      ..cubicTo(7.24, 7.08, 8.4, 7.4, 8.4, 7.4)
      ..cubicTo(9.62, 7.33, 10.87, 7.3, 12.1, 7.3)
      ..cubicTo(13.33, 7.3, 14.57, 7.33, 15.8, 7.4)
      ..cubicTo(15.8, 7.4, 16.97, 7.07, 17.34, 7.32)
      ..cubicTo(17.7, 8.55, 17.5, 9.5, 17.42, 9.87)
      ..cubicTo(17.98, 10.54, 18.3, 11.4, 18.3, 12.42)
      ..cubicTo(18.3, 16.63, 15.84, 17.51, 13.46, 17.8)
      ..cubicTo(13.84, 18.2, 14.15, 18.87, 14.15, 19.72)
      ..lineTo(14.15, 21.57)
      ..cubicTo(14.15, 21.93, 14.32, 22.33, 14.86, 22.23)
      ..cubicTo(18.8, 20.91, 21.63, 16.9, 21.63, 12.25)
      ..cubicTo(21.63, 6.58, 17.15, 2, 12, 2)
      ..close();
    // Punch the eyes and the smile out of the silhouette so the mark reads
    // as GitHub rather than a blob.
    final eyes = Path()
      ..addOval(Rect.fromCircle(center: const Offset(8.6, 12.4), radius: 1.35))
      ..addOval(Rect.fromCircle(center: const Offset(15.4, 12.4), radius: 1.35))
      ..addArc(
        Rect.fromCircle(center: const Offset(12, 14.4), radius: 3.4),
        0.35,
        2.44,
      );

    canvas.drawPath(Path.combine(PathOperation.difference, body, eyes), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// LinkedIn mark drawn directly.
class _LinkedInMark extends CustomPainter {
  const _LinkedInMark();

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white;
    final s = size.width / 24;
    canvas.save();
    canvas.scale(s);

    // Rounded square with an "in" cut out, so it reads at small sizes.
    final r = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 1, 22, 22),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(r, white);

    final cut = Paint()
      ..color = const Color(0xFF0A66C2)
      ..blendMode = BlendMode.srcOver;
    canvas.drawCircle(const Offset(6.2, 6.4), 1.7, cut);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4.9, 9.2, 2.6, 10.2),
        const Radius.circular(1.3),
      ),
      cut,
    );
    canvas.drawCircle(const Offset(11.4, 11.9), 1.75, cut);
    canvas.drawPath(
      Path()
        ..moveTo(10.4, 9.2)
        ..lineTo(10.4, 19.4)
        ..lineTo(13, 19.4)
        ..lineTo(13, 14.6)
        ..cubicTo(13, 13.3, 13.4, 12.4, 14.7, 12.4)
        ..cubicTo(16.1, 12.4, 16.4, 13.5, 16.4, 14.8)
        ..lineTo(16.4, 19.4)
        ..lineTo(19, 19.4)
        ..lineTo(19, 14.3)
        ..cubicTo(19, 11.6, 17.8, 9.0, 14.9, 9.0)
        ..cubicTo(13.4, 9.0, 12.5, 9.7, 12.1, 10.3)
        ..lineTo(12.1, 9.2)
        ..close(),
      cut,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
