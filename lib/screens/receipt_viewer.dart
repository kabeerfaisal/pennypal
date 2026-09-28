import 'package:flutter/material.dart';

import '../services/receipt_service.dart';

/// Full screen, pinch to zoom view of a receipt image.
class ReceiptViewer extends StatelessWidget {
  final String data;
  final String title;

  const ReceiptViewer({super.key, required this.data, this.title = 'Receipt'});

  @override
  Widget build(BuildContext context) {
    final bytes = ReceiptService.decode(data);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      body: Center(
        child: bytes == null
            ? const _Broken()
            : InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, _, _) => const _Broken(),
                ),
              ),
      ),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: Colors.white70, size: 56),
        SizedBox(height: 12),
        Text(
          'Could not load this receipt',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}
