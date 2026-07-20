import 'package:digit_data_model/models/entities/project_type.dart';

import '../local_store/server_summary_report_storage.dart';
import '../repositories/summary_report_remote_repository.dart';

class ServerSummaryReportService {
  final ServerSummaryReportStorage storage;
  final Map<String, dynamic> _cachedReportsByKey = <String, dynamic>{};
  bool _initialized = false;
  String? _activeUserUuid;
  String? _activeProjectId;
  ProjectCycle? _activeCycle;

  ServerSummaryReportService({
    required this.storage,
  });

  Future<void> initializeFromStorage() async {
    if (_initialized) {
      return;
    }

    await _reloadCacheFromStorage();
  }

  Future<void> _reloadCacheFromStorage() async {
    final storedData = await storage.readAllSummaryReportData();
    final root = storedData[ServerSummaryReportStorage.storageKey];
    if (root is Map) {
      _cachedReportsByKey
        ..clear()
        ..addAll(Map<String, dynamic>.from(root));
    } else {
      _cachedReportsByKey.clear();
    }

    _initialized = true;
  }

  Map<String, dynamic> get cachedReportsByKey =>
      Map<String, dynamic>.unmodifiable(_cachedReportsByKey);

  Future<void> initializeForContext({
    required String userUuid,
    required String projectId,
    required ProjectCycle currentCycle,
  }) async {
    _activeUserUuid = userUuid;
    _activeProjectId = projectId;
    _activeCycle = currentCycle;
    await initializeFromStorage();
  }

  String? get activeUserUuid => _activeUserUuid;
  String? get activeProjectId => _activeProjectId;
  ProjectCycle? get activeCycle => _activeCycle;

  Future<void> syncSummaryReports({
    required String userUuid,
    required String projectId,
    required ProjectCycle currentCycle,
    required List<ServerSummaryReport> reports,
  }) async {
    if (reports.isEmpty) {
      return;
    }

    await storage.writeSummaryReports(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: currentCycle.id,
      reports: reports,
    );

    await _reloadCacheFromStorage();
  }

  Future<Map<String, dynamic>?> readSummaryReportData({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) async {
    await initializeFromStorage();
    return _getReportByKey(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );
  }

  Future<int?> readSummaryReportTimestamp({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) async {
    final report = await readSummaryReportData(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );
    return _toNullableInt(report?['timeStamp']);
  }

  Future<Map<String, dynamic>> readAllSummaryReportData() async {
    await initializeFromStorage();
    return {
      ServerSummaryReportStorage.storageKey:
          Map<String, dynamic>.from(_cachedReportsByKey),
    };
  }

  Future<Map<String, dynamic>?> readActiveSummaryReportData() async {
    await initializeFromStorage();

    if (_activeUserUuid == null ||
        _activeProjectId == null ||
        _activeCycle == null) {
      return null;
    }

    return _getReportByKey(
      userUuid: _activeUserUuid!,
      projectId: _activeProjectId!,
      cycleIndex: _activeCycle!.id,
    );
  }

  Future<int?> timestamp() async {
    final report = await readActiveSummaryReportData();
    return _toNullableInt(report?['timeStamp']) ?? _activeCycle?.startDate;
  }

  Future<Map<String, dynamic>?> readActiveSummaryReportDayData({
    required String date,
  }) async {
    await initializeFromStorage();
    final report = await readActiveSummaryReportData();

    final data = report?['data'];
    if (data is! Map) {
      return null;
    }

    final dayData = data[date];
    if (dayData is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(dayData);
  }

  Future<int> householdRegistration({
    String? date,
  }) async {
    if (date != null && date.isNotEmpty) {
      final dayData = await readActiveSummaryReportDayData(date: date);
      return _toInt(dayData?['householdsRegistered']);
    }

    final allDayData = await _readAllActiveDayData();
    var total = 0;
    for (final dayData in allDayData.values) {
      total += _toInt(dayData['householdsRegistered']);
    }
    return total;
  }

  Future<int> childrenTreated({
    String? date,
  }) async {
    if (date != null && date.isNotEmpty) {
      final dayData = await readActiveSummaryReportDayData(date: date);
      return _toInt(dayData?['childrenTreated']);
    }

    final allDayData = await _readAllActiveDayData();
    var total = 0;
    for (final dayData in allDayData.values) {
      total += _toInt(dayData['childrenTreated']);
    }
    return total;
  }

  Future<int> childrenRegistered({
    String? date,
  }) async {
    if (date != null && date.isNotEmpty) {
      final dayData = await readActiveSummaryReportDayData(date: date);
      return _toInt(dayData?['childrenRegistered']);
    }

    final allDayData = await _readAllActiveDayData();
    var total = 0;
    for (final dayData in allDayData.values) {
      total += _toInt(dayData['childrenRegistered']);
    }
    return total;
  }

  Future<Map<String, double>> stockConsumedMap({
    String? date,
  }) async {
    if (date != null && date.isNotEmpty) {
      final dayData = await readActiveSummaryReportDayData(date: date);
      return _parseStockConsumedMap(dayData?['stockConsumedMap']);
    }

    final allDayData = await _readAllActiveDayData();
    final aggregated = <String, double>{};
    for (final dayData in allDayData.values) {
      final current = _parseStockConsumedMap(dayData['stockConsumedMap']);
      for (final entry in current.entries) {
        aggregated[entry.key] = (aggregated[entry.key] ?? 0.0) + entry.value;
      }
    }
    return aggregated;
  }

  Future<List<String>> allDates() async {
    final allDayData = await _readAllActiveDayData();
    final dates = allDayData.keys.toList()..sort();
    return dates;
  }

  Future<Map<String, dynamic>?> readSummaryReportDayData({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
    required String date,
  }) async {
    await initializeFromStorage();
    final report = _getReportByKey(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );

    final data = report?['data'];
    if (data is! Map) {
      return null;
    }

    final dayData = data[date];
    if (dayData is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(dayData);
  }

  Future<void> clearSummaryReportData() async {
    await storage.clearSummaryReportData();
    _cachedReportsByKey.clear();
    _initialized = true;
    _activeUserUuid = null;
    _activeProjectId = null;
    _activeCycle = null;
  }

  Map<String, dynamic>? _getReportByKey({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) {
    final reportKey = _buildReportKey(
      userUuid: userUuid,
      projectId: projectId,
      cycleIndex: cycleIndex,
    );

    final entry = _cachedReportsByKey[reportKey];
    if (entry is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(entry);
  }

  String _buildReportKey({
    required String userUuid,
    required String projectId,
    required int cycleIndex,
  }) {
    return '${userUuid}_${projectId}_$cycleIndex';
  }

  Future<Map<String, Map<String, dynamic>>> _readAllActiveDayData() async {
    await initializeFromStorage();
    final report = await readActiveSummaryReportData();
    final data = report?['data'];
    if (data is! Map) {
      return <String, Map<String, dynamic>>{};
    }

    final dayDataMap = <String, Map<String, dynamic>>{};
    for (final entry in data.entries) {
      if (entry.value is Map) {
        dayDataMap[entry.key.toString()] =
            Map<String, dynamic>.from(entry.value as Map);
      }
    }
    return dayDataMap;
  }

  Map<String, double> _parseStockConsumedMap(dynamic raw) {
    if (raw is! Map) {
      return <String, double>{};
    }

    final parsed = <String, double>{};
    for (final entry in raw.entries) {
      parsed[entry.key.toString()] = _toDouble(entry.value);
    }
    return parsed;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
