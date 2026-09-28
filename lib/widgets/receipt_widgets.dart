import 'package:flutter/material.dart';

import '../services/receipt_service.dart';

/// The receipt attachment field on the add/edit transaction form.
///
/// Extracted from the screen so the three visual states (empty, preparing,
/// attached) can be tested without standing up Firebase.
class ReceiptPickerField extends StatelessWidget {
  final String receiptData;
  final bool preparing;
  final Color accent;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const ReceiptPickerField({
    super.key,
    required this.receiptData,
    required this.preparing,
    required this.accent,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Receipt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Text(
              'optional',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (preparing)
          const _PreparingBox()
        else if (receiptData.isNotEmpty)
          _AttachedPreview(data: receiptData, onRemove: onRemove)
        else
          OutlinedButton.icon(
            onPressed: onPick,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: accent.withValues(alpha: 0.4)),
            ),
            icon: Icon(Icons.add_a_photo_outlined, color: accent),
            label: Text(
              'Add receipt photo',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _PreparingBox extends StatelessWidget {
  const _PreparingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Preparing receipt...')),
        ],
      ),
    );
  }
}

class _AttachedPreview extends StatelessWidget {
  final String data;
  final VoidCallback onRemove;

  const _AttachedPreview({required this.data, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final bytes = ReceiptService.decode(data);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: bytes == null
              ? Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.05),
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                )
              : Image.memory(
                  bytes,
                  width: double.infinity,
                  height: 170,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
        if (bytes != null)
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ReceiptService.readableSize(bytes.length),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small receipt preview for a transaction card, falling back to the category
/// icon when the transaction has no receipt.
class ReceiptThumb extends StatelessWidget {
  final String data;
  final Color color;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  const ReceiptThumb({
    super.key,
    required this.data,
    required this.color,
    required this.fallbackIcon,
    this.onTap,
  });

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final bytes = ReceiptService.decode(data);
    if (bytes == null) {
      return CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(fallbackIcon, color: color),
      );
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, _, _) => Container(
          width: size,
          height: size,
          color: color.withValues(alpha: 0.12),
          child: Icon(Icons.broken_image_outlined, size: 18, color: color),
        ),
      ),
    );

    if (onTap == null) return image;
    return GestureDetector(onTap: onTap, child: image);
  }
}
