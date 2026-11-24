import 'package:collection/collection.dart';
import 'package:digit_data_model/models/entities/user_action.dart';
import 'package:transit_post/data/repositories/local/user_action.dart';

import 'stock_calculation_utils.dart';

/// Additional-field key on a STOCK_BALANCE UserAction that holds its signed
/// stock count for a facility (or distributor) × product variant.
///
///   Stock Balance = StockModel count + UserAction count
///
/// * StockModel count — every stock transaction (receipt, issue, return,
///   loss, damage; rejected dispatches excluded), derived from StockModel
///   rows by [StockCalculationUtils].
/// * UserAction count — stock movements that have no StockModel row. Written
///   by `StockBalanceExecutor` from the registration delivery flow: each
///   delivery lowers it by the quantity delivered.
///
/// See [addUserActionCounts].
const String userActionCountFieldKey = 'count';

/// Signed stock count recorded on [row].
///
/// Returns 0 when [row] is null or was written before this field existed
/// (such rows carry only the old running `balance`, which is no longer read).
double userActionCountOf(UserActionModel? row) {
  final raw = row?.additionalFields?.fields
      .firstWhereOrNull((f) => f.key == userActionCountFieldKey)
      ?.value
      ?.toString();
  return double.tryParse(raw ?? '') ?? 0.0;
}

/// Loads the UserAction counts for [facilityId] × [productIds] from the local
/// STOCK_BALANCE rows, keyed by productVariantId. Products with no row are
/// left out, which callers treat as a count of zero.
Future<Map<String, double>> loadUserActionCounts({
  required UserActionLocalRepository repository,
  required String facilityId,
  required List<String> productIds,
}) async {
  if (facilityId.isEmpty || productIds.isEmpty) return {};

  final productByKey = {
    for (final productId in productIds)
      generateBalanceKey(facilityId, productId): productId,
  };
  final rows = await repository.search(
    UserActionSearchModel(clientReferenceId: productByKey.keys.toList()),
  );

  final counts = <String, double>{};
  for (final row in rows) {
    final productId = productByKey[row.clientReferenceId];
    if (productId == null) continue;
    counts[productId] = userActionCountOf(row);
  }
  return counts;
}

/// Stock balance per product: [stockModelCounts] (derived from StockModel
/// rows) plus [userActionCounts]. Returns one entry per product in
/// [stockModelCounts].
Map<String, double> addUserActionCounts(
  Map<String, double> stockModelCounts,
  Map<String, double> userActionCounts,
) {
  return {
    for (final entry in stockModelCounts.entries)
      entry.key: entry.value + (userActionCounts[entry.key] ?? 0.0),
  };
}
