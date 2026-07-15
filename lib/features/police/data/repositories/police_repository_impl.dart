import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/police_report.dart';
import '../../domain/repositories/police_repository.dart';
import '../models/police_report_model.dart';

class PoliceRepositoryImpl implements PoliceRepository {
  final SupabaseClient _supabaseClient;

  PoliceRepositoryImpl(this._supabaseClient);

  @override
  Future<String> reportIncident({
    required double latitude,
    required double longitude,
    required String category,
    required String description,
    String? evidencePath,
  }) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user found for submitting police reports.');
    }

    final response = await _supabaseClient.from('police_reports').insert({
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'evidence_path': evidencePath,
      'category': category,
      'description': description,
      'status': 'REPORTED',
    }).select().single();

    return response['id'] as String;
  }

  @override
  Stream<PoliceReport> subscribeToPoliceReportUpdates(String reportId) {
    final controller = StreamController<PoliceReport>();

    _fetchAndEmit(reportId, controller);

    final channel = _supabaseClient.channel('police_report_updates_$reportId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'police_reports',
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

  Future<void> _fetchAndEmit(String reportId, StreamController<PoliceReport> controller) async {
    try {
      final response = await _supabaseClient
          .from('police_reports')
          .select()
          .eq('id', reportId)
          .single();

      final model = PoliceReportModel.fromJson(response);
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

final policeRepositoryProvider = Provider<PoliceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PoliceRepositoryImpl(client);
});
