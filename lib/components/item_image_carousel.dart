import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import 'stored_image.dart';

class ItemImageCarousel extends StatefulWidget {
  const ItemImageCarousel({super.key, required this.item});

  final InventoryItem item;

  @override
  State<ItemImageCarousel> createState() => _ItemImageCarouselState();
}

class _ItemImageCarouselState extends State<ItemImageCarousel> {
  int _index = 0;
  late PageController _controller;
  Timer? _autoPlayTimer;

  List<String> get _images => widget.item.imagePaths;

  int get _initialPage => _images.length > 1 ? _images.length * 1000 : 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAutoPlay();
  }

  @override
  void didUpdateWidget(covariant ItemImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imagePaths.join('|') != _images.join('|')) {
      _autoPlayTimer?.cancel();
      _controller.dispose();
      _index = 0;
      _controller = PageController(initialPage: _initialPage);
      _scheduleAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_images.length < 2 || !mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _autoPlayTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: SizedBox.expand(
          child: Image.asset(
            widget.item.categoryInfo.asset,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) {
                setState(() => _index = value % images.length);
                _scheduleAutoPlay();
              },
              itemBuilder: (context, index) {
                final imageIndex = index % images.length;
                return GestureDetector(
                  onTap: () => _preview(images, imageIndex),
                  child: _GalleryImage(path: images[imageIndex]),
                );
              },
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${images.length}',
                    key: const Key('item-gallery-indicator'),
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _preview(List<String> images, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: _GalleryImage(
                    path: images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: MediaQuery.paddingOf(context).top + 10,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: StoredImage(
        path: path,
        fit: fit,
        fallback: const SizedBox.shrink(),
      ),
    );
  }
}
