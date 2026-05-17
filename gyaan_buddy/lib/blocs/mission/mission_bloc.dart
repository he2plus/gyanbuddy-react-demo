import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/mission_model.dart';
import '../../services/mission_api_service.dart';
import '../../services/cache_data_service.dart';

// Events
abstract class MissionEvent extends Equatable {
  const MissionEvent();

  @override
  List<Object?> get props => [];
}

class LoadMissions extends MissionEvent {
  final int? month;
  final int? year;

  const LoadMissions({this.month, this.year});

  @override
  List<Object?> get props => [month, year];
}

class RefreshMissions extends MissionEvent {
  final int? month;
  final int? year;

  const RefreshMissions({this.month, this.year});

  @override
  List<Object?> get props => [month, year];
}

class StartMission extends MissionEvent {
  final String missionId;

  const StartMission(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

class CompleteMission extends MissionEvent {
  final String missionId;

  const CompleteMission(this.missionId);

  @override
  List<Object?> get props => [missionId];
}

// States
abstract class MissionState extends Equatable {
  const MissionState();

  @override
  List<Object?> get props => [];
}

class MissionInitial extends MissionState {}

class MissionLoading extends MissionState {}

class MissionLoaded extends MissionState {
  final List<Mission> missions;
  final List<DateTime> missionDates;

  const MissionLoaded({
    required this.missions,
    required this.missionDates,
  });

  @override
  List<Object?> get props => [missions, missionDates];

  MissionLoaded copyWith({
    List<Mission>? missions,
    List<DateTime>? missionDates,
  }) {
    return MissionLoaded(
      missions: missions ?? this.missions,
      missionDates: missionDates ?? this.missionDates,
    );
  }
}

class MissionError extends MissionState {
  final String message;

  const MissionError(this.message);

  @override
  List<Object?> get props => [message];
}

class MissionActionLoading extends MissionState {
  final String missionId;
  final String action; // 'start' or 'complete'

  const MissionActionLoading({
    required this.missionId,
    required this.action,
  });

  @override
  List<Object?> get props => [missionId, action];
}

class MissionActionSuccess extends MissionState {
  final String missionId;
  final String action;
  final List<Mission> updatedMissions;

  const MissionActionSuccess({
    required this.missionId,
    required this.action,
    required this.updatedMissions,
  });

  @override
  List<Object?> get props => [missionId, action, updatedMissions];
}

class MissionActionError extends MissionState {
  final String message;
  final String missionId;
  final String action;

  const MissionActionError({
    required this.message,
    required this.missionId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, missionId, action];
}

// Bloc
class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final MissionApiService _missionApiService;
  String? _activeMissionRequestKey;

  MissionBloc({required MissionApiService missionApiService})
      : _missionApiService = missionApiService,
        super(MissionInitial()) {
    on<LoadMissions>(_onLoadMissions);
    on<RefreshMissions>(_onRefreshMissions);
    on<StartMission>(_onStartMission);
    on<CompleteMission>(_onCompleteMission);
  }

  Future<void> _onLoadMissions(
    LoadMissions event,
    Emitter<MissionState> emit,
  ) async {
    final requestKey = _missionRequestKey(month: event.month, year: event.year);
    _activeMissionRequestKey = requestKey;

    try {
      print(
          'Loading missions for ${event.month ?? DateTime.now().month}/${event.year ?? DateTime.now().year}...');
      emit(MissionLoading());

      final response = await CacheDataService.instance.getMissions(
        month: event.month,
        year: event.year,
      );
      if (!_isActiveMissionRequest(requestKey)) return;

      if (response.success && response.data != null) {
        final missions = response.data!;
        print(
            'Successfully loaded ${missions.length} missions from ${response.fromCache ? "cache" : "API"}');
        _emitLoadedMissions(emit, missions);

        if (response.fromCache) {
          final freshResponse = await CacheDataService.instance.getMissions(
            forceRefresh: true,
            month: event.month,
            year: event.year,
          );
          if (!_isActiveMissionRequest(requestKey)) return;

          if (freshResponse.success && freshResponse.data != null) {
            final freshMissions = freshResponse.data!;
            print(
                'Updated ${freshMissions.length} missions from API after cache hit');
            _emitLoadedMissions(emit, freshMissions);
          }
        }
      } else {
        emit(MissionError(response.error ?? 'Failed to load missions'));
      }
    } catch (e) {
      if (!_isActiveMissionRequest(requestKey)) return;
      print('Exception loading missions: $e');
      emit(MissionError('Failed to load missions: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshMissions(
    RefreshMissions event,
    Emitter<MissionState> emit,
  ) async {
    final requestKey = _missionRequestKey(month: event.month, year: event.year);
    _activeMissionRequestKey = requestKey;

    try {
      print('Refreshing missions from API...');
      await CacheDataService.instance.invalidateMissionsCache(
        month: event.month,
        year: event.year,
      );
      final response = await CacheDataService.instance.getMissions(
        forceRefresh: true,
        month: event.month,
        year: event.year,
      );
      if (!_isActiveMissionRequest(requestKey)) return;

      if (response.success && response.data != null) {
        final missions = response.data!;
        print('Successfully refreshed ${missions.length} missions from API');

        _emitLoadedMissions(emit, missions);
      } else {
        print('Failed to refresh missions: ${response.error}');
        emit(MissionError(response.error ?? 'Failed to refresh missions'));
      }
    } catch (e) {
      if (!_isActiveMissionRequest(requestKey)) return;
      print('Exception refreshing missions: $e');
      emit(MissionError('Failed to refresh missions: ${e.toString()}'));
    }
  }

  String _missionRequestKey({int? month, int? year}) {
    final now = DateTime.now();
    return '${year ?? now.year}-${month ?? now.month}';
  }

  bool _isActiveMissionRequest(String requestKey) {
    return _activeMissionRequestKey == requestKey;
  }

  void _emitLoadedMissions(
    Emitter<MissionState> emit,
    List<Mission> missions,
  ) {
    final missionDates =
        missions.map((mission) => mission.missionDate).toList();
    emit(MissionLoaded(missions: missions, missionDates: missionDates));
  }

  Future<void> _onStartMission(
    StartMission event,
    Emitter<MissionState> emit,
  ) async {
    emit(MissionActionLoading(
      missionId: event.missionId,
      action: 'start',
    ));

    try {
      print('Starting mission: ${event.missionId}');
      final response = await _missionApiService.startMission(event.missionId);
      print(
          'Start mission API response: success=${response.success}, message=${response.message}');

      if (response.success) {
        // Refresh the missions list to get updated status
        final missionsResponse = await _missionApiService.getAllMissions();

        if (missionsResponse.success && missionsResponse.data != null) {
          final missions = missionsResponse.data!;
          final missionDates =
              missions.map((mission) => mission.missionDate).toList();

          emit(MissionActionSuccess(
            missionId: event.missionId,
            action: 'start',
            updatedMissions: missions,
          ));

          // Update the state to show the updated missions
          emit(MissionLoaded(
            missions: missions,
            missionDates: missionDates,
          ));
        } else {
          emit(MissionActionError(
            message: 'Failed to refresh missions after starting',
            missionId: event.missionId,
            action: 'start',
          ));
        }
      } else {
        emit(MissionActionError(
          message: response.message,
          missionId: event.missionId,
          action: 'start',
        ));
      }
    } catch (e) {
      emit(MissionActionError(
        message: 'Failed to start mission: ${e.toString()}',
        missionId: event.missionId,
        action: 'start',
      ));
    }
  }

  Future<void> _onCompleteMission(
    CompleteMission event,
    Emitter<MissionState> emit,
  ) async {
    emit(MissionActionLoading(
      missionId: event.missionId,
      action: 'complete',
    ));

    try {
      print('Completing mission: ${event.missionId}');
      final response =
          await _missionApiService.completeMission(event.missionId);
      print(
          'Complete mission API response: success=${response.success}, message=${response.message}');

      if (response.success) {
        // Refresh the missions list to get updated status
        final missionsResponse = await _missionApiService.getAllMissions();

        if (missionsResponse.success && missionsResponse.data != null) {
          final missions = missionsResponse.data!;
          final missionDates =
              missions.map((mission) => mission.missionDate).toList();

          emit(MissionActionSuccess(
            missionId: event.missionId,
            action: 'complete',
            updatedMissions: missions,
          ));

          // Update the state to show the updated missions
          emit(MissionLoaded(
            missions: missions,
            missionDates: missionDates,
          ));
        } else {
          emit(MissionActionError(
            message: 'Failed to refresh missions after completing',
            missionId: event.missionId,
            action: 'complete',
          ));
        }
      } else {
        emit(MissionActionError(
          message: response.message,
          missionId: event.missionId,
          action: 'complete',
        ));
      }
    } catch (e) {
      emit(MissionActionError(
        message: 'Failed to complete mission: ${e.toString()}',
        missionId: event.missionId,
        action: 'complete',
      ));
    }
  }

  // Helper method to check if a date has missions
  bool hasMissionsOnDate(DateTime date) {
    if (state is MissionLoaded) {
      final missionState = state as MissionLoaded;
      return missionState.missionDates.any((missionDate) =>
          missionDate.year == date.year &&
          missionDate.month == date.month &&
          missionDate.day == date.day);
    }
    return false;
  }

  // Helper method to get missions for a specific date
  List<Mission> getMissionsForDate(DateTime date) {
    if (state is MissionLoaded) {
      final missionState = state as MissionLoaded;
      return missionState.missions
          .where((mission) =>
              mission.missionDate.year == date.year &&
              mission.missionDate.month == date.month &&
              mission.missionDate.day == date.day)
          .toList();
    }
    return [];
  }
}
