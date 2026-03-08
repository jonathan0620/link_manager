import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ToastHelper {
  ToastHelper._();

  static OverlayEntry? _currentOverlay;

  /// Show centered toast notification
  static void showSuccess(String message, {BuildContext? context}) {
    if (context != null) {
      _showCenteredToast(context, message, isError: false);
    }
  }

  static void showError(String message, {BuildContext? context}) {
    if (context != null) {
      _showCenteredToast(context, message, isError: true);
    }
  }

  static void showInfo(String message, {BuildContext? context}) {
    if (context != null) {
      _showCenteredToast(context, message, isError: false);
    }
  }

  /// Show custom centered toast
  static void _showCenteredToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Remove existing overlay if any
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => _CenteredToast(
        message: message,
        isError: isError,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  /// Show centered snackbar (for web compatibility)
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _showCenteredToast(context, message, isError: isError);
  }
}

class _CenteredToast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _CenteredToast({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_CenteredToast> createState() => _CenteredToastState();
}

class _CenteredToastState extends State<_CenteredToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError ? Icons.error : Icons.check_circle,
                      color: widget.isError ? AppColors.error : AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
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
    );
  }
}
