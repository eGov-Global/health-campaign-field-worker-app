part of 'json_schema_builder.dart';

class JsonSchemaIdPopulatorBuilder extends JsonSchemaBuilder<int> {
  final int? maxValue;
  final List<Option>? enums;
  final int? minValue;

  const JsonSchemaIdPopulatorBuilder({
    required super.formControlName,
    required super.form,
    this.enums,
    super.key,
    super.value,
    this.maxValue,
    this.minValue,
    super.label,
    super.helpText,
    super.innerLabel,
    super.readOnly,
    super.validations,
    super.isRequired,
    super.tooltipText,
  });

  @override
  Widget build(BuildContext context) {
    const idKey = 'idNumber';
    const idTypeKey = idPopulatorTypeKey;
    const idAutoFilledKey = 'idAutoFilled';
    const beneficiaryIdType = 'UNIQUE_BENEFICIARY_ID';
    const defaultIdType = idPopulatorDefaultType;

    final loc = FormLocalization.of(context);
    final validationMessages = buildValidationMessages(validations, loc);
    // Error from idNumberRequiredValidator: reuse the field's own required
    // message when configured, else the common one.
    validationMessages.putIfAbsent(
      idNumberRequiredErrorKey,
      () =>
          validationMessages['required'] ??
          (_) => loc.translate('CORE_COMMON_REQUIRED'),
    );

    final defaultValues = context.read<Map<String, dynamic>>();
    final identifiers = defaultValues['availableIDs'];

    /// Register controls
    if (!form.contains(idKey)) {
      form.addAll({
        idKey: FormControl<String>(),
      });
    }

    if (!form.contains(idTypeKey)) {
      form.addAll({
        idTypeKey: FormControl<String>(
          validators: isRequired ?? false ? [Validators.required] : [],
        ),
      });
    }

    if (!form.contains(idAutoFilledKey)) {
      form.addAll({
        idAutoFilledKey: FormControl<bool>(value: false),
      });
    }

    /// Populate from defaultValues using formControlName key (first priority)
    final defaultValue = defaultValues[formControlName];

    // Parse the original edit-flow combined value once so that
    // onSelect can restore the beneficiary's existing ID number when the
    // user toggles idType away and then back to whatever type it was
    // originally saved with. Without this, switching to DEFAULT and back
    // leaves the ID number field empty because the availableIDs map
    // typically doesn't re-include the type currently on the record.
    String? originalEditIdType;
    String? originalEditIdNumber;
    final originalCombinedForEdit = defaultValue;
    if (originalCombinedForEdit is String &&
        originalCombinedForEdit.contains(',')) {
      final origParts = originalCombinedForEdit.split(',');
      if (origParts.length >= 2) {
        originalEditIdType = origParts[0].trim();
        originalEditIdNumber = origParts.sublist(1).join(',').trim();
        if (originalEditIdNumber.isEmpty) originalEditIdNumber = null;
      }
    }

    // Check if this field has a direct value from navigationParams
    // (e.g., UNIQUE_BENEFICIARY_ID from navigation data)
    String? navParamValue;
    try {
      final navigationParams = context.read<Map<String, dynamic>?>();
      if (navigationParams != null &&
          navigationParams.containsKey(formControlName)) {
        navParamValue = navigationParams[formControlName] as String?;
      }
    } catch (_) {}

    // Use navParamValue if defaultValue doesn't have type format
    final valueToUse = (defaultValue is String && defaultValue.contains(','))
        ? defaultValue
        : (navParamValue ?? defaultValue as String?);

    String? resolveDefaultBeneficiaryId() {
      final navigationParams = context.read<Map<String, dynamic>?>();
      final navBeneficiaryId = navigationParams?[beneficiaryIdType];
      if (navBeneficiaryId is String && navBeneficiaryId.isNotEmpty) {
        return navBeneficiaryId;
      }

      final availableBeneficiaryId = identifiers?[beneficiaryIdType];
      if (availableBeneficiaryId is String && availableBeneficiaryId.isNotEmpty) {
        return availableBeneficiaryId;
      }

      return null;
    }

    void applyDefaultBeneficiarySelection() {
      final beneficiaryId = resolveDefaultBeneficiaryId();
      form.control(idTypeKey).value = defaultIdType;
      form.control(idAutoFilledKey).value = beneficiaryId != null;
      form.control(idKey).value = beneficiaryId;
      form.control(formControlName).value = beneficiaryId == null
          ? null
          : '$beneficiaryIdType, $beneficiaryId';
    }

    if (valueToUse != null &&
        form.control(idTypeKey).value == null &&
        form.control(idKey).value == null) {
      final parts = valueToUse.split(',');
      if (parts.length >= 2) {
        final type = parts[0].trim();
        final number = parts.sublist(1).join(',').trim();

        if (type == beneficiaryIdType || type == defaultIdType) {
          applyDefaultBeneficiarySelection();
        } else {
          form.control(idTypeKey).value = type;
          form.control(idKey).value = number;
          form.control(idAutoFilledKey).value = true;
          form.control(formControlName).value = '$type, $number';
        }
      }
    }

    /// Populate from combined value (edit case)
    final combinedValue = form.control(formControlName).value;
    if (combinedValue != null && combinedValue is String) {
      final parts = combinedValue.split(' ');
      if (parts.length >= 2) {
        final type = parts[0];
        final number = parts.sublist(1).join(' ');

        if (form.control(idTypeKey).value == null && type != beneficiaryIdType) {
          form.control(idTypeKey).value = type;
        }
        if (form.control(idKey).value == null &&
            type != defaultIdType &&
            type != beneficiaryIdType) {
          form.control(idKey).value = number;
          form.control(idAutoFilledKey).value = true;
        }
      }
    }

    final currentCombinedValue = form.control(formControlName).value;
    final hasCombinedValue = currentCombinedValue is String &&
        currentCombinedValue.trim().isNotEmpty;
    if (form.control(idTypeKey).value == null && !hasCombinedValue) {
      applyDefaultBeneficiarySelection();
    }

    /// Helper to update combined value
    void updateCombinedIdentifier() {
      final idType = form.control(idTypeKey).value;
      final idNumber = form.control(idKey).value;

      if (idType != null &&
          idNumber != null &&
          idNumber.toString().trim().isNotEmpty) {
        form.control(formControlName).value = '$idType, $idNumber';
      } else {
        form.control(formControlName).value = null;
      }
    }

    /// The ID-number check reads the ID type. Setting the field to the value
    /// it already holds (e.g. null -> null when switching type) skips
    /// validation, so re-check it after every type change.
    void revalidateIdNumber() {
      form.control(formControlName).updateValueAndValidity();
    }

    final isIdTypeMissing =
        (form.control(idTypeKey).value?.toString().trim().isEmpty ?? true);
    final filteredIdTypeOptions =
        (enums ?? []).where((e) => e.code != beneficiaryIdType).toList();

    return Column(
      children: [
        /// ID TYPE DROPDOWN
        ReactiveWrapperField(
          formControlName: formControlName,
          validationMessages: validationMessages,
          showErrors: (control) => control.invalid && control.touched,
          builder: (field) => LabeledField(
            infoText: translateIfPresent(tooltipText, loc),
            label: label,
            capitalizedFirstLetter: false,
            isRequired: isRequired ?? false,
            child: DigitDropdown<String>(
              helpText: helpText,
              errorMessage: isIdTypeMissing ? field.errorText : null,
              selectedOption: form.control(idTypeKey).value != null
                  ? DropdownItem(
                      code: form.control(idTypeKey).value!,
                      name: loc.translate(
                        filteredIdTypeOptions
                            .firstWhere(
                              (e) => e.code == form.control(idTypeKey).value,
                              orElse: () => Option(
                                code: form.control(idTypeKey).value,
                                name: form.control(idTypeKey).value!,
                              ),
                            )
                            .name,
                      ),
                    )
                  : null,
              items: filteredIdTypeOptions
                  .map(
                    (e) => DropdownItem(
                      code: e.code,
                      name: loc.translate(e.name),
                    ),
                  )
                  .toList(),
              onSelect: (value) {
                form.control(formControlName).markAsTouched();

                // Restore priority when the user picks a type:
                //   1. The beneficiary's original ID for this type (edit
                //      flow) — so toggling type away and back doesn't
                //      wipe an ID the record already carries.
                //   2. An availableIDs / navigationParams entry for this
                //      type (e.g. a freshly-allocated pool ID).
                //   3. Blank the number field.
                if (value.code == defaultIdType) {
                  applyDefaultBeneficiarySelection();
                  revalidateIdNumber();
                  return;
                }

                String? restoredNumber;
                if (originalEditIdType == value.code &&
                    originalEditIdNumber != null) {
                  restoredNumber = originalEditIdNumber;
                } else {
                  final navigationParams =
                      context.read<Map<String, dynamic>?>();
                  final autoIdentifier = identifiers?[value.code] ??
                      navigationParams?[value.code];
                  if (autoIdentifier is String && autoIdentifier.isNotEmpty) {
                    restoredNumber = autoIdentifier;
                  }
                }

                if (restoredNumber != null) {
                  form.control(idTypeKey).value = value.code;
                  form.control(idKey).value = restoredNumber;
                  form.control(idAutoFilledKey).value = true;

                  form.control(formControlName).value =
                      '${value.code}, $restoredNumber';
                } else {
                  form.control(idTypeKey).value = value.code;
                  form.control(idKey).value = null;
                  form.control(idAutoFilledKey).value = false;
                  form.control(formControlName).value = null;
                }
                revalidateIdNumber();
              },
              onChange: (value) {
                if (value.isEmpty) {
                  applyDefaultBeneficiarySelection();
                  revalidateIdNumber();
                }
              },
            ),
          ),
        ),

        if (form.control(idTypeKey).value != null &&
            form.control(idTypeKey).value != 'DEFAULT')
          const SizedBox(height: spacer4),

        /// ID NUMBER FIELD
        if (form.control(idTypeKey).value != null &&
            form.control(idTypeKey).value != 'DEFAULT')
          ReactiveFormConsumer(
            builder: (context, formGroup, child) {
              // UNIQUE_BENEFICIARY_ID must come from the downloaded pool
              // (via availableIDs / navigationParams). If the user skipped
              // the download the ID field would previously fall through
              // to editable free-text — locking it here so an operator
              // can't type an arbitrary value against a pool-sourced type.
              final isPoolSourcedType =
                  form.control(idTypeKey).value == 'UNIQUE_BENEFICIARY_ID';
              // Read here, not in the outer build, so it follows typing.
              final isIdNumberMissing =
                  (form.control(idKey).value?.toString().trim().isEmpty ??
                      true);
              return ReactiveWrapperField(
                formControlName: formControlName,
                validationMessages: validationMessages,
                showErrors: (control) => control.invalid && control.touched,
                builder: (field) => LabeledField(
                  label: loc.translate('ID_NUMBER_LABEL_TEXT'),
                  capitalizedFirstLetter: false,
                  isRequired: true,
                  child: DigitTextFormInput(
                    initialValue: form.control(idKey).value,
                    readOnly: form.control(idAutoFilledKey).value == true ||
                        isPoolSourcedType,
                    onChange: (value) {
                      form.control(formControlName).markAsTouched();
                      form.control(idAutoFilledKey).value = false;
                      form.control(idKey).value = value;
                      updateCombinedIdentifier();
                    },
                    errorMessage: isPoolSourcedType && isIdNumberMissing
                        ? loc.translate('BENEFICIARY_ID_POOL_EMPTY_ERROR')
                        : (isIdNumberMissing ? field.errorText : null),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
