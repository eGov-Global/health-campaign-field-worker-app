import 'package:digit_crud_bloc/digit_crud_bloc.dart';
import 'package:digit_forms_engine/forms_engine.dart';
import 'package:flutter/foundation.dart';

/// Utility class for scanner duplicate detection via DB queries.
///
/// Used by [ScannerComparisonProvider] in screen_builder to perform
/// per-scan duplicate checks against the local database when a barcode
/// or QR code is scanned.
class ScannerComparisonUtils {
  const ScannerComparisonUtils._();

  /// Prefix the scanner writes before a GS1 barcode typed in on its
  /// manual-entry form, e.g. `(manual)01:GTIN|10:BATCH`. Mirrors
  /// `DigitScannerUtils.manualEntryPrefix`; kept here because this package
  /// may resolve a digit_scanner release that predates it.
  static const manualEntryPrefix = '(manual)';

  /// Finds the [ComparisonConfig] for a given scanner field name in the schema.
  ///
  /// Handles multiEntityConfig suffix stripping: form control names like
  /// `scanResource_item_0` are matched against schema key `scanResource`.
  static ComparisonConfig? findComparisonConfig(
      SchemaObject schema, String fieldName) {
    // Strip _item_N suffix added by multiEntityConfig
    final baseFieldName = fieldName.replaceAll(RegExp(r'_item_\d+$'), '');
    for (final page in schema.pages.values) {
      final properties = page.properties;
      if (properties == null) continue;
      for (final entry in properties.entries) {
        if ((entry.key == fieldName || entry.key == baseFieldName) &&
            entry.value.format == PropertySchemaFormat.scanner) {
          return entry.value.comparisonConfig;
        }
      }
    }
    return null;
  }

  /// Gets the error message for duplicate detection for a given field.
  static String? getDuplicateErrorMessage(
      SchemaObject schema, String fieldName) {
    final config = findComparisonConfig(schema, fieldName);
    return config?.errorMessage;
  }

  /// Extracts all field values from all pages in the cached schema.
  /// Returns a flat map of fieldName -> value (across all pages).
  static Map<String, dynamic> extractAllSchemaValues(SchemaObject schema) {
    final allValues = <String, dynamic>{};
    for (final page in schema.pages.values) {
      final properties = page.properties;
      if (properties == null) continue;
      for (final entry in properties.entries) {
        final value = entry.value.value;
        if (value != null) {
          allValues[entry.key] = value;
        }
      }
    }
    return allValues;
  }

  /// Executes a per-scan duplicate check by querying the local DB.
  ///
  /// Looks up the [ComparisonConfig] for [fieldName] in the [schema],
  /// resolves filter values from [formValues] and [navigationParams],
  /// then queries the DB for matching entities.
  ///
  /// For `extractFrom: "column"` configs, the scanned value is added as
  /// a direct column filter — any result means duplicate.
  ///
  /// For `extractFrom: "additionalFields"` configs, results are fetched
  /// by senderId/receiverId filters, then each entity's additionalFields
  /// are checked for a matching extractKey value.
  static Future<bool> executeDuplicateCheck(
    SchemaObject schema,
    String compositeKey,
    String fieldName,
    String scannedValue,
    Map<String, dynamic> formValues,
    Map<String, dynamic> navigationParams,
  ) async {
    try {
      return await _executeDuplicateCheckInternal(
        schema,
        compositeKey,
        fieldName,
        scannedValue,
        formValues,
        navigationParams,
      );
    } catch (e, stackTrace) {
      // Log the full error for debugging, but do NOT block scanning.
      // The in-session duplicate check (bloc state comparison) still runs
      // as a safety net even when the DB check fails.
      debugPrint(
          'ScannerComparisonUtils: DB duplicate check failed, allowing scan.\n'
          'Error: $e\n'
          'StackTrace: $stackTrace');
      return false;
    }
  }

  /// Internal implementation of duplicate check. Exceptions propagate to
  /// [executeDuplicateCheck] which handles them gracefully.
  static Future<bool> _executeDuplicateCheckInternal(
    SchemaObject schema,
    String compositeKey,
    String fieldName,
    String scannedValue,
    Map<String, dynamic> formValues,
    Map<String, dynamic> navigationParams,
  ) async {
    // 1. Find comparisonConfig for fieldName in schema
    final config = findComparisonConfig(schema, fieldName);
    if (config == null) return false;

    // Build merged params from three sources (lowest to highest priority):
    // 1. allSchemaValues — facility fields cached from earlier pages
    // 2. formValues — current page's form control values (covers same-page
    //    fields or values not yet flushed to the schema cache)
    // 3. navigationParams — explicit navigation data (highest priority)
    final allSchemaValues = extractAllSchemaValues(schema);
    final mergedNavParams = <String, dynamic>{
      ...allSchemaValues,
      ...formValues,
      ...navigationParams,
    };

    // Resolve currentEntityId for multi-entity forms (e.g., stock with
    // multiple product variants). The screen_builder's navigationParams
    // doesn't include currentEntity (that's added at multi_entity_tab_view
    // level below the ScannerComparisonProvider), so we extract the product
    // variant ID from the schema's source field value using the entity index
    // embedded in the field name suffix (_item_N).
    if (!mergedNavParams.containsKey('currentEntityId')) {
      final entityIndex = _extractEntityIndex(fieldName);
      if (entityIndex != null) {
        final multiConfig = _findMultiEntityConfig(schema, fieldName);
        if (multiConfig != null) {
          final entities = allSchemaValues[multiConfig.sourceFieldKey];
          if (entities is List && entityIndex < entities.length) {
            final entity = entities[entityIndex];
            if (entity is Map && entity.containsKey('id')) {
              mergedNavParams['currentEntityId'] = entity['id'];
              debugPrint('ScannerComparisonUtils: Resolved currentEntityId='
                  '${entity['id']} from multiEntityConfig index=$entityIndex');
            }
          }
        }
      }
    }

    debugPrint('ScannerComparisonUtils: Config found for $fieldName, '
        'model=${config.model}, extractFrom=${config.extractFrom}');

    // 2. Separate filters into SQL-level and entity-level.
    // Filters with key prefix "additionalFields." are checked at entity level
    // against the entity's additionalFields after the SQL query.
    // All other filters become SQL WHERE clauses on direct columns.
    final sqlFilters = <ComparisonFilter>[];
    final entityAdditionalFieldFilters = <ComparisonFilter>[];
    for (final filter in config.filters) {
      if (filter.key.startsWith('additionalFields.')) {
        entityAdditionalFieldFilters.add(filter);
      } else {
        sqlFilters.add(filter);
      }
    }

    // 3. Resolve SQL filter values with switchOn/cases support
    final resolvedFilters = <SearchFilter>[];
    for (final filter in sqlFilters) {
      final resolvedValue = resolveFilterValue(
          filter, formValues, mergedNavParams,
          scannedValue: scannedValue);
      debugPrint('ScannerComparisonUtils: SQL filter ${filter.key} '
          'resolved to: $resolvedValue');
      if (resolvedValue == null || resolvedValue.isEmpty) continue;
      // additionalFields is stored as JSON text, where characters such as
      // the GS1 group separator (0x1D) or quotes are escaped (e.g.
      // "\u001d"), so a raw substring search would miss those rows. Search
      // for each run of characters JSON stores as-is instead; this only
      // narrows the query, the exact match runs on the decoded values below.
      final values = filter.operation == 'matches' &&
              config.extractFrom != 'column'
          ? jsonSafeFragments(resolvedValue)
          : [resolvedValue];
      for (final value in values) {
        resolvedFilters.add(SearchFilter(
          field: filter.key,
          operator: filter.operation,
          value: value,
          root: config.model,
        ));
      }
    }

    // Resolve entity-level additionalFields filter expected values upfront
    final resolvedEntityFilters = <String, String>{};
    for (final filter in entityAdditionalFieldFilters) {
      final afKey = filter.key.substring('additionalFields.'.length);
      final resolvedValue = resolveFilterValue(
          filter, formValues, mergedNavParams,
          scannedValue: scannedValue);
      debugPrint('ScannerComparisonUtils: Entity filter $afKey '
          'resolved to: $resolvedValue');
      if (resolvedValue != null && resolvedValue.isNotEmpty) {
        resolvedEntityFilters[afKey] = resolvedValue;
      }
    }

    // 4. For "column" match, add scanned value as direct filter. The same
    // code may be stored with the manual-entry prefix, so match that too.
    if (config.extractFrom == 'column') {
      resolvedFilters.add(SearchFilter(
        field: config.extractKey,
        operator: 'in',
        value: [scannedValue, '$manualEntryPrefix$scannedValue'],
        root: config.model,
      ));
    }

    if (resolvedFilters.isEmpty) {
      debugPrint(
          'ScannerComparisonUtils: No resolved SQL filters, skipping check');
      return false;
    }

    // 5. Execute search
    final service = CrudBlocSingleton().crudService;
    // Lazily initialize if not yet ready (matches CrudBloc._onSearch pattern)
    if (!service.isInitialized) {
      debugPrint('ScannerComparisonUtils: Initializing CrudService');
      service.init();
    }

    debugPrint('ScannerComparisonUtils: Executing search with '
        '${resolvedFilters.length} SQL filters on model ${config.model}');

    final (results, _) = await service.searchEntities(
      query: GlobalSearchParameters(
        filters: resolvedFilters,
        select: [config.model],
        primaryModel: config.model,
      ),
    );

    final entities = results[config.model] ?? [];
    debugPrint(
        'ScannerComparisonUtils: Found ${entities.length} matching entities');

    // 6. For "column" match: any result = duplicate
    if (config.extractFrom == 'column') {
      return entities.isNotEmpty;
    }

    // 7. For "additionalFields" match: check entity-level filters then barcode
    for (final entity in entities) {
      try {
        final additionalFields = (entity as dynamic).additionalFields;
        if (additionalFields == null) continue;

        // Check entity-level additionalFields filters first.
        // ALL filters must match for this entity to be considered a candidate.
        // e.g., stockEntryType must match the current transaction type.
        bool entityFiltersMatch = true;
        if (resolvedEntityFilters.isNotEmpty) {
          for (final entry in resolvedEntityFilters.entries) {
            bool found = false;
            for (final field in additionalFields.fields) {
              if (field.key == entry.key &&
                  field.value?.toString() == entry.value) {
                found = true;
                break;
              }
            }
            if (!found) {
              entityFiltersMatch = false;
              break;
            }
          }
        }
        if (!entityFiltersMatch) continue;

        // Entity-level filters passed — now check for barcode match
        for (final field in additionalFields.fields) {
          if (field.key == config.extractKey && field.value != null) {
            if (storedValueContains(field.value.toString(), scannedValue)) {
              debugPrint(
                  'ScannerComparisonUtils: DUPLICATE found in entity');
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('ScannerComparisonUtils: Entity parse failed: $e');
        continue;
      }
    }
    return false;
  }

  /// Resolves filter value, handling switchOn/cases for conditional values.
  ///
  /// When a filter has `switchOn` and `cases`, the switchOn template is resolved
  /// first to determine which case applies. For example, with stock entry types:
  /// - `switchOn: "{{navigation.stockEntryType}}"`
  /// - `cases: {"ISSUED": "{{navigation.facilityToWhich}}"}`
  /// - `value: "{{navigation.facilityFromWhich}}"` (default)
  ///
  /// If stockEntryType is "ISSUED", uses the ISSUED case template.
  /// Otherwise falls back to the default value template.
  static String? resolveFilterValue(
    ComparisonFilter filter,
    Map<String, dynamic> formValues,
    Map<String, dynamic> navigationParams, {
    String? scannedValue,
  }) {
    String template = filter.value;

    // Handle switchOn/cases for conditional filter values
    if (filter.switchOn != null && filter.cases != null) {
      final switchKey = resolveTemplate(
          filter.switchOn!, formValues, navigationParams,
          scannedValue: scannedValue);
      if (switchKey != null && filter.cases!.containsKey(switchKey)) {
        template = filter.cases![switchKey]!;
      }
    }

    return resolveTemplate(template, formValues, navigationParams,
        scannedValue: scannedValue);
  }

  /// Resolves a template string like `{{navigation.facilityFromWhich}}` to its value.
  ///
  /// Supports:
  /// - `form.` — looks up value in [formValues]
  /// - `navigation.` — looks up value in [navigationParams]
  /// - `scannedValue` — the code being checked. Lets a filter narrow the
  ///   SQL query to rows that mention it, e.g. a `matches` filter on the
  ///   `additionalFields` column.
  ///
  /// Static strings (without `{{`) are returned as-is.
  static String? resolveTemplate(
    String template,
    Map<String, dynamic> formValues,
    Map<String, dynamic> navigationParams, {
    String? scannedValue,
  }) {
    if (!template.contains('{{')) return template;

    final match = RegExp(r'^\{\{(.+?)\}\}$').firstMatch(template);
    if (match == null) return template;
    final path = match.group(1)!.trim();

    if (path == 'scannedValue') return scannedValue;
    if (path.startsWith('form.')) {
      return formValues[path.substring(5)]?.toString();
    }
    if (path.startsWith('navigation.')) {
      return navigationParams[path.substring(11)]?.toString();
    }
    return null;
  }

  /// Splits [value] into the runs of characters that JSON stores unescaped,
  /// dropping control characters, quotes and backslashes. Each run appears
  /// verbatim in the JSON text of a column that holds [value].
  static List<String> jsonSafeFragments(String value) {
    return value
        .split(RegExp(r'[\x00-\x1F"\\]'))
        .where((fragment) => fragment.isNotEmpty)
        .toList();
  }

  /// Whether [scannedValue] is one of the codes in [storedValue], a scanner
  /// value read back from the DB.
  static bool storedValueContains(String storedValue, String scannedValue) {
    final existingValues = extractComparisonValues(storedValue);
    // Normalize the scanned value so GS1 key ordering doesn't matter
    if (existingValues.contains(scannedValue) ||
        existingValues.contains(_normalizeBarcode(scannedValue))) {
      return true;
    }

    // Plain QR scans are stored as a comma-separated list ("QR1, QR2"),
    // which extractComparisonValues reads as one legacy GS1 barcode. Match
    // a plain scanned code against each entry of that list instead.
    final target = scannedValue.trim();
    final isGs1 =
        target.contains('|') || RegExp(r'^\d{2}:').hasMatch(target);
    if (target.isEmpty || isGs1) return false;
    return storedValue
        .split(RegExp('[,;]'))
        .any((code) => code.trim() == target);
  }

  /// Extracts comparison values from serialized GS1 barcode strings.
  ///
  /// Uses serial number (AI 21) when available, otherwise uses the full
  /// serialized barcode string as the comparison fingerprint.
  ///
  /// Supports both new format (`01:GTIN|10:BATCH|17:EXPIRY|21:SERIAL`)
  /// and legacy format (`GTIN,SERIAL,BATCH,EXPIRY`). For legacy entries,
  /// a normalized new-format string is also emitted so cross-format
  /// matching works correctly.
  static List<String> extractComparisonValues(String serializedData) {
    final values = <String>[];
    for (final barcode in serializedData.split(';')) {
      var trimmed = barcode.trim();
      // A manually entered code matches the same code scanned by camera
      if (trimmed.startsWith(manualEntryPrefix)) {
        trimmed = trimmed.substring(manualEntryPrefix.length).trim();
      }
      if (trimmed.isEmpty) continue;
      // Always add the full barcode string for full-match comparison
      values.add(trimmed);

      final isNewFormat =
          trimmed.contains('|') || RegExp(r'^\d{2}:').hasMatch(trimmed);

      if (isNewFormat) {
        // New format: key:value|key:value
        // Also emit a key-sorted normalized form for order-insensitive matching
        final normalized = _normalizeBarcode(trimmed);
        if (normalized != trimmed) {
          values.add(normalized);
        }
        for (final pair in trimmed.split('|')) {
          final colonIdx = pair.indexOf(':');
          if (colonIdx > 0) {
            final key = pair.substring(0, colonIdx).trim();
            final value = pair.substring(colonIdx + 1).trim();
            if (key == '21' && value.isNotEmpty) {
              values.add(value);
            }
          }
        }
      } else {
        // Legacy format: GTIN,SERIAL,BATCH,EXPIRY (positional)
        final parts = trimmed.split(',');
        final gtin = parts.isNotEmpty ? parts[0].trim() : '';
        final serial = parts.length > 1 ? parts[1].trim() : '';
        final batch = parts.length > 2 ? parts[2].trim() : '';
        final expiry = parts.length > 3 ? parts[3].trim() : '';

        // Extract serial for serial-based matching
        if (serial.isNotEmpty) {
          values.add(serial);
        }
        // Emit a normalized new-format string so a new-format scan
        // can match against this legacy DB row
        final normalized = <String>[];
        if (gtin.isNotEmpty) normalized.add('01:$gtin');
        if (expiry.isNotEmpty) normalized.add('17:$expiry');
        if (batch.isNotEmpty) normalized.add('10:$batch');
        if (serial.isNotEmpty) normalized.add('21:$serial');
        if (normalized.isNotEmpty) {
          values.add(normalized.join('|'));
        }
      }
    }
    return values;
  }

  /// Normalizes a new-format barcode by sorting key-value pairs by AI code.
  ///
  /// Ensures `01:GTIN|10:BATCH|17:EXPIRY` and `01:GTIN|17:EXPIRY|10:BATCH`
  /// produce the same string for order-insensitive comparison.
  static String _normalizeBarcode(String barcode) {
    if (!barcode.contains('|') && !RegExp(r'^\d{2}:').hasMatch(barcode)) {
      return barcode;
    }
    final pairs = barcode.split('|').map((p) => p.trim()).toList();
    pairs.sort();
    return pairs.join('|');
  }

  /// Extracts the entity index from a multi-entity field name suffix.
  ///
  /// e.g., `scanResource_item_0` → `0`, `scanResource` → `null`
  static int? _extractEntityIndex(String fieldName) {
    final match = RegExp(r'_item_(\d+)$').firstMatch(fieldName);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Finds the [MultiEntityConfig] for the page containing a given field.
  ///
  /// Strips the `_item_N` suffix and searches for the base field name
  /// across all pages. Returns the page's multiEntityConfig if found.
  static MultiEntityConfig? _findMultiEntityConfig(
      SchemaObject schema, String fieldName) {
    final baseFieldName = fieldName.replaceAll(RegExp(r'_item_\d+$'), '');
    for (final page in schema.pages.values) {
      final properties = page.properties;
      if (properties == null || page.multiEntityConfig == null) continue;
      if (properties.containsKey(baseFieldName)) {
        return page.multiEntityConfig;
      }
    }
    return null;
  }
}
