import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'category_schemas.dart';

typedef DynamicFormValues = Map<String, dynamic>;

class DynamicForm extends StatefulWidget {
  final List<FieldDef> fields;
  final DynamicFormValues initial;
  final ValueChanged<DynamicFormValues> onChanged;

  const DynamicForm({
    super.key,
    required this.fields,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<DynamicForm> createState() => DynamicFormState();
}

class DynamicFormState extends State<DynamicForm> {
  late final DynamicFormValues _values;
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initial);
    for (final f in widget.fields) {
      if (f.type == FieldType.text ||
          f.type == FieldType.multiline ||
          f.type == FieldType.number) {
        _controllers[f.key] = TextEditingController(
          text: _values[f.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  DynamicFormValues get values => Map.unmodifiable(_values);

  void _set(String key, dynamic value) {
    setState(() => _values[key] = value);
    widget.onChanged(Map.unmodifiable(_values));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in widget.fields) ...[
            _buildField(field),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildField(FieldDef field) {
    return switch (field.type) {
      FieldType.text => _textField(field),
      FieldType.multiline => _textField(field, multiline: true),
      FieldType.number => _textField(field, number: true),
      FieldType.dropdown => _dropdown(field),
      FieldType.boolean => _bool(field),
      FieldType.date => _date(field),
    };
  }

  Widget _label(FieldDef field) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Row(
        children: [
          Text(
            field.label,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
          ),
          if (field.required)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '*',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    FieldDef field, {
    bool multiline = false,
    bool number = false,
  }) {
    final ctrl = _controllers[field.key]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(field),
        TextFormField(
          controller: ctrl,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 6 : 1,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : multiline
                  ? TextInputType.multiline
                  : TextInputType.text,
          decoration: InputDecoration(
            hintText: field.helpText,
            prefixIcon:
                field.icon == null ? null : Icon(field.icon, size: 18),
          ),
          validator: (v) {
            if (field.required && (v == null || v.trim().isEmpty)) {
              return '${field.label} is required';
            }
            if (number && v != null && v.isNotEmpty) {
              if (num.tryParse(v) == null) return 'Enter a number';
            }
            return null;
          },
          onChanged: (v) {
            _set(field.key, number ? num.tryParse(v) : v);
          },
        ),
      ],
    );
  }

  Widget _dropdown(FieldDef field) {
    final current = _values[field.key] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(field),
        DropdownButtonFormField<String>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select…',
            prefixIcon:
                field.icon == null ? null : Icon(field.icon, size: 18),
          ),
          validator: (v) =>
              field.required && (v == null || v.isEmpty) ? 'Required' : null,
          items: [
            for (final o in field.options ?? const <String>[])
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (v) => _set(field.key, v),
        ),
      ],
    );
  }

  Widget _bool(FieldDef field) {
    final value = _values[field.key] == true;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (field.icon != null) ...[
            Icon(field.icon, size: 18, color: theme.iconTheme.color),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                if (field.helpText != null)
                  Text(
                    field.helpText!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppTheme.primary,
            onChanged: (v) => _set(field.key, v),
          ),
        ],
      ),
    );
  }

  Widget _date(FieldDef field) {
    final value = _values[field.key] as DateTime?;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(field),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) _set(field.key, picked);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_rounded, size: 18),
                const SizedBox(width: 10),
                Text(
                  value == null
                      ? 'Pick a date'
                      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
