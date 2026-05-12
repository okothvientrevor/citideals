import 'package:flutter/material.dart';

/// Schema-driven category form fields. To add a category or field, edit this
/// file — no other code changes required. Bump [schemaVersion] when renaming
/// or removing fields so old `categoryData` blobs can be migrated.
const int schemaVersion = 1;

enum FieldType { text, multiline, number, dropdown, boolean, date }

class FieldDef {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final String? helpText;
  final List<String>? options; // for dropdown
  final IconData? icon;

  const FieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.helpText,
    this.options,
    this.icon,
  });
}

class CategoryDef {
  final String name;
  final IconData icon;
  final List<FieldDef> fields;

  const CategoryDef({
    required this.name,
    required this.icon,
    required this.fields,
  });
}

const _condition = ['Mint', 'Excellent', 'Good', 'Fair', 'Poor'];

const Map<String, CategoryDef> categorySchemas = {
  'Watches': CategoryDef(
    name: 'Watches',
    icon: Icons.watch_rounded,
    fields: [
      FieldDef(
        key: 'brand',
        label: 'Brand',
        type: FieldType.text,
        required: true,
        icon: Icons.watch_rounded,
      ),
      FieldDef(
        key: 'model',
        label: 'Model',
        type: FieldType.text,
        required: true,
        icon: Icons.label_rounded,
      ),
      FieldDef(
        key: 'reference',
        label: 'Reference number',
        type: FieldType.text,
        helpText: 'e.g. 116610LN',
        icon: Icons.tag_rounded,
      ),
      FieldDef(
        key: 'year',
        label: 'Year',
        type: FieldType.number,
        icon: Icons.calendar_today_rounded,
      ),
      FieldDef(
        key: 'condition',
        label: 'Condition',
        type: FieldType.dropdown,
        options: _condition,
        required: true,
        icon: Icons.shield_rounded,
      ),
      FieldDef(
        key: 'boxAndPapers',
        label: 'Box & papers included',
        type: FieldType.boolean,
        icon: Icons.inventory_2_rounded,
      ),
      FieldDef(
        key: 'serviceHistory',
        label: 'Service history',
        type: FieldType.multiline,
        helpText: 'Optional. Dates, work performed.',
        icon: Icons.history_rounded,
      ),
    ],
  ),
  'Cars': CategoryDef(
    name: 'Cars',
    icon: Icons.directions_car_rounded,
    fields: [
      FieldDef(
        key: 'make',
        label: 'Make',
        type: FieldType.text,
        required: true,
        icon: Icons.directions_car_rounded,
      ),
      FieldDef(
        key: 'model',
        label: 'Model',
        type: FieldType.text,
        required: true,
        icon: Icons.directions_car_rounded,
      ),
      FieldDef(
        key: 'year',
        label: 'Year',
        type: FieldType.number,
        required: true,
        icon: Icons.calendar_today_rounded,
      ),
      FieldDef(
        key: 'mileage',
        label: 'Mileage (km)',
        type: FieldType.number,
        icon: Icons.speed_rounded,
      ),
      FieldDef(
        key: 'fuelType',
        label: 'Fuel Type',
        type: FieldType.dropdown,
        options: ['Petrol', 'Diesel', 'Hybrid', 'Electric', 'LPG'],
        icon: Icons.local_gas_station_rounded,
      ),
      FieldDef(
        key: 'transmission',
        label: 'Transmission',
        type: FieldType.dropdown,
        options: ['Manual', 'Automatic', 'Semi-automatic', 'CVT'],
        icon: Icons.settings_rounded,
      ),
      FieldDef(
        key: 'condition',
        label: 'Condition',
        type: FieldType.dropdown,
        options: ['New', 'Used', 'Certified Pre-owned'],
        icon: Icons.shield_rounded,
      ),
      FieldDef(
        key: 'vin',
        label: 'VIN',
        type: FieldType.text,
        icon: Icons.tag_rounded,
      ),
      FieldDef(
        key: 'exteriorColor',
        label: 'Exterior color',
        type: FieldType.text,
        icon: Icons.palette_outlined,
      ),
      FieldDef(
        key: 'accidentHistory',
        label: 'Accident history',
        type: FieldType.boolean,
        icon: Icons.warning_amber_rounded,
      ),
    ],
  ),
  'Real Estate': CategoryDef(
    name: 'Real Estate',
    icon: Icons.home_work_rounded,
    fields: [
      FieldDef(
        key: 'propertyType',
        label: 'Property type',
        type: FieldType.dropdown,
        options: ['House', 'Apartment', 'Townhouse', 'Land', 'Commercial'],
        required: true,
        icon: Icons.home_work_rounded,
      ),
      FieldDef(
        key: 'address',
        label: 'Address',
        type: FieldType.text,
        required: true,
        icon: Icons.place_rounded,
      ),
      FieldDef(
        key: 'sqft',
        label: 'Size (sq ft)',
        type: FieldType.number,
        icon: Icons.square_foot_rounded,
      ),
      FieldDef(
        key: 'beds',
        label: 'Bedrooms',
        type: FieldType.number,
        icon: Icons.bed_rounded,
      ),
      FieldDef(
        key: 'baths',
        label: 'Bathrooms',
        type: FieldType.number,
        icon: Icons.bathtub_rounded,
      ),
      FieldDef(
        key: 'yearBuilt',
        label: 'Year built',
        type: FieldType.number,
        icon: Icons.calendar_today_rounded,
      ),
      FieldDef(
        key: 'hoa',
        label: 'HOA / strata fees',
        type: FieldType.boolean,
        icon: Icons.account_balance_rounded,
      ),
    ],
  ),
  'Art': CategoryDef(
    name: 'Art',
    icon: Icons.palette_rounded,
    fields: [
      FieldDef(
        key: 'artist',
        label: 'Artist',
        type: FieldType.text,
        required: true,
        icon: Icons.brush_rounded,
      ),
      FieldDef(
        key: 'medium',
        label: 'Medium',
        type: FieldType.dropdown,
        options: [
          'Oil',
          'Acrylic',
          'Watercolor',
          'Mixed media',
          'Sculpture',
          'Digital',
          'Print',
        ],
        required: true,
        icon: Icons.palette_rounded,
      ),
      FieldDef(
        key: 'year',
        label: 'Year',
        type: FieldType.number,
        icon: Icons.calendar_today_rounded,
      ),
      FieldDef(
        key: 'dimensions',
        label: 'Dimensions (W×H×D)',
        type: FieldType.text,
        icon: Icons.straighten_rounded,
      ),
      FieldDef(
        key: 'signed',
        label: 'Signed by artist',
        type: FieldType.boolean,
        icon: Icons.draw_rounded,
      ),
      FieldDef(
        key: 'provenance',
        label: 'Provenance',
        type: FieldType.multiline,
        helpText: 'Ownership history, gallery records.',
        icon: Icons.history_edu_rounded,
      ),
    ],
  ),
  'Jewelry': CategoryDef(
    name: 'Jewelry',
    icon: Icons.diamond_rounded,
    fields: [
      FieldDef(
        key: 'material',
        label: 'Material',
        type: FieldType.dropdown,
        options: [
          'Gold (24k)',
          'Gold (18k)',
          'Gold (14k)',
          'Platinum',
          'Silver',
          'Other',
        ],
        required: true,
        icon: Icons.diamond_rounded,
      ),
      FieldDef(
        key: 'gemstone',
        label: 'Primary gemstone',
        type: FieldType.text,
        icon: Icons.star_rounded,
      ),
      FieldDef(
        key: 'carats',
        label: 'Carats',
        type: FieldType.number,
        icon: Icons.scale_rounded,
      ),
      FieldDef(
        key: 'certification',
        label: 'Certification body',
        type: FieldType.text,
        helpText: 'e.g. GIA, IGI',
        icon: Icons.verified_rounded,
      ),
      FieldDef(
        key: 'hallmark',
        label: 'Hallmark',
        type: FieldType.text,
        icon: Icons.tag_rounded,
      ),
    ],
  ),
  'Fashion': CategoryDef(
    name: 'Fashion',
    icon: Icons.checkroom_rounded,
    fields: [
      FieldDef(
        key: 'brand',
        label: 'Brand',
        type: FieldType.text,
        required: true,
        icon: Icons.label_rounded,
      ),
      FieldDef(
        key: 'designer',
        label: 'Designer',
        type: FieldType.text,
        icon: Icons.person_rounded,
      ),
      FieldDef(
        key: 'size',
        label: 'Size',
        type: FieldType.text,
        icon: Icons.straighten_rounded,
      ),
      FieldDef(
        key: 'condition',
        label: 'Condition',
        type: FieldType.dropdown,
        options: _condition,
        required: true,
        icon: Icons.shield_rounded,
      ),
      FieldDef(
        key: 'eraYear',
        label: 'Era / year',
        type: FieldType.text,
        icon: Icons.calendar_today_rounded,
      ),
    ],
  ),
  'Photography': CategoryDef(
    name: 'Photography',
    icon: Icons.camera_alt_rounded,
    fields: [
      FieldDef(
        key: 'artist',
        label: 'Photographer',
        type: FieldType.text,
        required: true,
        icon: Icons.camera_alt_rounded,
      ),
      FieldDef(
        key: 'edition',
        label: 'Edition (e.g. 3/25)',
        type: FieldType.text,
        icon: Icons.copy_rounded,
      ),
      FieldDef(
        key: 'year',
        label: 'Year',
        type: FieldType.number,
        icon: Icons.calendar_today_rounded,
      ),
      FieldDef(
        key: 'framed',
        label: 'Framed',
        type: FieldType.boolean,
        icon: Icons.crop_rounded,
      ),
      FieldDef(
        key: 'printMethod',
        label: 'Print method',
        type: FieldType.dropdown,
        options: [
          'Gelatin silver',
          'Chromogenic',
          'Inkjet',
          'Platinum',
          'Other',
        ],
        icon: Icons.print_rounded,
      ),
    ],
  ),
};

List<String> get categoryNames => categorySchemas.keys.toList();
