import 'package:flutter_test/flutter_test.dart';

import 'package:citideals/features/submission/category_schemas.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Schema registry
  // ─────────────────────────────────────────────────────────────────────────
  group('categorySchemas registry', () {
    test('contains all expected categories', () {
      expect(
        categorySchemas.keys,
        containsAll([
          'Watches',
          'Cars',
          'Real Estate',
          'Art',
          'Jewelry',
          'Fashion',
          'Photography',
        ]),
      );
    });

    test('every category has a non-empty name and at least one field', () {
      for (final entry in categorySchemas.entries) {
        final cat = entry.value;
        expect(
          cat.name.isNotEmpty,
          isTrue,
          reason: 'Category "${entry.key}" has empty name',
        );
        expect(
          cat.fields.isNotEmpty,
          isTrue,
          reason: 'Category "${entry.key}" has no fields',
        );
      }
    });

    test('every field has a non-empty key and label', () {
      for (final cat in categorySchemas.values) {
        for (final field in cat.fields) {
          expect(
            field.key.isNotEmpty,
            isTrue,
            reason: 'Field in ${cat.name} has empty key',
          );
          expect(
            field.label.isNotEmpty,
            isTrue,
            reason: 'Field "${field.key}" in ${cat.name} has empty label',
          );
        }
      }
    });

    test('dropdown fields have at least one option', () {
      for (final cat in categorySchemas.values) {
        for (final field in cat.fields.where(
          (f) => f.type == FieldType.dropdown,
        )) {
          expect(
            field.options?.isNotEmpty ?? false,
            isTrue,
            reason:
                'Dropdown field "${field.key}" in ${cat.name} has no options',
          );
        }
      }
    });

    test('required fields are properly flagged', () {
      // Watches: brand, model, condition should be required
      final watches = categorySchemas['Watches']!;
      final requiredKeys = watches.fields
          .where((f) => f.required)
          .map((f) => f.key)
          .toList();
      expect(requiredKeys, containsAll(['brand', 'model', 'condition']));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // FieldType
  // ─────────────────────────────────────────────────────────────────────────
  group('FieldType enum', () {
    test('all expected types exist', () {
      expect(
        FieldType.values,
        containsAll([
          FieldType.text,
          FieldType.multiline,
          FieldType.number,
          FieldType.dropdown,
          FieldType.boolean,
          FieldType.date,
        ]),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Per-category field spot checks
  // ─────────────────────────────────────────────────────────────────────────
  group('Watches schema', () {
    final watches = categorySchemas['Watches']!;

    test('has brand as required text field', () {
      final brand = watches.fields.firstWhere((f) => f.key == 'brand');
      expect(brand.type, FieldType.text);
      expect(brand.required, isTrue);
    });

    test('has condition as required dropdown', () {
      final condition = watches.fields.firstWhere((f) => f.key == 'condition');
      expect(condition.type, FieldType.dropdown);
      expect(condition.required, isTrue);
      expect(
        condition.options,
        containsAll(['Mint', 'Excellent', 'Good', 'Fair', 'Poor']),
      );
    });

    test('has boxAndPapers as boolean field', () {
      final boxPapers = watches.fields.firstWhere(
        (f) => f.key == 'boxAndPapers',
      );
      expect(boxPapers.type, FieldType.boolean);
    });
  });

  group('Cars schema', () {
    final cars = categorySchemas['Cars']!;

    test('has make as required text field', () {
      final make = cars.fields.firstWhere((f) => f.key == 'make');
      expect(make.type, FieldType.text);
      expect(make.required, isTrue);
    });

    test('has mileage as number field', () {
      final mileage = cars.fields.firstWhere((f) => f.key == 'mileage');
      expect(mileage.type, FieldType.number);
    });
  });

  group('Real Estate schema', () {
    final realEstate = categorySchemas['Real Estate']!;

    test('has location as required field', () {
      final loc = realEstate.fields.firstWhere((f) => f.key == 'location');
      expect(loc.required, isTrue);
    });
  });
}
