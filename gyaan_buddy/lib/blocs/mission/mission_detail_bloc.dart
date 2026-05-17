import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/mission_model.dart';
import '../../services/mission_api_service.dart';

// Events
abstract class MissionDetailEvent extends Equatable {
  const MissionDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadMissionDetail extends MissionDetailEvent {
  final String missionId;
  
  const LoadMissionDetail(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

class RefreshMissionDetail extends MissionDetailEvent {
  final String missionId;
  
  const RefreshMissionDetail(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

class StartMissionDetail extends MissionDetailEvent {
  final String missionId;
  
  const StartMissionDetail(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

class CompleteMissionDetail extends MissionDetailEvent {
  final String missionId;
  
  const CompleteMissionDetail(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

// States
abstract class MissionDetailState extends Equatable {
  const MissionDetailState();

  @override
  List<Object?> get props => [];
}

class MissionDetailInitial extends MissionDetailState {}

class MissionDetailLoading extends MissionDetailState {}

class MissionDetailLoaded extends MissionDetailState {
  final Mission mission;

  const MissionDetailLoaded({
    required this.mission,
  });

  @override
  List<Object?> get props => [mission];

  MissionDetailLoaded copyWith({
    Mission? mission,
  }) {
    return MissionDetailLoaded(
      mission: mission ?? this.mission,
    );
  }
}

class MissionDetailError extends MissionDetailState {
  final String message;

  const MissionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class MissionDetailActionLoading extends MissionDetailState {
  final String missionId;
  final String action; // 'start' or 'complete'

  const MissionDetailActionLoading({
    required this.missionId,
    required this.action,
  });

  @override
  List<Object?> get props => [missionId, action];
}

class MissionDetailActionSuccess extends MissionDetailState {
  final String missionId;
  final String action;
  final Mission updatedMission;

  const MissionDetailActionSuccess({
    required this.missionId,
    required this.action,
    required this.updatedMission,
  });

  @override
  List<Object?> get props => [missionId, action, updatedMission];
}

class MissionDetailActionError extends MissionDetailState {
  final String message;
  final String missionId;
  final String action;

  const MissionDetailActionError({
    required this.message,
    required this.missionId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, missionId, action];
}

// Bloc
class MissionDetailBloc extends Bloc<MissionDetailEvent, MissionDetailState> {
  final MissionApiService _missionApiService;

  MissionDetailBloc({required MissionApiService missionApiService})
      : _missionApiService = missionApiService,
        super(MissionDetailInitial()) {
    on<LoadMissionDetail>(_onLoadMissionDetail);
    on<RefreshMissionDetail>(_onRefreshMissionDetail);
    on<StartMissionDetail>(_onStartMissionDetail);
    on<CompleteMissionDetail>(_onCompleteMissionDetail);
  }

  Future<void> _onLoadMissionDetail(
    LoadMissionDetail event,
    Emitter<MissionDetailState> emit,
  ) async {
    emit(MissionDetailLoading());

    try {
      print('Loading mission detail for ID: ${event.missionId}');
      final response = await _missionApiService.getMissionById(event.missionId);
      print('Mission detail API response: success=${response.success}, message=${response.message}');
      
      if (response.success && response.data != null) {
        final mission = response.data!;
        print('Successfully loaded mission: ${mission.title}');
        
        emit(MissionDetailLoaded(mission: mission));
      } else {
        print('Failed to load mission detail: ${response.message}');
        emit(MissionDetailError(response.message));
      }
    } catch (e) {
      print('Exception loading mission detail: $e');
      emit(MissionDetailError('Failed to load mission: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshMissionDetail(
    RefreshMissionDetail event,
    Emitter<MissionDetailState> emit,
  ) async {
    try {
      print('Refreshing mission detail for ID: ${event.missionId}');
      final response = await _missionApiService.getMissionById(event.missionId);
      print('Mission detail refresh API response: success=${response.success}, message=${response.message}');
      
      if (response.success && response.data != null) {
        final mission = response.data!;
        print('Successfully refreshed mission: ${mission.title}');
        
        emit(MissionDetailLoaded(mission: mission));
      } else {
        print('Failed to refresh mission detail: ${response.message}');
        emit(MissionDetailError(response.message));
      }
    } catch (e) {
      print('Exception refreshing mission detail: $e');
      emit(MissionDetailError('Failed to refresh mission: ${e.toString()}'));
    }
  }

  Future<void> _onStartMissionDetail(
    StartMissionDetail event,
    Emitter<MissionDetailState> emit,
  ) async {
    emit(MissionDetailActionLoading(
      missionId: event.missionId,
      action: 'start',
    ));

    try {
      print('Starting mission: ${event.missionId}');
      final response = await _missionApiService.startMission(event.missionId);
      print('Start mission API response: success=${response.success}, message=${response.message}');
      
      if (response.success) {
        // Refresh the mission to get updated status
        final missionResponse = await _missionApiService.getMissionById(event.missionId);
        
        if (missionResponse.success && missionResponse.data != null) {
          emit(MissionDetailActionSuccess(
            missionId: event.missionId,
            action: 'start',
            updatedMission: missionResponse.data!,
          ));
          
          // Update the state to show the updated mission
          emit(MissionDetailLoaded(mission: missionResponse.data!));
        } else {
          emit(MissionDetailActionError(
            message: 'Failed to refresh mission after starting',
            missionId: event.missionId,
            action: 'start',
          ));
        }
      } else {
        emit(MissionDetailActionError(
          message: response.message,
          missionId: event.missionId,
          action: 'start',
        ));
      }
    } catch (e) {
      emit(MissionDetailActionError(
        message: 'Failed to start mission: ${e.toString()}',
        missionId: event.missionId,
        action: 'start',
      ));
    }
  }

  Future<void> _onCompleteMissionDetail(
    CompleteMissionDetail event,
    Emitter<MissionDetailState> emit,
  ) async {
    emit(MissionDetailActionLoading(
      missionId: event.missionId,
      action: 'complete',
    ));

    try {
      print('Completing mission: ${event.missionId}');
      final response = await _missionApiService.completeMission(event.missionId);
      print('Complete mission API response: success=${response.success}, message=${response.message}');
      
      if (response.success) {
        // Refresh the mission to get updated status
        final missionResponse = await _missionApiService.getMissionById(event.missionId);
        
        if (missionResponse.success && missionResponse.data != null) {
          emit(MissionDetailActionSuccess(
            missionId: event.missionId,
            action: 'complete',
            updatedMission: missionResponse.data!,
            ));
          
          // Update the state to show the updated mission
          emit(MissionDetailLoaded(mission: missionResponse.data!));
        } else {
          emit(MissionDetailActionError(
            message: 'Failed to refresh mission after completing',
            missionId: event.missionId,
            action: 'complete',
          ));
        }
      } else {
        emit(MissionDetailActionError(
          message: response.message,
          missionId: event.missionId,
          action: 'complete',
        ));
      }
    } catch (e) {
      emit(MissionDetailActionError(
        message: 'Failed to complete mission: ${e.toString()}',
        missionId: event.missionId,
        action: 'complete',
      ));
    }
  }
}
