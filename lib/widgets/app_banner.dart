import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppBannerType { success, error, info }

OverlayEntry? _current;
Timer? _dismissTimer;

/// Slide-down banner notification anchored to the top of the screen. Use as a
/// drop-in replacement for [ScaffoldMessenger.showSnackBar] so feedback is
/// visible above bottom sheets and the nav bar.
void showAppBanner(
  BuildContext context,
  String message, {
  AppBannerType type = AppBannerType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _current?.remove();
  _dismissTimer?.cancel();

  final entry = OverlayEntry(
    builder: (ctx) => _BannerView(message: message, type: type),
  );
  _current = entry;
  overlay.insert(entry);

  _dismissTimer = Timer(duration, () {
    _current?.remove();
    _current = null;
  });
}

class _BannerView extends StatefulWidget {
  final String message;
  final AppBannerType type;

  const _BannerView({required this.message, required this.type});

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bg {
    switch (widget.type) {
      case AppBannerType.success:
        return AppTheme.mint;
      case AppBannerType.error:
        return AppTheme.coral;
      case AppBannerType.info:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppBannerType.success:
        return Icons.check_circle_rounded;
      case AppBannerType.error:
        return Icons.error_outline_rounded;
      case AppBannerType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _bg.withOpacity(0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(_icon, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
