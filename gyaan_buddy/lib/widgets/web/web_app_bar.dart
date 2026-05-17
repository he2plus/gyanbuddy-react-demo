import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import '../../services/vibration_service.dart';
import '../../services/sound_service.dart';

/// Web-specific app bar with breadcrumbs, search, and user actions
class WebAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<String>? breadcrumbs;
  final VoidCallback? onMenuPressed;
  final bool showSearch;
  final Widget? trailing;

  const WebAppBar({
    super.key,
    required this.title,
    this.breadcrumbs,
    this.onMenuPressed,
    this.showSearch = true,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mobile menu toggle (for tablet/small desktop)
          if (onMenuPressed != null)
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu, size: 24),
              color: Colors.grey[700],
              splashRadius: 20,
            ),

          // Breadcrumbs or Title
          Expanded(
            child: _buildTitleSection(),
          ),

          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    if (breadcrumbs != null && breadcrumbs!.isNotEmpty) {
      return Row(
        children: [
          for (int i = 0; i < breadcrumbs!.length; i++) ...[
            if (i > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ),
            ],
            Text(
              breadcrumbs![i],
              style: TextStyle(
                fontSize: i == breadcrumbs!.length - 1 ? 18 : 14,
                fontWeight: i == breadcrumbs!.length - 1
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: i == breadcrumbs!.length - 1
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ],
        ],
      );
    }
    
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 280,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search subjects, topics...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await VibrationService().lightVibration();
          // await SoundService().playButtonClick();
          Navigator.of(context).pushNamed('/notifications');
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: Colors.grey[700],
                ),
              ),
              // Notification badge
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE74C3C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        String userName = 'Student';
        String userInitial = 'S';
        
        if (state is UserAuthenticated) {
          userName = state.user.firstName.isNotEmpty
              ? state.user.firstName
              : state.user.username;
          userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';
        }
        
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF27AE60),
                        Color(0xFF2ECC71),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

