import 'package:dio/dio.dart';

/// Calls the server-side summary report API. The [AuthTokenInterceptor]
/// on the shared Dio client injects RequestInfo (with the auth token), so
/// only the search criteria is sent here.
class SummaryReportRemoteRepository {
  final Dio _client;
  final String searchPath;

  const SummaryReportRemoteRepository(
    this._client, {
    this.searchPath = 'product/summary/v1/_search',
  });

  Future<List<ServerSummaryReport>> search({
    required String tenantId,
    required int startDate,
    required int endDate,
  }) async {
    final response = await _client.post(
      searchPath,
      data: {
        'SummaryReportSearchCriteria': {
          'tenantId': tenantId,
          'startDate': startDate,
          'endDate': endDate,
        },
      },
    );

    final data = response.data;
    if (data is! Map) return const [];

    final reports = data['SummaryReports'];
    if (reports is! List) return const [];

    return reports
        .whereType<Map>()
        .map(ServerSummaryReport.fromJson)
        .whereType<ServerSummaryReport>()
        .toList();
  }
}

class ServerSummaryReport {
  /// `yyyy-MM-dd`
  final String date;
  final String createdBy;
  final int householdsRegistered;
  final int individualRegistered;
  final int beneficiariesRegistered;
  final int childrenTreated;

  /// productVariantId -> quantity consumed on [date]
  final Map<String, double> stockConsumedMap;

  const ServerSummaryReport({
    required this.date,
    required this.createdBy,
    required this.householdsRegistered,
    required this.individualRegistered,
    required this.beneficiariesRegistered,
    required this.childrenTreated,
    required this.stockConsumedMap,
  });

  static ServerSummaryReport? fromJson(Map json) {
    final date = json['date'];
    final createdBy = json['createdBy'];
    if (date is! String || date.isEmpty) return null;
    if (createdBy is! String || createdBy.isEmpty) return null;

    final consumed = <String, double>{};
    final rawConsumed = json['stockConsumedMap'];
    if (rawConsumed is Map) {
      for (final entry in rawConsumed.entries) {
        consumed[entry.key.toString()] =
            (entry.value as num?)?.toDouble() ?? 0.0;
      }
    }

    return ServerSummaryReport(
      date: date,
      createdBy: createdBy,
      householdsRegistered:
          (json['householdsRegistered'] as num?)?.toInt() ?? 0,
      individualRegistered:
          (json['individualRegistered'] as num?)?.toInt() ?? 0,
      beneficiariesRegistered:
          (json['beneficiariesRegistered'] as num?)?.toInt() ?? 0,
      childrenTreated: (json['childrenTreated'] as num?)?.toInt() ?? 0,
      stockConsumedMap: consumed,
    );
  }
}
