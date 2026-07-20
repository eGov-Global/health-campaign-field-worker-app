import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/summary_report_remote_repository.dart';

class ServerSummaryReportStorage {
  static const String storageKey = 'ServerSummaryReport';

  ServerSummaryReportStorage._();

  static final ServerSummaryReportStorage instance =
      ServerSummaryReportStorage._();

  Future<void> writeSummaryReports({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
    required List<ServerSummaryReport> reports,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final root = _readRoot(prefs);
    final reportKey = _buildReportKey(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );

    final existingEntry = root[reportKey];
    final existingData = existingEntry is Map
        ? Map<String, dynamic>.from(existingEntry['data'] as Map? ?? {})
        : <String, dynamic>{};

    for (final report in reports) {
      existingData[report.date] = {
        'householdsRegistered': report.householdsRegistered,
        'childrenTreated': report.childrenTreated,
        'childrenRegistered': report.beneficiariesRegistered,
        'stockConsumedMap': report.stockConsumedMap,
      };
    }

    root[reportKey] = {
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'data': existingData,
    };

    await prefs.setString(storageKey, jsonEncode({storageKey: root}));
  }

  Future<Map<String, dynamic>?> readSummaryReportData({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final root = _readRoot(prefs);
    final reportKey = _buildReportKey(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );

    final entry = root[reportKey];
    if (entry is! Map) return null;

    return Map<String, dynamic>.from(entry);
  }

  Future<Map<String, dynamic>> readAllSummaryReportData() async {
    final prefs = await SharedPreferences.getInstance();
    return {storageKey: _readRoot(prefs)};
  }

  Future<void> clearSummaryReportData() async {
    final prefs = await SharedPreferences.getInstance();
    final root = _readRoot(prefs)..clear();
    await prefs.setString(storageKey, jsonEncode({storageKey: root}));
  }

  Map<String, dynamic> _readRoot(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final root = decoded[storageKey];
      if (root is Map) {
        return Map<String, dynamic>.from(root);
      }
      return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  String _buildReportKey({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) {
    return '${userUuid}_${projectId}_$cycleIndex';
  }
}
