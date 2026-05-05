import 'package:flutter/material.dart';
import '../services/ui_scale.dart';

class ShakeOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onDismiss;

  const ShakeOverlay({super.key, required this.isVisible, this.onDismiss});

  @override
  State<ShakeOverlay> createState() => _ShakeOverlayState();
}

class _ShakeOverlayState extends State<ShakeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(ShakeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
      // Auto-dismiss after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && widget.isVisible) {
          _dismiss();
        }
      });
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final ui = UiScale.of(context, designWidth: 402);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ui.s(32),
                        vertical: ui.s(16),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(ui.s(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: ui.s(10),
                            offset: Offset(0, ui.s(4)),
                          ),
                        ],
                      ),
                      child: Text(
                        'Geschüttelt!',
                        style: TextStyle(
                          fontSize: ui.s(24),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
