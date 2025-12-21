import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/app/controllers/home_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:music_player/app/ui/theme/app_colors.dart';

/// Optimized cached album artwork widget
/// Replaces FutureBuilder pattern which causes performance issues on low-end devices
///
/// This widget:
/// - Uses cached image data to avoid async operations during build
/// - Prevents FutureBuilder rebuild cycles
/// - Reduces memory usage with proper image resolution limits
/// - Works with both local and network images
class CachedAlbumArtwork extends StatefulWidget {
  final int songId;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool highQuality;
  final BoxFit fit;

  const CachedAlbumArtwork({
    super.key,
    required this.songId,
    this.width,
    this.height,
    this.borderRadius = 15,
    this.highQuality = false,
    this.fit = BoxFit.cover,
  });

  @override
  State<CachedAlbumArtwork> createState() => _CachedAlbumArtworkState();
}

class _CachedAlbumArtworkState extends State<CachedAlbumArtwork> {
  Uint8List? _cachedImage;
  bool _isLoading = true;
  String? _artworkUrl;

  // Resolution limits for performance
  // Lower resolution = faster decoding and rendering on low-end devices
  // Reduced significantly for low-end devices (Xiaomi 8 SE has weak GPU)
  static const int _listImageSize = 120; // Further reduced for low-end devices
  static const int _highQualitySize = 800; // Reduced for better performance

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedAlbumArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if songId changed
    if (oldWidget.songId != widget.songId) {
      _cachedImage = null;
      _isLoading = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    try {
      final controller = Get.find<HomeController>();

      // Check if artwork URL is available (for downloaded songs)
      // final artworkUrl = controller.getArtworkUrl(widget.songId);

      // if (artworkUrl != null) {
      //   // Network image available
      //   if (mounted) {
      //     setState(() {
      //       _artworkUrl = artworkUrl;
      //       _isLoading = false;
      //     });
      //   }
      //   return;
      // }

      // Load from service (async but only once per song)
      // The controller's getAlbumArtwork already handles caching internally
      final artwork = await controller.getAlbumArtwork(
        widget.songId,
        // highQuality: widget.highQuality,
      );

      if (mounted && artwork != null) {
        setState(() {
          _cachedImage = artwork;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [TpsColors.musicPrimary, TpsColors.musicSecondary],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 35,
      ),
    );
  }

  /// Optimized build method that prevents unnecessary rebuilds
  @override
  Widget build(BuildContext context) {
    // Show placeholder while loading or if no image
    if (_isLoading || (_cachedImage == null && _artworkUrl == null)) {
      return _buildPlaceholder();
    }

    // Use network image if available
    if (_artworkUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: CachedNetworkImage(
          imageUrl: _artworkUrl!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          // Use lower resolution for better performance on low-end devices
          memCacheWidth: widget.highQuality ? _highQualitySize : _listImageSize,
          memCacheHeight:
              widget.highQuality ? _highQualitySize : _listImageSize,
          // Use low filter quality for faster rendering on low-end devices
          filterQuality: FilterQuality.low, // Changed from high for performance
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      );
    }

    // Use cached memory image
    if (_cachedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.memory(
          _cachedImage!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          // Use lower resolution for better performance
          cacheWidth: widget.highQuality ? _highQualitySize : _listImageSize,
          cacheHeight: widget.highQuality ? _highQualitySize : _listImageSize,
          // Use low filter quality for faster rendering on low-end devices
          filterQuality: FilterQuality.low, // Changed from high for performance
        ),
      );
    }

    return _buildPlaceholder();
  }
}
