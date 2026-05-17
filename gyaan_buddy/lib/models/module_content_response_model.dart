import 'package:equatable/equatable.dart';
import 'module_content_item_model.dart';

// Module content response model
class ModuleContentResponse extends Equatable {
  final bool success;
  final List<ModuleContentItem> data;
  final String message;

  const ModuleContentResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory ModuleContentResponse.fromJson(Map<String, dynamic> json) {
    return ModuleContentResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => ModuleContentItem.fromJson(item))
              .toList() ??
          [],
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((item) => item.toJson()).toList(),
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, data, message];
}
