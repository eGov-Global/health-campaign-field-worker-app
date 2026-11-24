import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/entities/user_action.dart';
import 'package:flutter/foundation.dart';
import 'package:transit_post/data/repositories/local/user_action.dart';

import '../data/local_store/secure_store/secure_store.dart';
import '../models/entities/roles_type.dart';
import 'stock_calculation_utils.dart';

/// Credits a sender's STOCK_BALANCE back when a dispatch it sent comes down
/// from the server marked REJECTED by the receiver.
///
/// Nothing on the receiver's side touches the sender's balance (see
/// StockBalanceExecutor), so this download-time credit is the only place the
/// rejected quantity is restored.
///
/// Shared by the manual "Sync Stock Data" download (StockDownSyncBloc) and the
/// silent download on project selection (ProjectBloc). Both advance the same
/// `stock_<projectId>` downsync record, so each rejected row is downloaded —
/// and credited — by only one of them on a given device.
///
/// Several devices can serve the same facility, and each downloads the
/// rejected row. To credit it only once, the balance row carries a credit
/// ledger: one AdditionalField per credited rejection, keyed
/// `rc_<stock clientReferenceId>` with the credited quantity as value. The
/// ledger travels with the balance row to the server, and a device sees
/// another device's credits only when its own copy of the row came from the
/// server after that credit — a row newly pulled by `downSyncStockBalances`,
/// or one replaced by upload confirmation. `downSyncStockBalances` never
/// overwrites a row already on the device (nothing sets `isSync` to true), so
/// a device working from an older copy will credit again. Its upload then
/// replaces the server row as a whole, which drops the other device's credit,
/// so the result is still one credit; the ledger only becomes a reliable
/// guard once balance rows are refreshed from the server. Writers that
/// rebuild the field list must carry the ledger over via
/// [creditLedgerFields] (see StockBalanceExecutor).
class StockRejectionReconciler {
  StockRejectionReconciler({
    required this.localSecureStore,
    required this.projectFacilityLocalRepository,
    required this.userActionLocalRepository,
  });

  final LocalSecureStore localSecureStore;
  final LocalRepository<ProjectFacilityModel, ProjectFacilitySearchModel>
      projectFacilityLocalRepository;
  final UserActionLocalRepository userActionLocalRepository;

  static const String _rejectedStatus = 'REJECTED';
  static const String _dispatchedTransaction = 'DISPATCHED';

  /// Key prefix of credit-ledger fields on a STOCK_BALANCE row.
  static const String creditKeyPrefix = 'rc_';

  /// Oldest ledger entries beyond this are dropped so the balance row — which
  /// is upsynced on every stock transaction — stays small. A dropped entry
  /// only matters if some device downloads that rejection for the first time
  /// after this many newer rejections were credited for the same
  /// facility × product.
  static const int maxCreditEntries = 100;

  /// The credit-ledger fields of a balance row, for writers that rebuild the
  /// field list and must not lose them.
  static List<AdditionalField> creditLedgerFields(
    List<AdditionalField>? fields,
  ) =>
      fields?.where((f) => f.key.startsWith(creditKeyPrefix)).toList() ??
      const [];

  /// Run after `downSyncStockBalances`, so balance rows this device doesn't
  /// have yet are pulled from the server first — a facility × product pair
  /// with no balance row on the device is skipped, not credited.
  ///
  /// [isInitialDownload] is true when this device has never completed a stock
  /// download for the project (no `lastSyncedTime` on the downsync record —
  /// it survives logout, so this means a fresh install or first use of the
  /// project on this device). That download pulls the project's full history,
  /// and the server balance may already include credits for those older
  /// rejections (upsynced from another install, or carried up by a later
  /// stock transaction in earlier app versions). Crediting them again would
  /// overstate the balance, so history is treated as settled and nothing is
  /// credited.
  Future<void> reconcile({
    required String projectId,
    required List<StockModel> stockEntries,
    required bool isInitialDownload,
    String? projectReferenceID,
  }) async {
    if (isInitialDownload || stockEntries.isEmpty) return;

    try {
      final userObject = await localSecureStore.userRequestModel;
      // Credits are written as this user (see stampBalanceWrite); without a
      // logged-in user the write could never be uploaded.
      final userUuid = userObject?.uuid;
      if (userUuid == null || userUuid.isEmpty) return;
      final userRoles = userObject?.roles.map((e) => e.code) ?? [];
      final isDistributor =
          userRoles.contains(RolesType.distributor.toValue()) ||
              userRoles.contains(RolesType.communityDistributor.toValue());

      final projectFacilities = await projectFacilityLocalRepository.search(
        ProjectFacilitySearchModel(projectId: [projectId]),
      );

      final currentFacilities = projectFacilities.where((pf) {
        final facilityLevel = pf.additionalFields?.fields
            .where((f) => f.key == 'facilityLevel')
            .firstOrNull
            ?.value;
        return facilityLevel == null || facilityLevel == 'current';
      }).toList();

      final facilityIds = isDistributor
          ? {userObject?.uuid ?? ''}
          : currentFacilities
              .map((e) => e.facilityId)
              .whereType<String>()
              .toSet();

      facilityIds.removeWhere((element) => element.isEmpty);
      if (facilityIds.isEmpty) return;

      // Rejections grouped by "<senderId>|<productVariantId>" so the credit
      // path can look up both the new and legacy balance row shapes from the
      // same (facility, productVariant) pair, then keyed by stock
      // clientReferenceId so each one is checked against the credit ledger.
      // The `|` separator is safe because neither id contains it.
      final rejectionsByPair = <String, Map<String, double>>{};

      for (final stock in stockEntries) {
        final senderId = stock.senderId;
        final productVariantId = stock.productVariantId;
        final status = _getAdditionalFieldValue(stock, 'status');
        final transactionType = stock.transactionType?.toUpperCase() ?? '';

        if (senderId == null ||
            productVariantId == null ||
            !facilityIds.contains(senderId) ||
            transactionType != _dispatchedTransaction ||
            status != _rejectedStatus) {
          continue;
        }

        final quantity = double.tryParse(stock.quantity ?? '0') ?? 0;
        if (quantity <= 0) continue;

        final pairKey = '$senderId|$productVariantId';
        rejectionsByPair.putIfAbsent(pairKey, () => {})[
            stock.clientReferenceId] = quantity;
      }

      for (final entry in rejectionsByPair.entries) {
        final parts = entry.key.split('|');
        await _creditRejections(
          parts[0],
          parts[1],
          entry.value,
          userUuid: userUuid,
          projectReferenceID: projectReferenceID,
        );
      }
    } catch (e) {
      debugPrint('Rejected stock balance reconciliation error: $e');
    }
  }

  /// Credits [rejections] (stock clientReferenceId → quantity) to the
  /// (facility, productVariant) balance row, skipping any already in the
  /// row's credit ledger. Looks up the new campaign-suffixed key first; if no
  /// row exists, falls back to the legacy key shape so a downsync that lands
  /// before the user has triggered the copy-on-first-touch migration still
  /// updates the correct row.
  Future<void> _creditRejections(
    String facilityId,
    String productVariantId,
    Map<String, double> rejections, {
    required String userUuid,
    String? projectReferenceID,
  }) async {
    if (rejections.isEmpty) return;

    final newKey = generateBalanceKey(
      facilityId,
      productVariantId,
      projectReferenceID: projectReferenceID,
    );
    var existing = await userActionLocalRepository.search(
      UserActionSearchModel(clientReferenceId: [newKey]),
    );

    if (existing.isEmpty) {
      final oldKey = legacyBalanceKey(facilityId, productVariantId);
      if (oldKey != newKey) {
        existing = await userActionLocalRepository.search(
          UserActionSearchModel(clientReferenceId: [oldKey]),
        );
      }
    }

    if (existing.isEmpty) return;

    final balanceAction = existing.first;
    final balanceFieldIndex = balanceAction.additionalFields?.fields
            .indexWhere((field) => field.key == 'balance') ??
        -1;

    if (balanceFieldIndex < 0) return;

    final currentBalance = double.tryParse(
          balanceAction.additionalFields?.fields[balanceFieldIndex].value ??
              '0',
        ) ??
        0;

    final existingFields = balanceAction.additionalFields?.fields ?? [];
    final alreadyCredited = creditLedgerFields(existingFields)
        .map((f) => f.key.substring(creditKeyPrefix.length))
        .toSet();
    final toCredit = {
      for (final r in rejections.entries)
        if (!alreadyCredited.contains(r.key)) r.key: r.value,
    };
    // Every rejection here was already credited (e.g. by another device on
    // the same facility, pulled down with the balance) — nothing to do.
    if (toCredit.isEmpty) return;

    final quantity = toCredit.values.fold<double>(0, (sum, q) => sum + q);

    final updatedFields = List<AdditionalField>.from(existingFields);
    updatedFields[balanceFieldIndex] = AdditionalField(
      'balance',
      (currentBalance + quantity).toString(),
    );
    for (final r in toCredit.entries) {
      updatedFields
          .add(AdditionalField('$creditKeyPrefix${r.key}', r.value.toString()));
    }
    // Trim the oldest ledger entries (earliest in the list) beyond the cap.
    var excess =
        updatedFields.where((f) => f.key.startsWith(creditKeyPrefix)).length -
            maxCreditEntries;
    if (excess > 0) {
      updatedFields.removeWhere((f) {
        if (excess > 0 && f.key.startsWith(creditKeyPrefix)) {
          excess--;
          return true;
        }
        return false;
      });
    }

    // Write with an op-log entry so the credit uploads on its own. Without
    // one it stayed on the device and reached the server only when this
    // device's next stock transaction rewrote the row. stampBalanceWrite marks
    // the write as this user's: an upload belongs to the row's last modifier,
    // and a device only uploads its own user's operations.
    await userActionLocalRepository.update(
      stampBalanceWrite(
        balanceAction.copyWith(
          isSync: false,
          additionalFields: UserActionAdditionalFields(
            version: balanceAction.additionalFields?.version ?? 1,
            fields: updatedFields,
          ),
        ),
        userUuid,
      ),
    );
  }

  String _getAdditionalFieldValue(StockModel stock, String key) {
    final fields = stock.additionalFields?.fields;
    if (fields == null) return '';
    for (final field in fields) {
      if (field.key == key) {
        return field.value?.toString().toUpperCase() ?? '';
      }
    }
    return '';
  }
}
