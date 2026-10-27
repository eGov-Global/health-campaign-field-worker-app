import 'dart:convert';

import 'package:digit_flow_builder/utils/scanner_comparison_utils.dart';
import 'package:digit_forms_engine/forms_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('storedValueContains', () {
    test('finds a plain QR code inside a stored comma-separated list', () {
      const stored = 'QR1, QR2, QR3';
      expect(ScannerComparisonUtils.storedValueContains(stored, 'QR1'), isTrue);
      expect(ScannerComparisonUtils.storedValueContains(stored, 'QR2'), isTrue);
      expect(ScannerComparisonUtils.storedValueContains(stored, 'QR3'), isTrue);
    });

    test('does not match a different or partial QR code', () {
      const stored = 'QR10, QR20';
      expect(ScannerComparisonUtils.storedValueContains(stored, 'QR1'), isFalse);
      expect(ScannerComparisonUtils.storedValueContains(stored, 'QR30'), isFalse);
    });

    test('matches a single stored QR code', () {
      expect(ScannerComparisonUtils.storedValueContains('QR1', 'QR1'), isTrue);
    });

    test('matches QR codes that contain a GS1 group separator', () {
      const code1 = '010123456789012890TEC-IT\x1D8200https://www.tec-it.com';
      const code2 = '010123456789012890TEC-IT\x1D8200https://www.tec-it.';
      const stored = '$code1, $code2';
      expect(ScannerComparisonUtils.storedValueContains(stored, code1), isTrue);
      expect(ScannerComparisonUtils.storedValueContains(stored, code2), isTrue);
      expect(
        ScannerComparisonUtils.storedValueContains(
            stored, '010123456789012890TEC-IT\x1D8200https://other'),
        isFalse,
      );
    });

    test('still matches GS1 barcodes regardless of key order', () {
      const stored = '01:123|21:SERIAL1;01:123|21:SERIAL2';
      expect(
        ScannerComparisonUtils.storedValueContains(stored, '21:SERIAL2|01:123'),
        isTrue,
      );
      expect(
        ScannerComparisonUtils.storedValueContains(stored, '01:123|21:OTHER'),
        isFalse,
      );
    });
  });

  group('jsonSafeFragments', () {
    test('splits on characters JSON escapes', () {
      expect(
        ScannerComparisonUtils.jsonSafeFragments(
            '0101234TEC-IT\x1D8200https://x.com'),
        ['0101234TEC-IT', '8200https://x.com'],
      );
      expect(ScannerComparisonUtils.jsonSafeFragments('A"B\\C'),
          ['A', 'B', 'C']);
      expect(ScannerComparisonUtils.jsonSafeFragments('QR1'), ['QR1']);
    });

    test('every fragment appears in the stored JSON text', () {
      const code = '010123456789012890TEC-IT\x1D8200https://www.tec-it.com';
      final storedJson = jsonEncode({
        'fields': [
          {'key': 'scanner', 'value': '$code, OTHER'}
        ]
      });
      // The raw code is not in the JSON text (0x1D is escaped)...
      expect(storedJson.contains(code), isFalse);
      // ...but each fragment the SQL pre-filter searches for is.
      for (final fragment in ScannerComparisonUtils.jsonSafeFragments(code)) {
        expect(storedJson.contains(fragment), isTrue);
      }
    });
  });

  group('resolveFilterValue', () {
    test('resolves {{scannedValue}} to the code being checked', () {
      const filter = ComparisonFilter(
        key: 'additionalFields',
        value: '{{scannedValue}}',
        operation: 'matches',
      );
      expect(
        ScannerComparisonUtils.resolveFilterValue(filter, {}, {},
            scannedValue: 'QR1'),
        'QR1',
      );
    });

    test('keeps resolving form and navigation templates', () {
      const formFilter = ComparisonFilter(key: 'a', value: '{{form.x}}');
      const navFilter = ComparisonFilter(key: 'b', value: '{{navigation.y}}');
      expect(
        ScannerComparisonUtils.resolveFilterValue(formFilter, {'x': 1}, {}),
        '1',
      );
      expect(
        ScannerComparisonUtils.resolveFilterValue(navFilter, {}, {'y': 'Y'}),
        'Y',
      );
    });
  });
}
