import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/document_providers.dart';

/// Decrypts and renders a single vault image in memory.
class EncryptedImageView extends ConsumerWidget {
  const EncryptedImageView({
    super.key,
    required this.storedPath,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String storedPath;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBytes = ref.watch(decryptedImageProvider(storedPath));
    final scheme = Theme.of(context).colorScheme;

    final child = asyncBytes.when(
      data: (bytes) => Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _BrokenPhotoPlaceholder(scheme: scheme),
      ),
      loading: () => Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, stack) => _BrokenPhotoPlaceholder(scheme: scheme),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

class _BrokenPhotoPlaceholder extends StatelessWidget {
  const _BrokenPhotoPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: scheme.outline, size: 32),
          const SizedBox(height: 4),
          Text(
            'Unable to decrypt photo',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Full-screen pinch-to-zoom viewer for a document's encrypted photos.
class EncryptedPhotoViewerScreen extends StatefulWidget {
  const EncryptedPhotoViewerScreen({
    super.key,
    required this.title,
    required this.imagePaths,
    this.initialIndex = 0,
  });

  final String title;
  final List<String> imagePaths;
  final int initialIndex;

  @override
  State<EncryptedPhotoViewerScreen> createState() =>
      _EncryptedPhotoViewerScreenState();
}

class _EncryptedPhotoViewerScreenState
    extends State<EncryptedPhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _pageLabel(int index, int total) {
    if (total == 1) return widget.title;
    const slotNames = ['Front', 'Back', 'Page 3'];
    final slot = index < slotNames.length ? slotNames[index] : 'Page ${index + 1}';
    return '$slot (${index + 1}/$total)';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.imagePaths.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_pageLabel(_index, total)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: EncryptedImageView(
                storedPath: widget.imagePaths[i],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
