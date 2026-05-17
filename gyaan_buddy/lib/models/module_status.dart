import 'package:flutter/material.dart';

// Module status enum for better type safety
enum ModuleStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  due('due'),
  completed('completed');

  const ModuleStatus(this.value);
  final String value;

  static ModuleStatus fromString(String value) {
    return ModuleStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ModuleStatus.notStarted,
    );
  }

  String get displayName {
    switch (this) {
      case ModuleStatus.notStarted:
        return 'Not Started';
      case ModuleStatus.inProgress:
        return 'In Progress';
      case ModuleStatus.due:
        return 'Due';
      case ModuleStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case ModuleStatus.notStarted:
        return Colors.grey;
      case ModuleStatus.inProgress:
        return Colors.blue;
      case ModuleStatus.due:
        return Colors.orange;
      case ModuleStatus.completed:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case ModuleStatus.notStarted:
        return Icons.play_circle_outline;
      case ModuleStatus.inProgress:
        return Icons.pause_circle_outline;
      case ModuleStatus.due:
        return Icons.schedule;
      case ModuleStatus.completed:
        return Icons.check_circle;
    }
  }
}
