import 'package:digit_forms_engine/helper/validator_helper.dart';
import 'package:digit_forms_engine/models/property_schema/property_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

void main() {
  group('ValidationRule and buildValidators', () {
    test('required validation', () {
      final schema = PropertySchema(
        type: PropertySchemaType.string,
        label: 'Name',
        validations: [
          ValidationRule(type: 'required', value: true, message: 'Required!'),
        ],
      );
      final validators = buildValidators(schema);
      final form = FormGroup({
        'name': FormControl<String>(validators: validators),
      });
      expect(form.control('name').valid, isFalse);
      form.control('name').value = 'John';
      expect(form.control('name').valid, isTrue);
    });

    test('minLength and maxLength validation', () {
      final schema = PropertySchema(
        type: PropertySchemaType.string,
        label: 'Username',
        validations: [
          ValidationRule(type: 'minLength', value: 3, message: 'Too short'),
          ValidationRule(type: 'maxLength', value: 5, message: 'Too long'),
        ],
      );
      final validators = buildValidators(schema);
      final form = FormGroup({
        'username': FormControl<String>(validators: validators),
      });
      form.control('username').value = 'Jo';
      expect(form.control('username').valid, isFalse);
      form.control('username').value = 'John';
      expect(form.control('username').valid, isTrue);
      form.control('username').value = 'Johnny';
      expect(form.control('username').valid, isFalse);
    });

    test('pattern validation', () {
      final schema = PropertySchema(
        type: PropertySchemaType.string,
        label: 'Email',
        validations: [
          ValidationRule(
              type: 'pattern',
              value: r'^\S+@\S+\.\S+$',
              message: 'Invalid email'),
        ],
      );
      final validators = buildValidators(schema);
      final form = FormGroup({
        'email': FormControl<String>(validators: validators),
      });
      form.control('email').value = 'not-an-email';
      expect(form.control('email').valid, isFalse);
      form.control('email').value = 'test@example.com';
      expect(form.control('email').valid, isTrue);
    });

    test('min and max value validation', () {
      final schema = PropertySchema(
        type: PropertySchemaType.integer,
        label: 'Age',
        validations: [
          ValidationRule(type: 'min', value: 18, message: 'Too young'),
          ValidationRule(type: 'max', value: 60, message: 'Too old'),
        ],
      );
      final validators = buildValidators(schema);
      final form = FormGroup({
        'age': FormControl<int>(validators: validators),
      });
      form.control('age').value = 15;
      expect(form.control('age').valid, isFalse);
      form.control('age').value = 30;
      expect(form.control('age').valid, isTrue);
      form.control('age').value = 70;
      expect(form.control('age').valid, isFalse);
    });
  });

  group('scanCountMatch validation', () {
    final scannerSchema = PropertySchema(
      type: PropertySchemaType.string,
      format: PropertySchemaFormat.scanner,
      validations: [
        ValidationRule(type: 'required', value: true, message: 'Required'),
        ValidationRule(
          type: 'scanCountMatch',
          value: 'resourceCard.quantityDistributed',
          message: 'Mismatch',
        ),
      ],
    );

    FormGroup buildForm(dynamic resourceCard) => FormGroup({
          'resourceCard': FormControl<dynamic>(value: resourceCard),
          'scanner': FormControl<String>(
            validators: buildValidators(scannerSchema),
          ),
        });

    List<Map<String, dynamic>> rows(List<int> quantities) => quantities
        .map((q) => {
              'resourceDelivered': {'name': 'BEDNET', 'productId': 'P1'},
              'quantityDistributed': q,
            })
        .toList();

    test('passes only when scanned count equals the quantity', () {
      final form = buildForm(rows([3]));
      final scanner = form.control('scanner');

      expect(scanner.hasError('required'), isTrue);

      scanner.value = 'QR1, QR2';
      expect(scanner.hasError('scanCountMatch'), isTrue);

      scanner.value = 'QR1, QR2, QR3';
      expect(scanner.valid, isTrue);

      scanner.value = 'QR1, QR2, QR3, QR4';
      expect(scanner.hasError('scanCountMatch'), isTrue);
    });

    test('sums quantities across resource rows', () {
      final form = buildForm(rows([2, 1]));
      form.control('scanner').value = 'QR1, QR2, QR3';
      expect(form.control('scanner').valid, isTrue);
    });

    test('catches a quantity change after scanning once re-validated', () {
      final form = buildForm(rows([2]));
      final scanner = form.control('scanner');
      scanner.value = 'QR1, QR2';
      expect(scanner.valid, isTrue);

      form.control('resourceCard').value = rows([3]);
      scanner.updateValueAndValidity();
      expect(scanner.hasError('scanCountMatch'), isTrue);
    });

    test('skips the count check while the resource card has no quantity', () {
      final form = buildForm(null);
      form.control('scanner').value = 'QR1';
      expect(form.control('scanner').valid, isTrue);
    });

    test('is flagged as a cross-field rule', () {
      expect(hasCrossFieldValidation(scannerSchema), isTrue);
      expect(
        hasCrossFieldValidation(PropertySchema(
          type: PropertySchemaType.string,
          validations: [ValidationRule(type: 'required', value: true)],
        )),
        isFalse,
      );
    });

    test('counts QR and GS1 scanner values', () {
      expect(countScannedCodes(null), 0);
      expect(countScannedCodes(''), 0);
      expect(countScannedCodes('QR1'), 1);
      expect(countScannedCodes('QR1, QR2, QR3'), 3);
      expect(countScannedCodes('01:123|21:A;01:123|21:B'), 2);
    });
  });

  group('idPopulator ID number', () {
    const idSchema = PropertySchema(
      type: PropertySchemaType.string,
      format: PropertySchemaFormat.idPopulator,
    );

    // Mirrors the page form: the field plus the idType control the widget
    // registers. The field holds "<idType>, <idNumber>" or null.
    FormGroup buildForm({String? idType, String? identifiers}) {
      final form = FormGroup({
        'identifiers': FormControl<String>(
          value: identifiers,
          validators: buildValidators(idSchema),
        ),
        idPopulatorTypeKey: FormControl<String>(value: idType),
      });
      form.control('identifiers').updateValueAndValidity();
      return form;
    }

    test('requires the number once a real ID type is picked', () {
      final form = buildForm(idType: 'CNI');
      final field = form.control('identifiers');
      expect(field.hasError(idNumberRequiredErrorKey), isTrue);

      field.value = 'CNI, 12345';
      expect(field.valid, isTrue);

      field.value = null;
      expect(field.hasError(idNumberRequiredErrorKey), isTrue);
    });

    test('does not require a number for the DEFAULT (no ID) type', () {
      expect(buildForm(idType: 'DEFAULT').control('identifiers').valid,
          isTrue);
    });

    test('skips the check before the widget registers the ID type', () {
      final form = FormGroup({
        'identifiers':
            FormControl<String>(validators: buildValidators(idSchema)),
      });
      form.control('identifiers').updateValueAndValidity();
      expect(form.control('identifiers').valid, isTrue);
    });

    test('catches a switch to a real ID type once re-validated', () {
      final form = buildForm(idType: 'DEFAULT');
      final field = form.control('identifiers');
      expect(field.valid, isTrue);

      // null -> null does not re-run validators on its own.
      form.control(idPopulatorTypeKey).value = 'CNI';
      field.value = null;
      expect(field.valid, isTrue);

      field.updateValueAndValidity();
      expect(field.hasError(idNumberRequiredErrorKey), isTrue);
    });

    test('is re-validated on submit as a cross-field field', () {
      expect(hasCrossFieldValidation(idSchema), isTrue);
    });
  });
}
