import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/user/user_bloc.dart';
import '../../models/user_model.dart';
import '../../utils/web_size_utils.dart';
import 'ranked_item.dart';

class LeaderboardWidget extends StatefulWidget {
  final bool compact;

  const LeaderboardWidget({
    super.key,
    this.compact = false,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  String? _selectedFilter;
  String? _className;
  String? _gradeName;
  bool _didPrecacheAssets = false;
  late ScrollController _scrollController;

  Color _hexToColor(String? hexString, {Color fallback = Colors.blue}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      String hex =
          hexString.startsWith('#') ? hexString.substring(1) : hexString;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallback;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedFilter = 'IX-A';

    // Load leaderboard data if not already loaded
    final state = context.read<UserBloc>().state;
    if (state is! LeaderboardLoaded && state is! LeaderboardLoading) {
      context
          .read<UserBloc>()
          .add(const LoadLeaderboard(limit: 10, grade: null));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheAssets) return;
    _didPrecacheAssets = true;
    precacheImage(const AssetImage('assets/images/prize.png'), context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterBar(),
        if (!widget.compact) _buildPrizeImage(),
        _buildLeaderboardContent(),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = <String>[];
    if (_className != null && _className!.isNotEmpty) {
      filters.add(_className!);
    }
    if (_gradeName != null && _gradeName!.isNotEmpty) {
      filters.add(_gradeName!);
    }

    if (filters.isEmpty) {
      filters.addAll(['IX-A', 'IX']);
    }

    if (_selectedFilter == null || !filters.contains(_selectedFilter)) {
      if (filters.isNotEmpty) {
        _selectedFilter = filters[0];
      }
    }

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 9.wWeb : 18.wWeb,
          vertical: widget.compact ? 5.hWeb : 9.hWeb,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.rWeb),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: widget.compact ? 34.hWeb : 40.hWeb,
              constraints: BoxConstraints(
                maxWidth: kIsWeb ? 315 : 0.9.sw,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hexToColor("6A8AFF").withOpacity(0.85),
                    _hexToColor("5A7AEF").withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.rWeb),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hexToColor("3960EA").withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: filters.map((filter) {
                  final isSelected = _selectedFilter == filter;

                  return Expanded(
                    flex: isSelected ? 6 : 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });

                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0.0);
                        }

                        final gradeParam =
                            (filter == _gradeName && _gradeName != null)
                                ? _gradeName
                                : null;
                        context
                            .read<UserBloc>()
                            .add(LoadLeaderboard(limit: 10, grade: gradeParam));

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted && _scrollController.hasClients) {
                              _scrollController.jumpTo(0.0);
                            }
                          });
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: EdgeInsets.all(4.wWeb),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _hexToColor("3960EA").withOpacity(0.9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16.rWeb),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: isSelected ? 13.spWeb : 12.spWeb,
                            ),
                            child: Text(
                              filter,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeImage() {
    return SizedBox(
      height: 230.hWeb,
      width: 260.wWeb,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/prize.png',
                width: 260.wWeb,
                height: 230.hWeb,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150.wWeb,
                    height: 150.hWeb,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.rWeb),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 50.spWeb,
                      color: Colors.amber,
                    ),
                  );
                },
              ),
              Positioned(
                top: 45.hWeb,
                right: 118.wWeb,
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 48.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 95.hWeb,
                right: 200.wWeb,
                child: Text(
                  '2',
                  style: TextStyle(
                    fontSize: 48.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                top: 95.hWeb,
                right: 36.wWeb,
                child: Text(
                  '3',
                  style: TextStyle(
                    fontSize: 48.spWeb,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return Container(
            height: widget.compact ? 200.hWeb : 300.hWeb,
            width: double.infinity,
            padding: EdgeInsets.all(30.wWeb),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else if (state is LeaderboardLoaded) {
          if (state.className != null || state.gradeName != null) {
            final classNameChanged = _className != state.className;
            final gradeNameChanged = _gradeName != state.gradeName;

            if (classNameChanged || gradeNameChanged) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _className = state.className;
                    _gradeName = state.gradeName;

                    if (_selectedFilter == null) {
                      _selectedFilter = state.className ?? state.gradeName;
                    } else {
                      final validFilters = <String>[];
                      if (_className != null && _className!.isNotEmpty)
                        validFilters.add(_className!);
                      if (_gradeName != null && _gradeName!.isNotEmpty)
                        validFilters.add(_gradeName!);

                      if (!validFilters.contains(_selectedFilter)) {
                        _selectedFilter =
                            validFilters.isNotEmpty ? validFilters[0] : null;
                      }
                    }
                  });
                }
              });
            } else {
              _className = state.className;
              _gradeName = state.gradeName;
            }
          }
          return _buildRankedList(state.users);
        } else if (state is LeaderboardError) {
          return _buildErrorState(state.message);
        } else {
          return Container(
            padding: EdgeInsets.all(30.wWeb),
            child: const Center(
              child: Text('No leaderboard data available'),
            ),
          );
        }
      },
    );
  }

  Widget _buildRankedList(List<User> users) {
    if (users.isEmpty) {
      return Container(
        padding: EdgeInsets.all(30.wWeb),
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(fontSize: 14.spWeb, color: Colors.grey),
          ),
        ),
      );
    }

    final currentUser = context.read<UserBloc>().currentUser;
    final currentUserId = currentUser?.id;
    final entries = _visibleEntries(users, currentUserId);

    return Center(
      child: Container(
        width: widget.compact ? double.infinity : 450.wWeb,
        padding:
            EdgeInsets.symmetric(horizontal: widget.compact ? 9.wWeb : 18.wWeb),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: entries.map((entry) {
            final user = entry.value;
            final rank = entry.key + 1;
            final isCurrentUser = user.id == currentUserId;

            return RankedItem(
              user: user,
              rank: rank,
              isCurrentUser: isCurrentUser,
            );
          }).toList(),
        ),
      ),
    );
  }

  List<MapEntry<int, User>> _visibleEntries(
      List<User> users, String? currentUserId) {
    final indexedUsers = users.asMap().entries.toList();
    if (!widget.compact) return indexedUsers;

    final topThree = indexedUsers.take(3).toList();
    final currentUserTopThree = currentUserId != null &&
        topThree.any((entry) => entry.value.id == currentUserId);
    if (currentUserTopThree || users.length <= 3) return topThree;

    if (currentUserId != null) {
      final currentUserIndex =
          indexedUsers.indexWhere((entry) => entry.value.id == currentUserId);
      if (currentUserIndex >= 3) {
        return [...topThree, indexedUsers[currentUserIndex]];
      }
    }

    return indexedUsers.take(4).toList();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40.wWeb,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.hWeb),
          Text(
            'Error loading leaderboard',
            style: TextStyle(
              fontSize: 14.spWeb,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.hWeb),
          Text(
            message,
            style: TextStyle(
              fontSize: 13.spWeb,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.hWeb),
          ElevatedButton(
            onPressed: () {
              final gradeParam =
                  (_selectedFilter == _gradeName && _gradeName != null)
                      ? _gradeName
                      : null;
              context
                  .read<UserBloc>()
                  .add(LoadLeaderboard(limit: 10, grade: gradeParam));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
