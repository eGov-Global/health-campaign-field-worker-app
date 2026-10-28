import 'package:digit_scanner/utils/scanner_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gs1_barcode_parser/gs1_barcode_parser.dart';

void main() {
  final utils = DigitScannerUtils();

  GS1Barcode parseBarcode() => GS1BarcodeParser.defaultParser().parse(
        utils.generateGS1Barcode(
          gtin: '01234567890128',
          batchNumber: 'B1',
          expiryDate: DateTime(2027, 1, 31),
        ),
      );

  group('manual-entry prefix', () {
    test('serializes only manually entered barcodes with the prefix', () {
      final plain = utils.serializeGs1Barcodes([parseBarcode()]);
      final serialized = utils.serializeGs1Barcodes(
          [parseBarcode(), ManualGS1Barcode.from(parseBarcode())]);

      expect(plain, startsWith('01:01234567890128|10:B1|17:'));
      expect(serialized, '$plain;(manual)$plain');
    });

    test('omits the prefix when serializing for comparison', () {
      final plain = utils.serializeGs1Barcodes([parseBarcode()]);
      expect(
        utils.serializeGs1Barcodes([ManualGS1Barcode.from(parseBarcode())],
            withManualPrefix: false),
        plain,
      );
    });

    test('deserializes a prefixed barcode like an unprefixed one', () {
      final plain = utils.serializeGs1Barcodes([parseBarcode()]);
      expect(DigitScannerUtils.deserializeGs1Barcodes('(manual)$plain'),
          DigitScannerUtils.deserializeGs1Barcodes(plain));
      expect(DigitScannerUtils.isManualEntry('(manual)$plain'), isTrue);
      expect(DigitScannerUtils.isManualEntry(plain), isFalse);
    });
  });
}
