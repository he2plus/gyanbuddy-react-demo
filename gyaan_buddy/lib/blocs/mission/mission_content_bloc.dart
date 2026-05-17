import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/mission_api_service.dart';
import '../../models/next_content_model.dart';

// Events
abstract class MissionContentEvent extends Equatable {
  const MissionContentEvent();

  @override
  List<Object?> get props => [];
}

class LoadNextMissionContent extends MissionContentEvent {
  final String missionId;
  final String? currentContentId;
  
  const LoadNextMissionContent(this.missionId, {this.currentContentId});

  @override
  List<Object?> get props => [missionId, currentContentId];
}

class RefreshMissionContent extends MissionContentEvent {
  final String missionId;
  final String? currentContentId;
  
  const RefreshMissionContent(this.missionId, {this.currentContentId});

  @override
  List<Object?> get props => [missionId, currentContentId];
}

// States
abstract class MissionContentState extends Equatable {
  const MissionContentState();

  @override
  List<Object?> get props => [];
}

class MissionContentInitial extends MissionContentState {}

class MissionContentLoading extends MissionContentState {}

class MissionContentLoaded extends MissionContentState {
  final NextContent content;
  final String missionId;
  final String? currentContentId;

  const MissionContentLoaded({
    required this.content,
    required this.missionId,
    this.currentContentId,
  });

  @override
  List<Object?> get props => [content, missionId, currentContentId];

  MissionContentLoaded copyWith({
    NextContent? content,
    String? missionId,
    String? currentContentId,
  }) {
    return MissionContentLoaded(
      content: content ?? this.content,
      missionId: missionId ?? this.missionId,
      currentContentId: currentContentId ?? this.currentContentId,
    );
  }
}

class MissionContentError extends MissionContentState {
  final String message;
  final String missionId;
  final String? currentContentId;

  const MissionContentError({
    required this.message,
    required this.missionId,
    this.currentContentId,
  });

  @override
  List<Object?> get props => [message, missionId, currentContentId];
}

class NoNextMissionContent extends MissionContentState {
  final String message;
  final String missionId;
  final String? currentContentId;

  const NoNextMissionContent({
    required this.message,
    required this.missionId,
    this.currentContentId,
  });

  @override
  List<Object?> get props => [message, missionId, currentContentId];
}

// Bloc
class MissionContentBloc extends Bloc<MissionContentEvent, MissionContentState> {
  final MissionApiService _missionApiService;

  MissionContentBloc({required MissionApiService missionApiService})
      : _missionApiService = missionApiService,
        super(MissionContentInitial()) {
    on<LoadNextMissionContent>(_onLoadNextMissionContent);
    on<RefreshMissionContent>(_onRefreshMissionContent);
  }

  Future<void> _onLoadNextMissionContent(
    LoadNextMissionContent event,
    Emitter<MissionContentState> emit,
  ) async {
    emit(MissionContentLoading());

    try {
      print('Loading next mission content for mission: ${event.missionId}, current content: ${event.currentContentId}');
      final response = await _missionApiService.getNextContent(
        event.missionId,
        currentContentId: event.currentContentId,
      );
      print('Mission content API response: success=${response.success}, message=${response.message}');
      
      if (response.success && response.data != null) {
        final content = response.data!;
        print('Successfully loaded next mission content');
        
        emit(MissionContentLoaded(
          content: content,
          missionId: event.missionId,
          currentContentId: event.currentContentId,
        ));
      } else if (response.message.toLowerCase().contains('no more content') || 
                 response.message.toLowerCase().contains('completed') ||
                 response.message.toLowerCase().contains('finished')) {
        print('No more mission content available: ${response.message}');
        emit(NoNextMissionContent(
          message: response.message,
          missionId: event.missionId,
          currentContentId: event.currentContentId,
        ));
      } else {
        print('Failed to load mission content: ${response.message}');
        emit(MissionContentError(
          message: response.message,
          missionId: event.missionId,
          currentContentId: event.currentContentId,
        ));
      }
    } catch (e) {
      print('Exception loading mission content: $e');
      emit(MissionContentError(
        message: 'Failed to load mission content: ${e.toString()}',
        missionId: event.missionId,
        currentContentId: event.currentContentId,
      ));
    }
  }

  Future<void> _onRefreshMissionContent(
    RefreshMissionContent event,
    Emitter<MissionContentState> emit,
  ) async {
    // Reset to initial state and reload
    emit(MissionContentInitial());
    add(LoadNextMissionContent(event.missionId, currentContentId: event.currentContentId));
  }
}
