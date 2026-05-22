import 'package:flutter/material.dart';

import '../../theme/workout_runner_theme.dart';
import '../internals/hero_stepper.dart';

/// Compact label-plus-trailing-input row used by every bundled editor
/// (`ExerciseEditorSheet`, `MuscleEditorSheet`, `CategoryEditorSheet`,
/// `PlanEditorScreen`, …).
///
/// The label renders in the muted caption style on the left, the [child] is
/// the trailing input aligned to the right. Use the named constructors for
/// the common cases — they all reduce to the same `Padding(Row(label, child))`
/// layout.
///
/// Example:
///
/// ```dart
/// MetaFieldRow.text(
///   label: 'Name',
///   value: state.name,
///   hint: 'Goblet Squat',
///   onChanged: (v) => setState(() => state.name = v),
/// );
/// ```
class MetaFieldRow extends StatelessWidget {
  /// Left-hand label rendered in the muted caption style.
  final String label;

  /// Trailing input. Free-form so editors can supply any widget — text input,
  /// [HeroStepper], [Switch], [DropdownButton], chips, etc.
  final Widget child;

  /// Whether the [child] should be wrapped in an [Expanded]. Defaults to
  /// `true`; pass `false` for naturally-sized trailing widgets like a
  /// [Switch] so they sit flush to the right edge.
  final bool expandChild;

  /// Override for outer padding. Defaults to a comfortable
  /// `EdgeInsets.symmetric(vertical: t.space2)` so multiple rows stack
  /// without manual gaps.
  final EdgeInsetsGeometry? padding;

  const MetaFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.expandChild = true,
    this.padding,
  });

  /// Free-text input wrapped in a themed [TextField]. Single-line by default
  /// (uses [TextInputAction.next] so editors can chain focus); pass
  /// `maxLines > 1` for notes / description fields.
  factory MetaFieldRow.text({
    Key? key,
    required String label,
    required String value,
    String? hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return MetaFieldRow(
      key: key,
      label: label,
      child: _ThemedTextField(
        value: value,
        hint: hint,
        onChanged: onChanged,
        maxLines: maxLines,
      ),
    );
  }

  /// Boolean toggle wrapped in an accent-tinted [Switch].
  factory MetaFieldRow.toggle({
    Key? key,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MetaFieldRow(
      key: key,
      label: label,
      expandChild: false,
      child: _ThemedSwitch(value: value, onChanged: onChanged),
    );
  }

  /// Numeric input backed by a [HeroStepper]. Same param semantics as the
  /// underlying stepper.
  factory MetaFieldRow.stepper({
    Key? key,
    required String label,
    required num value,
    num min = 0,
    num max = 1000,
    num smallStep = 1,
    bool integer = true,
    String? unit,
    required ValueChanged<num> onChanged,
  }) {
    return MetaFieldRow(
      key: key,
      label: label,
      child: HeroStepper(
        label: label,
        value: value,
        min: min,
        max: max,
        smallStep: smallStep,
        integer: integer,
        unit: unit,
        onChanged: onChanged,
      ),
    );
  }

  /// Themed [DropdownButton] for picking from a fixed list.
  ///
  /// Dart constructors cannot be generic, so this is exposed as a static
  /// builder. Call sites read `MetaFieldRow.dropdown<MyType>(...)`.
  static MetaFieldRow dropdown<T>({
    Key? key,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return MetaFieldRow(
      key: key,
      label: label,
      expandChild: false,
      child: _ThemedDropdown<T>(
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final trailing = expandChild ? Expanded(child: child) : child;
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(vertical: t.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: t.caption.copyWith(color: t.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: t.space3),
          trailing,
        ],
      ),
    );
  }
}

/// Themed text input used by `MetaFieldRow.text`.
class _ThemedTextField extends StatefulWidget {
  final String value;
  final String? hint;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _ThemedTextField({
    required this.value,
    required this.hint,
    required this.onChanged,
    required this.maxLines,
  });

  @override
  State<_ThemedTextField> createState() => _ThemedTextFieldState();
}

class _ThemedTextFieldState extends State<_ThemedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _ThemedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the controller in sync if the parent forces a new value (e.g.
    // after a reset). Avoid clobbering during normal typing.
    if (widget.value != _controller.text) {
      final newValue = widget.value;
      _controller.value = _controller.value.copyWith(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final isMultiline = widget.maxLines > 1;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: t.radiusMedium,
        border: Border.all(color: t.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space2),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        textInputAction:
            isMultiline ? TextInputAction.newline : TextInputAction.next,
        cursorColor: t.accent,
        style: t.body,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: t.bodyMuted.copyWith(color: t.textDim),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }
}

/// Themed [Switch] used by `MetaFieldRow.toggle`.
class _ThemedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ThemedSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: t.accent,
      activeTrackColor: t.accentMuted,
      inactiveThumbColor: t.textMuted,
      inactiveTrackColor: t.surfaceElevated,
    );
  }
}

/// Themed [DropdownButton] used by `MetaFieldRow.dropdown`.
class _ThemedDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ThemedDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceElevated,
        borderRadius: t.radiusMedium,
        border: Border.all(color: t.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: t.space3),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          dropdownColor: t.surfaceElevated,
          iconEnabledColor: t.textMuted,
          style: t.body,
        ),
      ),
    );
  }
}
