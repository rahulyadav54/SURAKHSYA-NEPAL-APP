import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../data/repositories/responder_repository.dart';

class ResponderDashboardState {
  final String availabilityStatus;
  final Map<String, dynamic>? activeDispatch;
  final bool isLoading;
  final String? errorMessage;

  const ResponderDashboardState({
    this.availabilityStatus = 'OFFLINE',
    this.activeDispatch,
    this.isLoading = false,
    this.errorMessage,
  });

  ResponderDashboardState copyWith({
    String? availabilityStatus,
    Map<String, dynamic>? activeDispatch,
    bool? isLoading,
    String? errorMessage,
    bool clearActiveDispatch = false,
  }) {
    return ResponderDashboardState(
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      activeDispatch: clearActiveDispatch ? null : (activeDispatch ?? this.activeDispatch),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ResponderController extends StateNotifier<ResponderDashboardState> {
  final ResponderRepository _repository;
  final SupabaseClient _supabase;
  final Ref _ref;
  RealtimeChannel? _dispatchSubscription;
  String? _responderId;

  ResponderController(this._repository, this._supabase, this._ref)
      : super(const ResponderDashboardState()) {
    _init();
  }

  void _init() async {
    final authState = _ref.read(authControllerProvider);
    if (authState is Authenticated) {
      final firebaseUid = authState.profile.id;
      final statusMap = await _repository.getResponderStatus(firebaseUid);
      if (statusMap != null) {
        _responderId = statusMap['id'] as String;
        state = state.copyWith(
          availabilityStatus: statusMap['availability_status'] as String? ?? 'OFFLINE',
        );
        _subscribeToDispatches();
        _checkForPendingDispatches();
      }
    }
  }

  /// Check for any pending dispatches on startup
  Future<void> _checkForPendingDispatches() async {
    if (_responderId == null) return;
    try {
      final pendingDispatches = await _supabase
          .from('dispatch_requests')
          .select('id')
          .eq('responder_id', _responderId!)
          .eq('status', 'PENDING')
          .limit(1);

      if (pendingDispatches.isNotEmpty) {
        final dispatchId = pendingDispatches[0]['id'] as String;
        await _fetchDispatchDetails(dispatchId);
      }
    } catch (_) {}
  }

  /// Subscribe to realtime dispatches for this responder
  void _subscribeToDispatches() {
    if (_responderId == null) return;

    _dispatchSubscription = _supabase
        .channel('public:dispatch_requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dispatch_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'responder_id',
            value: _responderId!,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;

            final status = record['status'] as String?;
            if (status == 'PENDING') {
              _fetchDispatchDetails(record['id'] as String);
            } else if (status == 'REJECTED' || status == 'EXPIRED' || status == 'CANCELLED' || status == 'ACCEPTED') {
              state = state.copyWith(clearActiveDispatch: true);
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchDispatchDetails(String dispatchId) async {
    try {
      final dispatch = await _supabase
          .from('dispatch_requests')
          .select('*, emergency_requests(*)')
          .eq('id', dispatchId)
          .maybeSingle();

      if (dispatch != null) {
        state = state.copyWith(activeDispatch: dispatch);
      }
    } catch (_) {}
  }

  /// Toggle availability status
  Future<void> toggleAvailability(bool online) async {
    final newStatus = online ? 'AVAILABLE' : 'OFFLINE';
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authControllerProvider);
      if (authState is Authenticated) {
        await _repository.updateAvailability(authState.profile.id, newStatus);
        state = state.copyWith(availabilityStatus: newStatus, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Accept incoming dispatch
  Future<void> acceptDispatch(String dispatchId, String emergencyId) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Update dispatch_requests status
      await _supabase
          .from('dispatch_requests')
          .update({'status': 'ACCEPTED', 'accepted_at': DateTime.now().toIso8601String()})
          .eq('id', dispatchId);

      // 2. Update emergency_requests status and assigned responder
      await _supabase
          .from('emergency_requests')
          .update({'status': 'ACCEPTED', 'assigned_responder_id': _responderId})
          .eq('id', emergencyId);

      // 3. Update responder status to BUSY/EN_ROUTE
      final authState = _ref.read(authControllerProvider);
      if (authState is Authenticated) {
        await _repository.updateAvailability(authState.profile.id, 'EN_ROUTE');
      }

      state = state.copyWith(
        availabilityStatus: 'EN_ROUTE',
        isLoading: false,
        clearActiveDispatch: true,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// Reject incoming dispatch
  Future<void> rejectDispatch(String dispatchId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase
          .from('dispatch_requests')
          .update({'status': 'REJECTED', 'rejected_at': DateTime.now().toIso8601String()})
          .eq('id', dispatchId);

      state = state.copyWith(isLoading: false, clearActiveDispatch: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    if (_dispatchSubscription != null) {
      _supabase.removeChannel(_dispatchSubscription!);
    }
    super.dispose();
  }
}

final responderControllerProvider =
    StateNotifierProvider.autoDispose<ResponderController, ResponderDashboardState>((ref) {
  final repository = ref.watch(responderRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return ResponderController(repository, supabase, ref);
});
