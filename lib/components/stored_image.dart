import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../storage/local_image_store.dart';

class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.path,
    required this.fit,
    required this.fallback,
    this.cacheWidth,
  });

  final String path;
  final BoxFit fit;
  final Widget fallback;
  final int? cacheWidth;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  static const _maxCachedImages = 64;
  static final LinkedHashMap<String, Uint8List> _byteCache = LinkedHashMap();

  Future<Uint8List?>? _localBytes;

  @override
  void initState() {
    super.initState();
    _prepareLocalImage();
  }

  @override
  void didUpdateWidget(covariant StoredImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _prepareLocalImage();
  }

  void _prepareLocalImage() {
    final clean = widget.path.trim();
    _localBytes = _isLocalPath(clean) ? _loadBytes(clean) : null;
  }

  bool _isLocalPath(String path) {
    return path.isNotEmpty &&
        !path.startsWith('http://') &&
        !path.startsWith('https://') &&
        !path.startsWith('blob:') &&
        !path.startsWith('assets/') &&
        !path.startsWith('static/');
  }

  Future<Uint8List?> _loadBytes(String path) async {
    final cached = _byteCache.remove(path);
    if (cached != null) {
      _byteCache[path] = cached;
      return cached;
    }
    final bytes = await LocalImageStore.instance.load(path);
    if (bytes != null) {
      _byteCache[path] = bytes;
      while (_byteCache.length > _maxCachedImages) {
        _byteCache.remove(_byteCache.keys.first);
      }
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final clean = widget.path.trim();
    if (clean.isEmpty) return widget.fallback;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    }
    if (clean.startsWith('blob:')) {
      return Image.network(
        clean,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    }
    if (clean.startsWith('assets/') || clean.startsWith('static/')) {
      return Image.asset(clean, fit: widget.fit);
    }
    return FutureBuilder(
      future: _localBytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(
          bytes,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}
