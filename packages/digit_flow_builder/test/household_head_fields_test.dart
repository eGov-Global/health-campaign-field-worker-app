import 'package:digit_data_model/data_model.dart';
import 'package:digit_data_model/data_model.init.dart';
import 'package:digit_flow_builder/utils/function_registry.dart';
import 'package:digit_flow_builder/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the templates the registration flow uses to copy the household
/// head's name, age, gender and mobile number into HouseholdModel and
/// TaskModel additionalFields.
void main() {
  setUpAll(() {
    initializeFunctionRegistry();
    // The app registers the data model mappers at startup; a bare test must
    // do it so IndividualModel.toMap() encodes name and gender.
    initializeMappers();
  });

  // Born on 1 January, 30 years before the current year: always 30 now.
  final birthYear = DateTime.now().year - 30;
  final dob = DateTime(birthYear, 1, 1);

  group('calculateAgeInYears', () {
    dynamic ageOf(dynamic value) =>
        resolveValue('{{fn:calculateAgeInYears(dob)}}', {'dob': value});

    test('reads every date of birth format the app stores', () {
      expect(ageOf('01/01/$birthYear'), 30);
      expect(ageOf('01-01-$birthYear'), 30);
      expect(ageOf('$birthYear-01-01'), 30);
      expect(ageOf(dob), 30);
      expect(ageOf(dob.millisecondsSinceEpoch), 30);
      expect(ageOf('${dob.millisecondsSinceEpoch}'), 30);
    });

    test('returns null when there is no usable date of birth', () {
      expect(ageOf(null), isNull);
      expect(ageOf(''), isNull);
      expect(ageOf('not a date'), isNull);
    });
  });

  test('registration data computes headAge from the submitted form', () {
    const template =
        '{{fn:calculateAgeInYears(formData.beneficiaryDetails.dobPicker)}}';
    final contextData = {
      'formData': {
        'beneficiaryDetails': {'dobPicker': '01/01/$birthYear'},
      },
      'navigation': <String, dynamic>{},
    };
    expect(resolveValue(template, contextData), 30);

    final withoutDob = {
      'formData': {'householdDetails': <String, dynamic>{}},
      'navigation': <String, dynamic>{},
    };
    expect(resolveValue(template, withoutDob), isNull);
  });

  test('householdOverview navigation reads the head individual', () {
    final head = IndividualModel(
      clientReferenceId: 'ind-1',
      name: NameModel(givenName: 'Awa'),
      gender: Gender.female,
      dateOfBirth: '01/01/$birthYear',
      mobileNumber: '077123456',
    );
    final evalContext = {
      'contextData': [
        {
          'headIndividual': [head],
        },
      ],
    };

    expect(
      resolveValue(
          '{{contextData.0.headIndividual.0.name.givenName}}', evalContext),
      'Awa',
    );
    expect(
      resolveValue(
          '{{fn:calculateAgeInYears(contextData.0.headIndividual.0.dateOfBirth)}}',
          evalContext),
      30,
    );
    expect(resolveValue('{{contextData.0.headIndividual.0.gender}}', evalContext),
        'FEMALE');
    expect(
      resolveValue(
          '{{contextData.0.headIndividual.0.mobileNumber}}', evalContext),
      '077123456',
    );

    // A household without a head individual yields null, which the
    // transformer skips instead of storing the template text.
    final noHead = {
      'contextData': [
        {'headIndividual': <IndividualModel>[]},
      ],
    };
    expect(
      resolveValue('{{contextData.0.headIndividual.0.name.givenName}}', noHead),
      isNull,
    );
  });

  test('DELIVERY transformer data reads the head from navigation', () {
    final contextData = {
      'formData': <String, dynamic>{},
      'navigation': {'headName': 'Awa', 'headAge': 30},
    };
    expect(resolveValue('{{navigation.headName}}', contextData), 'Awa');
    expect(resolveValue('{{navigation.headAge}}', contextData), 30);
    expect(resolveValue('{{navigation.headMobileNumber}}', contextData),
        isNull);
  });
}
