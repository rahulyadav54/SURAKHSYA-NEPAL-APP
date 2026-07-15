import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/fire_report.dart';
import '../../domain/repositories/fire_repository.dart';
import '../models/fire_report_model.dart';

class FireRepositoryImpl implements FireRepository {
  final SupabaseClient _supabaseClient;

  FireRepositoryImpl(this._supabaseClient);

  @override
  Future<String> reportFire({
    required double latitude,
    required double longitude,
    String? imagePath,
    String? videoPath,
    required String description,
    required String aiSeverity,
  }) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user found for submitting fire reports.');
    }

    final response = await _supabaseClient.from('fire_reports').insert({
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'image_path': imagePath,
      'video_path': videoPath,
      'description': description,
      'ai_predicted_severity': aiSeverity,
      'status': 'REPORTED',
    }).select().single();

    return response['id'] as String;
  }

  @override
  Stream<FireReport> subscribeToFireReportUpdates(String reportId) {
    final controller = StreamController<FireReport>();

    _fetchAndEmit(reportId, controller);

    final channel = _supabaseClient.channel('fire_report_updates_$reportId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'fire_reports',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: reportId,
      ),
      callback: (payload) {
        _fetchAndEmit(reportId, controller);
      },
    ).subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmit(String reportId, StreamController<FireReport> controller) async {
    try {
      final response = await _supabaseClient
          .from('fire_reports')
          .select()
          .eq('id', reportId)
          .single();

      final model = FireReportModel.fromJson(response);
      if (!controller.isClosed) {
        controller.add(model);
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }
}

final fireRepositoryProvider = Provider<FireRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FireRepositoryImpl(client);
});
