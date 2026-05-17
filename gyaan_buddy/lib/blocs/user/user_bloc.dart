import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../services/user_api_service.dart';
import '../../services/token_storage_service.dart';
import '../../services/global_logout_service.dart';
import '../../services/api_service.dart';
import '../../services/cache_data_service.dart';
import '../../utils/error_message_helper.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoginUser extends UserEvent {
  final Map<String, dynamic> loginData;

  const LoginUser(this.loginData);

  @override
  List<Object?> get props => [loginData];
}

class RegisterUser extends UserEvent {
  final Map<String, dynamic> registerData;

  const RegisterUser(this.registerData);

  @override
  List<Object?> get props => [registerData];
}

class LoadCurrentUser extends UserEvent {
  final bool forceRefresh;

  const LoadCurrentUser({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class UpdateUserProfile extends UserEvent {
  final Map<String, dynamic> profileData;

  const UpdateUserProfile(this.profileData);

  @override
  List<Object?> get props => [profileData];
}

class LogoutUser extends UserEvent {
  const LogoutUser();
}

class ChangePassword extends UserEvent {
  final Map<String, dynamic> passwordData;

  const ChangePassword(this.passwordData);

  @override
  List<Object?> get props => [passwordData];
}

class LoadLeaderboard extends UserEvent {
  final int? page;
  final int? limit;
  final String? period;
  final String? grade;
  final bool forceRefresh;

  const LoadLeaderboard({
    this.page,
    this.limit,
    this.period,
    this.grade,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [page, limit, period, grade, forceRefresh];
}

class ResetToUserState extends UserEvent {
  const ResetToUserState();
}



// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserAuthenticated extends UserState {
  final User user;

  const UserAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserUnauthenticated extends UserState {}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class LeaderboardLoading extends UserState {}

class LeaderboardLoaded extends UserState {
  final List<User> users;
  final int currentPage;
  final bool hasMore;
  final String? className;
  final String? gradeName;

  const LeaderboardLoaded({
    required this.users,
    required this.currentPage,
    required this.hasMore,
    this.className,
    this.gradeName,
  });

  @override
  List<Object?> get props => [users, currentPage, hasMore, className, gradeName];
}

class LeaderboardError extends UserState {
  final String message;

  const LeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserApiService _userApiService;
  
  // Cache the authenticated user so it persists across state changes
  User? _cachedUser;
  String? _cachedClassName;
  String? _cachedGradeName;

  UserBloc({UserApiService? userApiService})
      : _userApiService = userApiService ?? UserApiService(),
        super(UserInitial()) {
    on<LoginUser>(_onLoginUser);
    on<RegisterUser>(_onRegisterUser);
    on<LoadCurrentUser>(_onLoadCurrentUser);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<LogoutUser>(_onLogoutUser);
    on<ChangePassword>(_onChangePassword);
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<ResetToUserState>(_onResetToUserState);
  }

  void _onLoginUser(LoginUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    
    try {
      final response = await _userApiService.login(event.loginData);
      
      if (response.success && response.data != null) {
        _cachedUser = response.data!; // Cache the user
        emit(UserAuthenticated(response.data!));
      } else {
        emit(UserError(response.message));
      }
    } catch (e) {
      emit(UserError(ErrorMessageHelper.getErrorMessage(e)));
    }
  }

  void _onRegisterUser(RegisterUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    
    try {
      final response = await _userApiService.register(event.registerData);
      
      if (response.success && response.data != null) {
        _cachedUser = response.data!; // Cache the user
        emit(UserAuthenticated(response.data!));
      } else {
        emit(UserError(response.message));
      }
    } catch (e) {
      emit(UserError(ErrorMessageHelper.getErrorMessage(e)));
    }
  }

  void _onLoadCurrentUser(LoadCurrentUser event, Emitter<UserState> emit) async {
    // If we already have a cached user in memory and not forcing refresh, return immediately
    if (_cachedUser != null && !event.forceRefresh) {
      print('🔵 UserBloc: Using in-memory cached user');
      emit(UserAuthenticated(_cachedUser!));
      return;
    }
    
    try {
      // First check if we have tokens stored
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      
      if (!isLoggedIn) {
        emit(UserUnauthenticated());
        return;
      }
      
      // Set the auth token from storage for API calls
      final accessToken = await TokenStorageService.getAccessToken();
      if (accessToken != null) {
        _userApiService.setAuthToken(accessToken);
      }
      
      // Try to get user from CacheDataService (checks local cache first, then API)
      // Don't emit loading if we have local cache - check cache synchronously first
      await CacheDataService.instance.initialize();
      final cacheResult = await CacheDataService.instance.getUser(forceRefresh: event.forceRefresh);
      
      if (cacheResult.success && cacheResult.data != null) {
        _cachedUser = cacheResult.data!;
        print('🔵 UserBloc: Loaded user from ${cacheResult.fromCache ? "cache" : "API"}${event.forceRefresh ? " (forced refresh)" : ""}');
        emit(UserAuthenticated(_cachedUser!));
      } else {
        // Only emit loading if we need to fetch from API with no cache
        emit(UserLoading());
        
        // Try API directly as fallback
        final response = await _userApiService.getCurrentUser();
        if (response.success && response.data != null) {
          _cachedUser = response.data!;
          emit(UserAuthenticated(_cachedUser!));
        } else {
          // If API also fails, clear tokens and show unauthenticated
          await TokenStorageService.clearTokens();
          _cachedUser = null;
          emit(UserUnauthenticated());
        }
      }
    } catch (e) {
      // Handle unauthorized exceptions
      if (e is UnauthorizedException) {
        // GlobalLogoutService will handle the logout automatically
        _cachedUser = null;
        emit(UserUnauthenticated());
        return;
      }
      
      // If any other error occurs, clear tokens and show unauthenticated
      try {
        await TokenStorageService.clearTokens();
      } catch (clearError) {
        // Ignore clear errors
      }
      _cachedUser = null;
      emit(UserUnauthenticated());
    }
  }

  void _onUpdateUserProfile(UpdateUserProfile event, Emitter<UserState> emit) async {
    if (state is UserAuthenticated) {
      emit(UserLoading());
      
      try {
        final response = await _userApiService.updateProfile(
          name: event.profileData['name'],
          email: event.profileData['email'],
          profileImage: event.profileData['profile_image'],
        );
        
        if (response.success && response.data != null) {
          _cachedUser = response.data!; // Cache the user
          emit(UserAuthenticated(response.data!));
        } else {
          emit(UserError(response.message));
        }
      } catch (e) {
        // Handle unauthorized exceptions
        if (e is UnauthorizedException) {
          // GlobalLogoutService will handle the logout automatically
          emit(UserUnauthenticated());
          return;
        }
        emit(UserError(e.toString()));
      }
    }
  }

  void _onLogoutUser(LogoutUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    
    try {
      await _userApiService.logout();
      // Clear tokens from storage
      await TokenStorageService.clearTokens();
      _cachedUser = null; // Clear cached user
      emit(UserUnauthenticated());
    } catch (e) {
      // Even if logout fails, we should still clear tokens and show unauthenticated state
      await TokenStorageService.clearTokens();
      _cachedUser = null; // Clear cached user
      emit(UserUnauthenticated());
    }
  }

  void _onChangePassword(ChangePassword event, Emitter<UserState> emit) async {
    if (state is UserAuthenticated) {
      emit(UserLoading());
      
      try {
        final response = await _userApiService.changePassword(
          currentPassword: event.passwordData['current_password'],
          newPassword: event.passwordData['new_password'],
          newPasswordConfirmation: event.passwordData['new_password_confirmation'],
        );
        
        if (response.success) {
          // Reload current user to get updated data
          add(const LoadCurrentUser());
        } else {
          emit(UserError(response.message));
        }
      } catch (e) {
        // Handle unauthorized exceptions
        if (e is UnauthorizedException) {
          // GlobalLogoutService will handle the logout automatically
          emit(UserUnauthenticated());
          return;
        }
        emit(UserError(e.toString()));
      }
    }
  }

  void _onLoadLeaderboard(LoadLeaderboard event, Emitter<UserState> emit) async {
    emit(LeaderboardLoading());
    
    try {
      await CacheDataService.instance.initialize();
      User? refreshedUser;
      if (event.forceRefresh) {
        final userResult =
            await CacheDataService.instance.getUser(forceRefresh: true);
        if (userResult.success && userResult.data != null) {
          refreshedUser = userResult.data!;
          _cachedUser = refreshedUser;
        }
      }

      // Try to get from CacheDataService first (local storage cache)
      // Only use cache for default parameters (no pagination/filtering)
      final useCache = event.page == null && event.period == null && event.grade == null;
      var emittedCachedLeaderboard = false;
      
      if (useCache && !event.forceRefresh) {
        final cacheResult = await CacheDataService.instance.getLeaderboard();
        
        if (cacheResult.success && cacheResult.data != null) {
          final leaderboardResponse = cacheResult.data!;
          _cacheLeaderboardScope(leaderboardResponse);
          final users = _mergeCurrentUserIntoLeaderboard(
            leaderboardResponse.users,
            latestUser: refreshedUser,
          );
          final currentPage = 1;
          final hasMore = users.length >= (event.limit ?? 20);
          
          print('🔵 UserBloc: Loaded ${users.length} leaderboard users from ${cacheResult.fromCache ? "cache" : "API"}');
          
          emit(LeaderboardLoaded(
            users: users,
            currentPage: currentPage,
            hasMore: hasMore,
            className: leaderboardResponse.className,
            gradeName: leaderboardResponse.gradeName,
          ));
          emittedCachedLeaderboard = true;
        }
      }

      if (useCache) {
        final cacheResult =
            await CacheDataService.instance.getLeaderboard(forceRefresh: true);

        if (cacheResult.success && cacheResult.data != null) {
          final leaderboardResponse = cacheResult.data!;
          _cacheLeaderboardScope(leaderboardResponse);
          final users = _mergeCurrentUserIntoLeaderboard(
            leaderboardResponse.users,
            latestUser: refreshedUser,
          );
          final currentPage = 1;
          final hasMore = users.length >= (event.limit ?? 20);

          print('🔵 UserBloc: Refreshed ${users.length} leaderboard users from API');

          emit(LeaderboardLoaded(
            users: users,
            currentPage: currentPage,
            hasMore: hasMore,
            className: leaderboardResponse.className,
            gradeName: leaderboardResponse.gradeName,
          ));
          return;
        }

        if (emittedCachedLeaderboard) return;
      }
      
      // Fallback to direct API call for paginated/filtered requests
      final response = await _userApiService.getLeaderboard(
        page: event.page,
        limit: event.limit,
        period: event.period,
        grade: event.grade,
      );
      
      if (response.success && response.data != null) {
        final leaderboardResponse = response.data!;
        _cacheLeaderboardScope(leaderboardResponse);
        final users = _mergeCurrentUserIntoLeaderboard(
          leaderboardResponse.users,
          latestUser: refreshedUser,
        );
        final currentPage = event.page ?? 1;
        final hasMore = users.length >= (event.limit ?? 20);
        
        emit(LeaderboardLoaded(
          users: users,
          currentPage: currentPage,
          hasMore: hasMore,
          className: leaderboardResponse.className,
          gradeName: leaderboardResponse.gradeName,
        ));
      } else {
        emit(LeaderboardError(response.message));
      }
    } catch (e) {
      emit(LeaderboardError(ErrorMessageHelper.getErrorMessage(e)));
    }
  }

  void _cacheLeaderboardScope(LeaderboardResponse leaderboardResponse) {
    if (leaderboardResponse.className != null &&
        leaderboardResponse.className!.isNotEmpty) {
      _cachedClassName = leaderboardResponse.className;
    }
    if (leaderboardResponse.gradeName != null &&
        leaderboardResponse.gradeName!.isNotEmpty) {
      _cachedGradeName = leaderboardResponse.gradeName;
    }
  }

  List<User> _mergeCurrentUserIntoLeaderboard(
    List<User> users, {
    User? latestUser,
  }) {
    final currentUser = latestUser ?? _cachedUser;
    if (currentUser == null) return users;

    final currentUserIndex =
        users.indexWhere((user) => user.id == currentUser.id);
    if (currentUserIndex == -1) return users;

    final mergedUsers = List<User>.from(users);
    final originalOrder = {
      for (final entry in users.asMap().entries) entry.value.id: entry.key,
    };
    final leaderboardUser = mergedUsers[currentUserIndex];
    if (latestUser == null && currentUser.totalExp <= leaderboardUser.totalExp) {
      return users;
    }
    mergedUsers[currentUserIndex] = leaderboardUser.copyWith(
      totalExp: currentUser.totalExp,
      rewards: currentUser.rewards,
      level: currentUser.level,
    );
    mergedUsers.sort((a, b) {
      final expCompare = b.totalExp.compareTo(a.totalExp);
      if (expCompare != 0) return expCompare;
      return (originalOrder[a.id] ?? 0).compareTo(originalOrder[b.id] ?? 0);
    });
    return mergedUsers;
  }

  void _onResetToUserState(ResetToUserState event, Emitter<UserState> emit) async {
    // Only reset if we're actually in a leaderboard state and not actively loading
    if (state is LeaderboardLoaded || state is LeaderboardError) {
      // Check if we have a cached user state
      final isLoggedIn = await TokenStorageService.isLoggedIn();
      if (isLoggedIn) {
        // Try to load current user
        add(const LoadCurrentUser());
      } else {
        emit(UserUnauthenticated());
      }
    }
    // Don't reset if we're currently loading leaderboard data
  }



  // Helper method to get current user state without changing the state
  UserState? getCurrentUserState() {
    if (state is UserAuthenticated) {
      return state;
    }
    return null;
  }

  // Helper method to check if user is authenticated
  bool get isAuthenticated => state is UserAuthenticated;

  // Helper method to get current user (uses cached user for persistence across state changes)
  User? get currentUser {
    if (state is UserAuthenticated) {
      return (state as UserAuthenticated).user;
    }
    // Return cached user if available (persists across LeaderboardLoaded, etc.)
    return _cachedUser;
  }

  String? get currentClassName => _cachedClassName;
  String? get currentGradeName => _cachedGradeName;
}
