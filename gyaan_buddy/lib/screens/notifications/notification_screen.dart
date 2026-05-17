import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../utils/web_size_utils.dart';
import '../../widgets/smooth_scroll_wrapper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  // Circle animation controllers
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  late Animation<double> _circle1Animation;
  late Animation<double> _circle2Animation;
  late Animation<double> _circle3Animation;

  // Base color for the background
  final Color _baseColor = const Color(0xFF4A90E2); // Blue color

  // Helper function to create light/pastel versions of color for gradients
  List<Color> _getGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.05) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.1) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.2) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Colors.white,
    ];
  }

  List<Color> _getBottomGradientColors(Color baseColor) {
    return [
      Colors.white,
      Color.lerp(Colors.white, baseColor, 0.15) ?? Colors.white,
      Color.lerp(Colors.white, baseColor, 0.25) ?? Colors.white,
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Initialize circle animation controllers
    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _circle1Animation = Tween<double>(
      begin: -20.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _circle1Controller,
      curve: Curves.easeInOut,
    ));

    _circle2Animation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _circle2Controller,
      curve: Curves.easeInOut,
    ));

    _circle3Animation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationService().getStoredNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
      await NotificationService().markNotificationAsRead(notification.id);
    }
  }

  Future<void> _deleteNotification(NotificationItem notification) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
    await NotificationService().deleteNotification(notification.id);
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _notifications.clear();
    });
    await NotificationService().clearAllNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final topGradientColors = _getGradientColors(_baseColor);
    final bottomGradientColors = _getBottomGradientColors(_baseColor);

    return Scaffold(
      body: Stack(
        children: [
          // White base background
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
          // Top gradient (1/4 of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kIsWeb ? 200 : 0.25.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: topGradientColors,
                  stops: const [0.0, 0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0],
                ),
              ),
            ),
          ),
          // Bottom gradient (1/3 of screen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kIsWeb ? 250 : 0.33.sh,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bottomGradientColors,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Circular shapes overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  // Large circle in top right
                  AnimatedBuilder(
                    animation: _circle1Animation,
                    builder: (context, child) {
                      return Positioned(
                        top: -100 + _circle1Animation.value,
                        right: -100,
                        child: Container(
                          width: WebSize.width(context, 300),
                          height: WebSize.width(context, 300),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _baseColor.withOpacity(0.15),
                          ),
                        ),
                      );
                    },
                  ),
                  // Small circle in upper left
                  AnimatedBuilder(
                    animation: _circle2Animation,
                    builder: (context, child) {
                      return Positioned(
                        top: 240 + _circle2Animation.value,
                        left: 40,
                        child: Container(
                          width: WebSize.width(context, 120),
                          height: WebSize.width(context, 120),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _baseColor.withOpacity(0.25),
                          ),
                        ),
                      );
                    },
                  ),
                  // Small circle in lower right
                  AnimatedBuilder(
                    animation: _circle3Animation,
                    builder: (context, child) {
                      return Positioned(
                        bottom: 240 - _circle3Animation.value,
                        right: 20,
                        child: Container(
                          width: WebSize.width(context, 50),
                          height: WebSize.width(context, 50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _baseColor.withOpacity(0.25),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 20 : 20.w,
        vertical: kIsWeb ? 16 : 16.h,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(kIsWeb ? 8 : 8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: kIsWeb ? 24 : 24.sp,
              ),
            ),
          ),
          SizedBox(width: kIsWeb ? 16 : 16.w),
          // Title
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: kIsWeb ? 24 : 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Clear all button
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.black87,
                size: kIsWeb ? 24 : 24.sp,
              ),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return SmoothScrollOverlay(
      showTopFade: true,
      showBottomFade: true,
      fadeHeight: kIsWeb ? 40 : 40.h,
      fadeColor: Colors.white,
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
          physics: const BouncingScrollPhysics(),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            return _buildNotificationCard(notification, index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: kIsWeb ? 80 : 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: kIsWeb ? 16 : 16.h),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: kIsWeb ? 24 : 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: kIsWeb ? 8 : 8.h),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: kIsWeb ? 16 : 16.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: kIsWeb ? 32 : 32.h),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _baseColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 24 : 24.w,
                vertical: kIsWeb ? 12 : 12.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kIsWeb ? 24 : 24.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: EdgeInsets.only(bottom: kIsWeb ? 12 : 12.h),
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
          child: Container(
            padding: EdgeInsets.all(kIsWeb ? 16 : 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
              color: notification.isRead ? Colors.white : _baseColor.withOpacity(0.05),
              border: notification.isRead
                  ? null
                  : Border.all(color: _baseColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: kIsWeb ? 40 : 40.w,
                  height: kIsWeb ? 40 : 40.w,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kIsWeb ? 20 : 20.r),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: kIsWeb ? 20 : 20.sp,
                  ),
                ),
                SizedBox(width: kIsWeb ? 12 : 12.w),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: kIsWeb ? 16 : 16.sp,
                          fontWeight:
                              notification.isRead ? FontWeight.w500 : FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: kIsWeb ? 4 : 4.h),

                      // Body
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 14.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: kIsWeb ? 8 : 8.h),

                      // Time and Actions
                      Row(
                        children: [
                          // Time
                          Text(
                            _formatTime(notification.timestamp),
                            style: TextStyle(
                              fontSize: kIsWeb ? 12 : 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),

                          // Mark as read/unread
                          if (!notification.isRead)
                            TextButton(
                              onPressed: () => _markAsRead(notification),
                              child: Text(
                                'Mark as read',
                                style: TextStyle(fontSize: kIsWeb ? 12 : 12.sp),
                              ),
                            ),

                          // Delete button
                          IconButton(
                            onPressed: () => _showDeleteDialog(notification),
                            icon: Icon(Icons.delete_outline, size: kIsWeb ? 18 : 18.sp),
                            color: Colors.grey[500],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    _markAsRead(notification);

    if (notification.data != null && notification.data!['screen'] != null) {
      final screen = notification.data!['screen'];
      switch (screen) {
        case 'home':
          Navigator.of(context).pushNamed('/home');
          break;
        case 'leaderboard':
          Navigator.of(context).pushNamed('/leaderboard');
          break;
        case 'profile':
          Navigator.of(context).pushNamed('/profile');
          break;
        default:
          Navigator.of(context).pushNamed('/home');
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Colors.green;
      case 'achievement':
        return Colors.orange;
      case 'reminder':
        return _baseColor;
      case 'update':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Icons.quiz;
      case 'achievement':
        return Icons.emoji_events;
      case 'reminder':
        return Icons.schedule;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteDialog(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteNotification(notification);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllNotifications();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
