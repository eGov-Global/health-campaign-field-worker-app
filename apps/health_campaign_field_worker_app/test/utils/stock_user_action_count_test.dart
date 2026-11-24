import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/models/entities/user_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_campaign_field_worker_app/utils/stock_calculation_utils.dart';
import 'package:health_campaign_field_worker_app/utils/stock_user_action_count.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transit_post/data/repositories/local/user_action.dart';

class _MockUserActionRepo extends Mock implements UserActionLocalRepository {}

const _warehouse = 'F-2026-01-01-000001';
const _other = 'F-2026-01-01-000002';
const _distributor = '3f2b9c1e-4a5d-4e6f-8a7b-1c2d3e4f5a6b';
const _product = 'PVAR-2026-01-01-000001';
const _product2 = 'PVAR-2026-01-01-000002';

StockModel _stock({
  required String ref,
  required String senderId,
  required String receiverId,
  required String transactionType,
  required String quantity,
  String? status,
  String? stockEntryType,
  String productVariantId = _product,
}) {
  return StockModel(
    clientReferenceId: ref,
    productVariantId: productVariantId,
    senderId: senderId,
    receiverId: receiverId,
    transactionType: transactionType,
    quantity: quantity,
    additionalFields: StockAdditionalFields(
      version: 1,
      fields: [
        if (status != null) AdditionalField('status', status),
        if (stockEntryType != null)
          AdditionalField('stockEntryType', stockEntryType),
      ],
    ),
  );
}

UserActionModel _row(String key, List<AdditionalField> fields) {
  return UserActionModel(
    clientReferenceId: key,
    action: 'STOCK_BALANCE',
    projectId: 'project-id',
    boundaryCode: 'BOUNDARY',
    latitude: 0,
    longitude: 0,
    locationAccuracy: 0,
    isSync: true,
    tenantId: 'tenant',
    additionalFields: UserActionAdditionalFields(version: 1, fields: fields),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(UserActionSearchModel());
  });

  group('userActionCountOf', () {
    test('is zero for a missing row', () {
      expect(userActionCountOf(null), 0);
    });

    test('is zero for a row from an older app version (balance only)', () {
      final row = _row('k', const [AdditionalField('balance', '120')]);
      expect(userActionCountOf(row), 0);
    });

    test('reads the signed count', () {
      final row = _row('k', const [
        AdditionalField('balance', '120'),
        AdditionalField(userActionCountFieldKey, '-35.0'),
      ]);
      expect(userActionCountOf(row), -35);
    });
  });

  group('addUserActionCounts', () {
    test('adds UserAction counts and keeps products without a count', () {
      final result = addUserActionCounts(
        {_product: 100, _product2: 40},
        {_product: -30, 'not-in-stock-map': -5},
      );
      expect(result, {_product: 70, _product2: 40});
    });
  });

  group('loadUserActionCounts', () {
    late _MockUserActionRepo repo;

    setUp(() => repo = _MockUserActionRepo());

    test('maps rows back to products by balance key', () async {
      final key1 = generateBalanceKey(_distributor, _product);
      final key2 = generateBalanceKey(_distributor, _product2);
      when(() => repo.search(any())).thenAnswer((_) async => [
            _row(key1, const [AdditionalField(userActionCountFieldKey, '-12')]),
            // Older-format row: counts as zero.
            _row(key2, const [AdditionalField('balance', '80')]),
          ]);

      final counts = await loadUserActionCounts(
        repository: repo,
        facilityId: _distributor,
        productIds: const [_product, _product2],
      );

      expect(counts, {_product: -12, _product2: 0});
      final query = verify(() => repo.search(captureAny())).captured.single
          as UserActionSearchModel;
      expect(query.clientReferenceId, unorderedEquals([key1, key2]));
    });

    test('skips the lookup when there is nothing to load', () async {
      expect(
        await loadUserActionCounts(
          repository: repo,
          facilityId: '',
          productIds: const [_product],
        ),
        isEmpty,
      );
      expect(
        await loadUserActionCounts(
          repository: repo,
          facilityId: _warehouse,
          productIds: const [],
        ),
        isEmpty,
      );
      verifyNever(() => repo.search(any()));
    });
  });

  group('Stock Balance = StockModel count + UserAction count', () {
    test('warehouse: rejected dispatch stays in hand, deliveries deducted',
        () {
      final stocks = [
        _stock(
          ref: 'in-1',
          senderId: _other,
          receiverId: _warehouse,
          transactionType: 'RECEIVED',
          quantity: '200',
        ),
        _stock(
          ref: 'out-1',
          senderId: _warehouse,
          receiverId: _other,
          transactionType: 'DISPATCHED',
          quantity: '50',
        ),
        _stock(
          ref: 'out-rejected',
          senderId: _warehouse,
          receiverId: _other,
          transactionType: 'DISPATCHED',
          quantity: '30',
          status: 'REJECTED',
        ),
        _stock(
          ref: 'loss-1',
          senderId: _warehouse,
          receiverId: _other,
          transactionType: 'DISPATCHED',
          quantity: '5',
          stockEntryType: 'LOSS',
        ),
      ];

      final stockModelCounts =
          StockCalculationUtils.calculateStockInHandForProducts(
        stockList: stocks,
        facilityId: _warehouse,
        productIds: const [_product],
      );
      expect(stockModelCounts[_product], 145);

      // 20 delivered → UserAction count −20.
      expect(
        addUserActionCounts(stockModelCounts, {_product: -20})[_product],
        125,
      );
    });

    test('distributor: rejected return stays in hand, deliveries deducted',
        () {
      final stocks = [
        _stock(
          ref: 'in-1',
          senderId: _warehouse,
          receiverId: _distributor,
          transactionType: 'RECEIVED',
          quantity: '100',
        ),
        _stock(
          ref: 'return-rejected',
          senderId: _distributor,
          receiverId: _warehouse,
          transactionType: 'DISPATCHED',
          quantity: '10',
          status: 'REJECTED',
          stockEntryType: 'RETURNED',
        ),
        _stock(
          ref: 'return-1',
          senderId: _distributor,
          receiverId: _warehouse,
          transactionType: 'DISPATCHED',
          quantity: '15',
          stockEntryType: 'RETURNED',
        ),
      ];

      final stockModelCounts =
          StockCalculationUtils.calculateStockInHandForProducts(
        stockList: stocks,
        facilityId: _distributor,
        productIds: const [_product],
        isDistributor: true,
      );
      expect(stockModelCounts[_product], 85);

      // 40 delivered → UserAction count −40.
      expect(
        addUserActionCounts(stockModelCounts, {_product: -40})[_product],
        45,
      );
    });
  });
}
