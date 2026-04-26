import 'package:flutter/material.dart';

import '../theme/edubridge_colors.dart';

class DashboardEntrance extends StatefulWidget {
  const DashboardEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 380,
    this.offsetY = 14,
  });

  final Widget child;
  final int delayMs;
  final int durationMs;
  final double offsetY;

  @override
  State<DashboardEntrance> createState() => _DashboardEntranceState();
}

class _DashboardEntranceState extends State<DashboardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.durationMs),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offsetY / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class DashboardPressable extends StatefulWidget {
  const DashboardPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<DashboardPressable> createState() => _DashboardPressableState();
}

class _DashboardPressableState extends State<DashboardPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) {
      // Ne pas intercepter les gestes si aucune action n'est fournie.
      // Cela évite de bloquer le scroll/clic dans les grilles dashboard.
      return widget.child;
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? widget.scaleDown : 1,
        child: widget.child,
      ),
    );
  }
}

class DashboardHoverCard extends StatefulWidget {
  const DashboardHoverCard({
    super.key,
    required this.child,
    this.baseShadows = const [],
    this.hoverShadows = const [],
  });

  final Widget child;
  final List<BoxShadow> baseShadows;
  final List<BoxShadow> hoverShadows;

  @override
  State<DashboardHoverCard> createState() => _DashboardHoverCardState();
}

class _DashboardHoverCardState extends State<DashboardHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktopLike = {
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    }.contains(Theme.of(context).platform);
    if (!isDesktopLike) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        scale: _hovered ? 1.01 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hovered ? widget.hoverShadows : widget.baseShadows,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class DashboardPulseBadge extends StatefulWidget {
  const DashboardPulseBadge({
    super.key,
    required this.value,
    this.color = EduBridgeColors.error,
  });

  final int value;
  final Color color;

  @override
  State<DashboardPulseBadge> createState() => _DashboardPulseBadgeState();
}

class _DashboardPulseBadgeState extends State<DashboardPulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value <= 0) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.85 + (_controller.value * 0.25);
        return Transform.scale(scale: pulse, child: child);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${widget.value}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class DashboardAnimatedSwitcher extends StatelessWidget {
  const DashboardAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(fade);
        return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
      },
      child: KeyedSubtree(
        key: ValueKey(child.hashCode),
        child: child,
      ),
    );
  }
}
