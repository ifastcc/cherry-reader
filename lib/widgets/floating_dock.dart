import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onCenterAction;
  final Widget centerIcon;

  const FloatingDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onCenterAction,
    this.centerIcon = const Icon(Icons.add),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40), // More rounded pill
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Stronger blur
          child: Container(
            height: 72, // Slightly taller for better touch targets
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.75), // More translucent
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.08), // Very subtle border
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat Tab
                _DockItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  selectedIcon: Icons.chat_bubble_rounded,
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                  tooltip: 'Conversation',
                ),
                
                const SizedBox(width: 16),

                // Center Action Button
                _CenterButton(
                  onTap: onCenterAction,
                  icon: centerIcon,
                ),

                const SizedBox(width: 16),

                // Knowledge Tab
                _DockItem(
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  isSelected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                  tooltip: 'Knowledge',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget icon;

  const _CenterButton({
    required this.onTap,
    required this.icon,
  });

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.tertiary, // Vibrant gradient
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(-2, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: colorScheme.onPrimary,
                size: 26,
              ),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primaryContainer.withValues(alpha: 0.2) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18), // Soft squircle
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
