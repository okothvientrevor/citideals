import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// App-wide network image. Caches to disk, shows a shimmer while loading, and
/// adds Cloudinary `f_auto,q_auto[,w_…]` transforms to URLs that don't already
/// have them so payloads are much smaller on the wire.
class CachedImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? targetWidth;
  final BorderRadius? borderRadius;
  final Widget? errorPlaceholder;

  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.targetWidth,
    this.borderRadius,
    this.errorPlaceholder,
  });

  String? _optimized(String? src) {
    if (src == null || src.isEmpty) return null;
    if (!src.contains('res.cloudinary.com')) return src;
    if (!src.contains('/upload/')) return src;
    if (src.contains('/upload/f_auto') ||
        src.contains('/upload/q_auto') ||
        src.contains(',f_auto') ||
        src.contains(',q_auto')) {
      return src;
    }
    final transform = targetWidth != null
        ? 'f_auto,q_auto,w_$targetWidth'
        : 'f_auto,q_auto';
    return src.replaceFirst('/upload/', '/upload/$transform/');
  }

  Widget _placeholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE6ECFA),
      highlightColor: isDark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFF4F7FF),
      child: Container(
        width: width,
        height: height,
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE6ECFA),
      ),
    );
  }

  Widget _error(BuildContext context) {
    if (errorPlaceholder != null) return errorPlaceholder!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF1A1A1A) : AppTheme.lightMuted,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: isDark ? Colors.white24 : Colors.black26,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _optimized(url);
    Widget child;
    if (resolved == null || resolved.isEmpty) {
      child = _error(context);
    } else {
      child = CachedNetworkImage(
        imageUrl: resolved,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: targetWidth != null
            ? (targetWidth! * MediaQuery.of(context).devicePixelRatio).round()
            : null,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (ctx, _) => _placeholder(ctx),
        errorWidget: (ctx, _, __) => _error(ctx),
      );
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
