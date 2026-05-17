import 'package:equatable/equatable.dart';

class Level extends Equatable {
  final String id;
  final int name;
  final int minExp;
  final int maxExp;

  const Level({
    required this.id,
    required this.name,
    required this.minExp,
    required this.maxExp,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'].toString(),
      name: json['name'] ?? 1,
      minExp: json['min_exp'] ?? 0,
      maxExp: json['max_exp'] ?? 100,
    );
  }

  // Safer factory method for leaderboard data
  factory Level.fromLeaderboardJson(Map<String, dynamic> json) {
    return Level(
      id: json['id']?.toString() ?? '',
      name: _safeParseInt(json['name']),
      minExp: _safeParseInt(json['min_exp']),
      maxExp: _safeParseInt(json['max_exp']),
    );
  }

  // Safe integer parsing helper
  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing Level int from string: $value, error: $e');
        return 0;
      }
    }
    if (value is double) return value.toInt();
    print(
        'Unexpected type for Level int parsing: $value (${value.runtimeType})');
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'min_exp': minExp,
      'max_exp': maxExp,
    };
  }

  // Computed properties
  int get expRange => maxExp - minExp + 1;

  bool isExpInRange(int exp) => exp >= minExp && exp <= maxExp;

  // Methods
  Level copyWith({
    String? id,
    int? name,
    int? minExp,
    int? maxExp,
  }) {
    return Level(
      id: id ?? this.id,
      name: name ?? this.name,
      minExp: minExp ?? this.minExp,
      maxExp: maxExp ?? this.maxExp,
    );
  }

  @override
  List<Object?> get props => [id, name, minExp, maxExp];

  @override
  String toString() {
    return 'Level(id: $id, name: $name, minExp: $minExp, maxExp: $maxExp)';
  }
}
