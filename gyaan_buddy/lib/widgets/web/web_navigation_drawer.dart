import 'package:flutter/material.dart';
import '../../services/vibration_service.dart';

/// Navigation item model for web drawer
class WebNavigationItem {
  final String imagePath;
  final String label;
  final IconData? icon;
  final double? size;

  WebNavigationItem({
    required this.imagePath,
    required this.label,
    this.icon,
    this.size,
  });
}

/// Web-specific navigation drawer with modern design
class WebNavigationDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<WebNavigationItem> items;
  final String? userName;
  final String? userInitial;
  final String? classLabel;

  const WebNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.userName,
    this.userInitial,
    this.classLabel,
  });

  @override
  State<WebNavigationDrawer> createState() => _WebNavigationDrawerState();
}

class _WebNavigationDrawerState extends State<WebNavigationDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Brand Header
          _buildHeader(),
          const SizedBox(height: 20),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index, widget.items[index]);
              },
            ),
          ),

          // User Profile Section at bottom
          if (widget.userName != null) _buildUserSection(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF365DEA).withOpacity(0.3),
            const Color(0xFF1A1D29),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          'assets/images/gyan_buddy_light.png',
          width: 190,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'GyanBuddy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, WebNavigationItem item) {
    final isSelected = index == widget.selectedIndex;
    final isHovered = index == _hoveredIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = -1),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            await VibrationService().navigationVibration();
            // await SoundService().playButtonClick();
            widget.onItemSelected(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF365DEA),
                        Color(0xFF5B7AFF),
                      ],
                    )
                  : null,
              color: !isSelected && isHovered
                  ? Colors.white.withOpacity(0.08)
                  : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF365DEA).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Icon/Image
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: item.size ?? 40,
                  child: item.icon != null
                      ? Icon(
                          item.icon,
                          size: item.size ?? 40,
                          color: isSelected
                              ? Colors.white
                              : isHovered
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.6),
                        )
                      : Image.asset(
                          item.imagePath,
                          fit: BoxFit.contain,
                          color: isSelected
                              ? Colors.white
                              : isHovered
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.6),
                        ),
                ),
                const SizedBox(width: 8),
                // Label
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isHovered
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                    child: Text(item.label),
                  ),
                ),
                // Selection indicator
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF27AE60),
                  Color(0xFF2ECC71),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF27AE60).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.userInitial ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'Student',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (widget.classLabel != null && widget.classLabel!.isNotEmpty)
                  Text(
                    widget.classLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
