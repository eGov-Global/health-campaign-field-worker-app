import 'package:collection/collection.dart';
import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/entities/user_action.dart';
import 'package:digit_flow_builder/action_handler/action_config.dart';
import 'package:digit_flow_builder/action_handler/executors/action_executor.dart';
import 'package:digit_flow_builder/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:transit_post/data/repositories/local/user_action.dart';

import '../models/entities/roles_type.dart';
import '../utils/stock_calculation_utils.dart';
import '../utils/stock_user_action_count.dart';
import '../utils/utils.dart';

/// Executor that maintains the UserAction count of STOCK_BALANCE records:
///
///   Stock Balance = StockModel count + UserAction count
///
/// Used by the registration delivery flows: configured as
/// `UPDATE_STOCK_BALANCE` (`"entity": "TaskModel"`) right after the
/// `CREATE_EVENT` that saves the delivery task. For each delivered resource
/// of the newly created task(s) in `contextData['entities']` it lowers the
/// [userActionCountFieldKey] of the affected facility (or distributor) ×
/// product variant row by the delivered quantity.
///
/// Stock transactions (receipt, issue, return, loss, damage) are not written
/// to the UserAction — the inventory configs no longer call this action.
/// They are StockModel rows and make up the StockModel count
/// ([StockCalculationUtils]). An older inventory config that still fires
/// `UPDATE_STOCK_BALANCE` is accepted and ignored.
class StockBalanceExecutor extends ActionExecutor {
  String _getLoggedInUserUuid(BuildContext context) {
    final flowBuilderUuid = FlowBuilderSingleton().loggedInUserUuid;
    final String? contextUuid = _tryGetContextUuid(context);
    final result = flowBuilderUuid ?? contextUuid ?? '';

    return result;
  }

  String? _tryGetContextUuid(BuildContext context) {
    try {
      return context.loggedInUserUuid;
    } catch (_) {
      return null;
    }
  }

  @override
  bool canHandle(String actionType) => actionType == 'UPDATE_STOCK_BALANCE';

  @override
  Future<Map<String, dynamic>> execute(
    ActionConfig action,
    BuildContext context,
    Map<String, dynamic> contextData,
  ) async {
    try {
      // Only the entities produced for this delivery. `existingModels` is
      // deliberately not used as a fallback: in registration it can carry the
      // household's earlier tasks, whose deliveries are already counted.
      final entities = contextData['entities'];
      if (entities == null || entities is! List || entities.isEmpty) {
        debugPrint('UPDATE_STOCK_BALANCE: No entities found');
        return contextData;
      }

      final projectId = FlowBuilderSingleton().projectId;
      final boundaryCode =
          FlowBuilderSingleton().selectedProject?.address?.boundary;

      if (projectId == null || boundaryCode == null) {
        debugPrint('UPDATE_STOCK_BALANCE: Missing projectId or boundaryCode');
        return contextData;
      }

      // Auto-detect entity type from the entities in contextData,
      // falling back to the action config property if present
      final hasTask = entities.any((e) => e is TaskModel);
      final entityType = action.properties['entity'] as String?;

      if (hasTask || entityType == 'TASK' || entityType == 'TaskModel') {
        await _handleTaskEntity(context, entities, projectId, boundaryCode);
      } else {
        debugPrint(
          'UPDATE_STOCK_BALANCE: No task entities — stock transactions are '
          'read from StockModel rows, nothing to record',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('UPDATE_STOCK_BALANCE error: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    return contextData;
  }

  Future<void> _handleTaskEntity(
    BuildContext context,
    List<dynamic> entities,
    String projectId,
    String boundaryCode,
  ) async {
    final taskEntities = entities.whereType<TaskModel>().toList();
    if (taskEntities.isEmpty) {
      debugPrint('_handleTaskEntity: No task entities found');
      return;
    }

    // Read everything needed from [context] before the first await.
    final userActionRepo = context.read<UserActionLocalRepository>();
    final projectFacilityRepo = context.read<
        LocalRepository<ProjectFacilityModel, ProjectFacilitySearchModel>>();
    final loggedInUserUuid = _getLoggedInUserUuid(context);
    final tenantId = context.selectedProject.tenantId;

    final isDistributor = context.loggedInUserRoles.any((role) =>
        role.code == RolesType.distributor.toValue() ||
        role.code == RolesType.communityDistributor.toValue());

    final deliveredQuantities = <String, double>{};

    for (final task in taskEntities) {
      final resources = task.resources;
      if (resources == null || resources.isEmpty) continue;

      for (final resource in resources) {
        if (resource.isDelivered != true) continue;

        final productVariantId = resource.productVariantId;
        if (productVariantId == null) continue;

        final quantity = double.tryParse(resource.quantity ?? '0') ?? 0;
        deliveredQuantities[productVariantId] =
            (deliveredQuantities[productVariantId] ?? 0) + quantity;
      }
    }

    String? facilityId;
    if (isDistributor) {
      facilityId = loggedInUserUuid;
    } else {
      final projectFacilities = await projectFacilityRepo.search(
        ProjectFacilitySearchModel(projectId: [projectId]),
      );

      final currentFacilities = projectFacilities.where((pf) {
        final facilityLevel = pf.additionalFields?.fields
            .where((f) => f.key == 'facilityLevel')
            .firstOrNull
            ?.value;
        return facilityLevel == null || facilityLevel == 'current';
      }).toList();

      if (currentFacilities.isNotEmpty) {
        facilityId = currentFacilities.first.facilityId;
      }
    }

    if (facilityId == null || facilityId.isEmpty) {
      debugPrint(
          '_handleTaskEntity: facilityId is null, skipping delivery update');
      return;
    }

    for (final entry in deliveredQuantities.entries) {
      await _recordDelivery(
        userActionRepo: userActionRepo,
        loggedInUserUuid: loggedInUserUuid,
        tenantId: tenantId,
        facilityId: facilityId,
        productVariantId: entry.key,
        deliveredQuantity: entry.value,
        projectId: projectId,
        boundaryCode: boundaryCode,
      );
    }
  }

  /// Lowers the UserAction count of [facilityId] × [productVariantId] by
  /// [deliveredQuantity]. [deliveredQuantity] is negative for a return
  /// through a task, which raises the count.
  ///
  /// A row written by an older app version has no count and starts from
  /// zero; its old `balance` field is dropped on this write.
  Future<void> _recordDelivery({
    required UserActionLocalRepository userActionRepo,
    required String loggedInUserUuid,
    required String? tenantId,
    required String facilityId,
    required String productVariantId,
    required double deliveredQuantity,
    required String projectId,
    required String boundaryCode,
  }) async {
    final balanceKey = generateBalanceKey(facilityId, productVariantId);

    final existing = (await userActionRepo.search(
      UserActionSearchModel(clientReferenceId: [balanceKey]),
    ))
        .firstOrNull;

    final previousCount = userActionCountOf(existing);
    final count = previousCount - deliveredQuantity;

    final now = DateTime.now().millisecondsSinceEpoch;

    final balanceAction = UserActionModel(
      clientReferenceId: balanceKey,
      action: 'STOCK_BALANCE',
      projectId: projectId,
      boundaryCode: boundaryCode,
      latitude: 0.0,
      longitude: 0.0,
      locationAccuracy: 0.0,
      isSync: false,
      timestamp: now,
      id: existing?.id,
      rowVersion: existing?.rowVersion,
      tenantId: existing?.tenantId ?? tenantId,
      nonRecoverableError: false,
      additionalFields: UserActionAdditionalFields(
        version: 1,
        fields: [
          AdditionalField(userActionCountFieldKey, count.toString()),
          AdditionalField('facilityId', facilityId),
          AdditionalField('productVariantId', productVariantId),
          AdditionalField('deliveredQuantity', deliveredQuantity.toString()),
        ],
      ),
      auditDetails: existing?.auditDetails ??
          AuditDetails(
            createdBy: loggedInUserUuid,
            createdTime: now,
          ),
      clientAuditDetails: ClientAuditDetails(
        createdBy: existing?.clientAuditDetails?.createdBy ?? loggedInUserUuid,
        createdTime: existing?.clientAuditDetails?.createdTime ?? now,
        lastModifiedBy: loggedInUserUuid,
        lastModifiedTime: now,
      ),
    );

    if (existing != null) {
      await userActionRepo.update(balanceAction);
    } else {
      await userActionRepo.create(balanceAction);
    }

    debugPrint(
      'UPDATE_STOCK_BALANCE: UserAction count for $facilityId/$productVariantId = $count (previous: $previousCount, delivered: $deliveredQuantity, existing record: ${existing != null})',
    );
  }
}
