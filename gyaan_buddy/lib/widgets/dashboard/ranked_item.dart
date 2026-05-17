import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/web_size_utils.dart';

class RankedItem extends StatelessWidget {
  final User user;
  final int rank;
  final bool isCurrentUser;

  const RankedItem({
    super.key,
    required this.user,
    required this.rank,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    // Safely get first character of name
    final firstNameInitial = (user.firstName.isNotEmpty
        ? user.firstName[0].toUpperCase()
        : (user.fullName.isNotEmpty
            ? user.fullName[0].toUpperCase()
            : '?'));

    return Container(
      margin: EdgeInsets.only(bottom: 9.hWeb),
      padding: EdgeInsets.all(11.wWeb),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(7.rWeb),
        border: isCurrentUser 
          ? Border.all(color: Colors.blue, width: 2)
          : Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
              left: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
              bottom: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 4,
              ),
              right: BorderSide(
                color: Colors.black.withOpacity(0.05),
                width: 5,
              ),
            ),
        boxShadow: isCurrentUser ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Row(
        children: [
          // Rank
          Text(
            '$rank.',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14.spWeb,
            ),
          ),
          SizedBox(
            width: 18.wWeb,
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 43.wWeb,
                  height: 43.wWeb,
                  decoration: BoxDecoration(
                    color: getRankColor(rank),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      firstNameInitial,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 20.spWeb,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 9.wWeb),

                // User info
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 14.spWeb,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 8.wWeb),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.wWeb, vertical: 2.hWeb),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(9.rWeb),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              fontSize: 9.spWeb,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Score
          Text(
            '${user.totalExp} XP',
            style: TextStyle(
              fontSize: 14.spWeb,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to get rank color
Color getRankColor(int rank) {
  switch (rank) {
    case 1:
      return Colors.amber; // Gold
    case 2:
      return Colors.grey[400]!; // Silver
    case 3:
      return Colors.brown; // Bronze
    default:
      return Colors.blue;
  }
}

