import 'package:digit_forms_engine/helper/form_builder_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../models/property_schema/property_schema.dart';

// Global registry for page schemas - used by validators to access cross-page values
final Map<String, Map<String, PropertySchema>> _pagesRegistry = {};

// Global registry for navigation params - used by validators to access navigation values
final Map<String, Map<String, dynamic>> _navigationParamsRegistry = {};

void registerPagesForValidation(
    String schemaKey, Map<String, PropertySchema> pages) {
  _pagesRegistry[schemaKey] = pages;
}

void unregisterPagesForValidation(String schemaKey) {
  _pagesRegistry.remove(schemaKey);
}

void registerNavigationParams(
    String schemaKey, Map<String, dynamic> navigationParams) {
  _navigationParamsRegistry[schemaKey] = navigationParams;
}

void unregisterNavigationParams(String schemaKey) {
  _navigationParamsRegistry.remove(schemaKey);
}

/// Resolves a value that may be a navigation param reference (e.g., "navigation.stockBalance")
/// Returns the resolved value or null if not found
dynamic _resolveNavigationValue(dynamic value, String? schemaKey) {
  if (value is! String || schemaKey == null) return value;
  if (!value.startsWith('navigation.')) return value;

  final navParams = _navigationParamsRegistry[schemaKey];
  if (navParams == null) return null;

  // Extract the key after "navigation."
  final key = value.substring('navigation.'.length);
  return navParams[key];
}

List<Validator<T>> buildValidators<T>(PropertySchema schema,
    {String? schemaKey}) {
  final List<Validator<T>> validators = [];

  if (schema.validations != null) {
    for (final rule in schema.validations!) {
      switch (rule.type) {
        case 'minLength':
          final parsedValue = parseIntValue(rule.value);

          if (schema.type != PropertySchemaType.integer) {
            if (parsedValue != null) {
              validators.add(Validators.composeOR([
                Validators.minLength(parsedValue) as Validator<T>,
                Validators.composeOR(
                    [Validators.equals(''), Validators.equals(null)]),
              ]) as Validator<T>);
            }
          }

          break;

        case 'maxLength':
          final parsedValue = parseIntValue(rule.value);
          if (parsedValue != null &&
              schema.type != PropertySchemaType.integer) {
            validators.add(Validators.composeOR([
              Validators.maxLength(parsedValue) as Validator<T>,
              Validators.composeOR(
                  [Validators.equals(''), Validators.equals(null)]),
            ]) as Validator<T>);
          }
          break;

        case 'min':
        case 'minValue':
          // Check if value is a navigation param reference
          if (rule.value is String &&
              rule.value.startsWith('navigation.') &&
              schemaKey != null) {
            validators.add(Validators.delegate((control) {
              final resolvedValue =
                  _resolveNavigationValue(rule.value, schemaKey);
              final minVal = parseIntValue(resolvedValue);
              if (minVal == null || control.value == null) return null;
              final numValue = num.tryParse(control.value.toString());
              if (numValue == null) return null;
              if (numValue < minVal) {
                return {
                  'min': {'min': minVal, 'actual': numValue}
                };
              }
              return null;
            }) as Validator<T>);
          } else {
            final parsedValue = parseIntValue(rule.value);
            if (parsedValue != null) {
              // Use delegate validator to handle both numeric and string values
              validators.add(Validators.delegate((control) {
                if (control.value == null || control.value.toString().isEmpty) {
                  return null; // Allow null/empty values (required validation handles this)
                }
                final numValue = num.tryParse(control.value.toString());
                if (numValue == null) return null; // Not a valid number, skip
                if (numValue < parsedValue) {
                  return {
                    'min': {'min': parsedValue, 'actual': numValue}
                  };
                }
                return null;
              }) as Validator<T>);
            }
          }
          break;

        case 'max':
        case 'maxValue':
          // Check if value is a navigation param reference
          if (rule.value is String &&
              rule.value.startsWith('navigation.') &&
              schemaKey != null) {
            validators.add(Validators.delegate((control) {
              final resolvedValue =
                  _resolveNavigationValue(rule.value, schemaKey);
              final maxVal = parseIntValue(resolvedValue);
              if (maxVal == null || control.value == null) return null;
              final numValue = num.tryParse(control.value.toString());
              if (numValue == null) return null;
              if (numValue > maxVal) {
                return {
                  'max': {'max': maxVal, 'actual': numValue}
                };
              }
              return null;
            }) as Validator<T>);
          } else {
            final parsedValue = parseIntValue(rule.value);
            if (parsedValue != null) {
              // Use delegate validator to handle both numeric and string values
              validators.add(Validators.delegate((control) {
                if (control.value == null || control.value.toString().isEmpty) {
                  return null; // Allow null/empty values (required validation handles this)
                }
                final numValue = num.tryParse(control.value.toString());
                if (numValue == null) return null; // Not a valid number, skip
                if (numValue > parsedValue) {
                  return {
                    'max': {'max': parsedValue, 'actual': numValue}
                  };
                }
                return null;
              }) as Validator<T>);
            }
          }
          break;

        case 'pattern':
          if (rule.value is List && rule.value.isNotEmpty) {
            validators.add(Validators.composeOR([
              Validators.pattern(RegExp(rule.value.first)) as Validator<T>,
              Validators.composeOR(
                  [Validators.equals(''), Validators.equals(null)]),
            ]) as Validator<T>);
          } else if (rule.value is String && rule.value.isNotEmpty) {
            validators.add(Validators.composeOR([
              Validators.pattern(RegExp(rule.value)) as Validator<T>,
              Validators.composeOR(
                  [Validators.equals(''), Validators.equals(null)]),
            ]) as Validator<T>);
          }
          break;

        case 'required':
          if (rule.value == true) {
            // Checkbox controls default to `false`, which Validators.required
            // treats as a present value — a required checkbox would never
            // block submission. Require the value to be `true` instead.
            // Scoped to checkboxes: boolean radios render `false` as a
            // legitimate "No" answer.
            if (schema.type == PropertySchemaType.boolean &&
                schema.format == PropertySchemaFormat.checkbox) {
              validators.add(Validators.requiredTrue as Validator<T>);
            } else {
              validators.add(Validators.required as Validator<T>);
            }
          }
          break;

        case 'notEqualTo':
          if (rule.value is String && schemaKey != null) {
            validators.add(Validators.delegate(
              (control) => _notEqualToValidator(
                  rule.value as String, control, schemaKey),
            ) as Validator<T>);
          }
          break;

        case 'scanCountMatch':
          // The number of scanned codes must equal a count held by another
          // field on the same page, e.g. "resourceCard.quantityDistributed".
          if (rule.value is String && (rule.value as String).isNotEmpty) {
            final path = rule.value as String;
            validators.add(Validators.delegate((control) {
              final form = control.parent;
              if (form is! FormGroup) return null;
              final expected = resolveExpectedScanCount(form, path);
              // No count to compare against yet; the source field's own
              // validation reports that.
              if (expected == null || expected <= 0) return null;
              final scanned = countScannedCodes(control.value);
              if (scanned == expected) return null;
              return {
                'scanCountMatch': {'expected': expected, 'actual': scanned}
              };
            }) as Validator<T>);
          }
          break;

        default:
          if (kDebugMode) {
            // print('Unknown validation type: ${rule.type}');
          }
          break;
      }
    }
  }

  return validators;
}

/// Rule types whose result depends on another field's value. Their cached
/// result goes stale when that other field changes, so they are re-run on
/// submit.
const Set<String> _crossFieldValidationTypes = {'scanCountMatch'};

/// Whether [schema] has a rule that reads another field's value.
bool hasCrossFieldValidation(PropertySchema? schema) {
  return schema?.validations
          ?.any((rule) => _crossFieldValidationTypes.contains(rule.type)) ??
      false;
}

/// Counts the codes held by a scanner field value. QR codes are stored
/// comma-separated; GS1 barcodes are stored ';'-separated, with '|' between
/// the parts of one barcode.
int countScannedCodes(dynamic value) {
  if (value == null) return 0;
  final raw = value.toString().trim();
  if (raw.isEmpty) return 0;
  final isGs1 = raw.contains('|') || RegExp(r'^\d{2}:').hasMatch(raw);
  return raw
      .split(isGs1 ? ';' : ',')
      .where((code) => code.trim().isNotEmpty)
      .length;
}

/// Reads the number of codes a scanner field must hold from another field
/// in [form]. [path] is "<field>" or "<field>.<key>[.<key>...]". When the
/// field holds a list (e.g. resource card rows), the value at the key path
/// is summed across the rows. Returns null when nothing numeric is found.
int? resolveExpectedScanCount(FormGroup form, String path) {
  final segments = path.split('.').map((s) => s.trim()).toList();
  final fieldName = segments.first;
  if (!form.contains(fieldName)) return null;
  final keys = segments.skip(1).toList();

  num? readNumber(dynamic node) {
    dynamic current = node;
    for (final key in keys) {
      if (current is! Map) return null;
      current = current[key];
    }
    if (current is num) return current;
    return current == null ? null : num.tryParse(current.toString());
  }

  final fieldValue = form.control(fieldName).value;
  if (fieldValue is List) {
    num? total;
    for (final item in fieldValue) {
      final number = readNumber(item);
      if (number != null) total = (total ?? 0) + number;
    }
    return total?.toInt();
  }
  return readNumber(fieldValue)?.toInt();
}

/// Checks if the validations contain a rule of type 'required'.
bool hasRequiredValidation(List<ValidationRule>? validations) {
  if (validations == null) return false;

  return validations
      .any((rule) => rule.type == 'required' && rule.value == true);
}

int? getMinValue(List<ValidationRule>? validations) {
  if (validations == null) return null;

  for (final rule in validations) {
    if (rule.type == 'min' || rule.type == 'minValue') {
      return parseIntValue(rule.value);
    }
  }
  return null;
}

int? getMaxValue(List<ValidationRule>? validations) {
  if (validations == null) return null;

  for (final rule in validations) {
    if (rule.type == 'max' || rule.type == 'maxValue') {
      return parseIntValue(rule.value);
    }
  }
  return null;
}

int? getMinLength(List<ValidationRule>? validations) {
  if (validations == null) return null;

  for (final rule in validations) {
    if (rule.type == 'minLength') {
      return parseIntValue(rule.value);
    }
  }
  return null;
}

int? getMaxLength(List<ValidationRule>? validations) {
  if (validations == null) return null;

  for (final rule in validations) {
    if (rule.type == 'maxLength') {
      return parseIntValue(rule.value);
    }
  }
  return null;
}

/// Custom validator that checks if a field's value is not equal to another field's value
/// Supports both current page fields and cross-page references using dot notation (e.g., 'warehouseDetails.facilityFromWhich')
Map<String, dynamic>? _notEqualToValidator(
    String otherFieldName, AbstractControl<dynamic> control, String schemaKey) {
  final form = control.parent;
  if (form is! FormGroup) return null;

  final currentValue = control.value;

  // Build flat value map from all pages
  final pages = _pagesRegistry[schemaKey];
  if (pages == null) return null;

  final flatValues = <String, dynamic>{};

  // Add current form values
  form.controls.forEach((key, control) {
    flatValues[key] = control.value;
  });

  // Add all page values with dot notation
  pages.forEach((pageKey, pageSchema) {
    if (pageSchema.properties != null) {
      pageSchema.properties!.forEach((fieldKey, fieldSchema) {
        flatValues['$pageKey.$fieldKey'] = fieldSchema.value;
      });
    }
  });

  debugPrint('Flat Values $flatValues');
  debugPrint('Looking for otherFieldName: $otherFieldName');

  // Look up the other field's value
  final otherValue = flatValues[otherFieldName];
  debugPrint('Found otherValue: $otherValue');

  // Allow null or empty values to pass (required validation handles that separately)
  if (currentValue == null ||
      currentValue == '' ||
      otherValue == null ||
      otherValue == '') {
    return null;
  }

  // Check if values are equal
  if (currentValue == otherValue) {
    return {'notEqualTo': true};
  }

  return null;
}
