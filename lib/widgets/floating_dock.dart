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
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat Tab
                _DockItem(
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  isSelected: selectedIndex == 0,
                  onTap: () => onDestinationSelected(0),
                  tooltip: 'Conversation',
                ),
                
                const SizedBox(width: 12),

                // Center Action Button
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCenterAction,
                      borderRadius: BorderRadius.circular(24),
                      child: IconTheme(
                        data: IconThemeData(
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                        child: centerIcon,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Knowledge Tab
                _DockItem(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  selectedIcon: Icons.auto_awesome_mosaic,
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
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected 
                    ? colorScheme.secondaryContainer.withOpacity(0.5) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected 
                    ? colorScheme.onSecondaryContainer 
                    : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
