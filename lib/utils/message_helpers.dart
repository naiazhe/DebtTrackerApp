import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _activeMessageEntry;
Timer? _activeMessageTimer;

void _removeActiveMessage() {
  _activeMessageTimer?.cancel();
  _activeMessageTimer = null;
  _activeMessageEntry?.remove();
  _activeMessageEntry = null;
}

/// Compact top message widget that does not block the whole screen.
class _TopMessageCard extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onClose;

  const _TopMessageCard({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.textColor,
    required this.accentColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showTopMessage(
  BuildContext context,
  String message, {
  required Color backgroundColor,
  required IconData icon,
  required Color textColor,
  required Color accentColor,
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: duration,
          ),
        );
    }
    return;
  }

  _removeActiveMessage();

  final entry = OverlayEntry(
    builder: (overlayContext) {
      final mediaQuery = MediaQuery.maybeOf(overlayContext);
      final topPadding = (mediaQuery?.padding.top ?? 0) + 10;

      return Positioned(
        top: topPadding,
        left: 12,
        right: 12,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -28, end: 0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          builder: (context, offsetY, child) {
            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Opacity(
                opacity: ((28 + offsetY) / 28).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: _TopMessageCard(
            message: message,
            backgroundColor: backgroundColor,
            icon: icon,
            textColor: textColor,
            accentColor: accentColor,
            onClose: _removeActiveMessage,
          ),
        ),
      );
    },
  );

  _activeMessageEntry = entry;
  overlay.insert(entry);

  _activeMessageTimer = Timer(duration, _removeActiveMessage);
}

/// Shows a success message at the top of the screen
void showSuccessMessage(BuildContext context, String message) {
  _showTopMessage(
    context,
    message,
    backgroundColor: const Color(0xFFEAF8EF),
    icon: Icons.check_circle_outline,
    textColor: const Color(0xFF1B5E20),
    accentColor: const Color(0xFF2E7D32),
  );
}

/// Shows an error message at the top of the screen
void showErrorMessage(BuildContext context, String message) {
  _showTopMessage(
    context,
    message,
    backgroundColor: const Color(0xFFFDECEA),
    icon: Icons.error_outline,
    textColor: const Color(0xFFB71C1C),
    accentColor: const Color(0xFFD32F2F),
  );
}

/// Shows an info message at the top of the screen
void showInfoMessage(BuildContext context, String message) {
  _showTopMessage(
    context,
    message,
    backgroundColor: const Color(0xFFE6F1F6),
    icon: Icons.info_outline,
    textColor: const Color(0xFF005B88),
    accentColor: const Color(0xFF0070A8),
  );
}
