import 'package:flutter/material.dart';

void showOverlayNotification(
  BuildContext context, {
  required Widget child,
  required VoidCallback onTapNotification,
  Duration notificationDuration = const Duration(seconds: 3),
  EdgeInsets edgeInsets = const EdgeInsets.all(8.0),
  Alignment alignment = Alignment.topCenter,
  Color? surfaceTintColor,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _OverlayWidget(
      duration: notificationDuration,
      onEnd: () => overlayEntry.remove(),
      edgeInsets: edgeInsets,
      alignment: alignment,
      surfaceTintColor: surfaceTintColor,
      onTapNotification: onTapNotification,
      child: child,
    ),
  );

  overlay.insert(overlayEntry);
}

class _OverlayWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final VoidCallback onEnd;
  final VoidCallback onTapNotification;

  final EdgeInsets edgeInsets;
  final Alignment alignment;
  final Color? surfaceTintColor;

  const _OverlayWidget({
    required this.child,
    required this.duration,
    required this.onEnd,
    required this.onTapNotification,
    required this.edgeInsets,
    required this.alignment,
    this.surfaceTintColor,
  });

  @override
  __OverlayWidgetState createState() => __OverlayWidgetState();
}

class __OverlayWidgetState extends State<_OverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _removeNotification();
      }
    });
  }

  void _removeNotification() {
    if (mounted) {
      _animationController.reverse().then((_) {
        if (mounted) {
          widget.onEnd();
        }
      });
    }
  }

  void _handleNotificationTap() {
    widget.onTapNotification();
    _removeNotification();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: widget.edgeInsets,
          child: Align(
            alignment: widget.alignment,
            child: Material(
              surfaceTintColor: widget.surfaceTintColor,
              borderRadius: BorderRadius.circular(20),
              elevation: 3,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _handleNotificationTap,
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.child,
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _removeNotification,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
