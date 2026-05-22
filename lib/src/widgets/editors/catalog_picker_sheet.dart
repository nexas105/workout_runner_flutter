import 'package:flutter/material.dart';

import '../../l10n/workout_runner_localizations.dart';
import '../../theme/workout_runner_theme.dart';
import '../internals/runner_card.dart';
import '../internals/runner_pill_button.dart';

/// Discriminator the host app passes to `show` so it can wire one shared
/// catalogue picker to multiple lookup sources (exercises, muscles,
/// categories). The sheet itself is generic, so this enum exists purely as
/// metadata for callers — it does NOT change the rendered UI.
enum CatalogPickerKind { exercise, muscle, category }

/// Reusable bottom-sheet picker for any catalog list (default + user-defined
/// exercises, muscles, categories, plans).
///
/// Single-select returns the picked item as a `List<T>` of length 1 once the
/// user taps an entry (immediate dismissal). Multi-select keeps the sheet
/// open while toggles accumulate and resolves on the "Done" button.
class CatalogPickerSheet<T> extends StatefulWidget {
  /// Full list to choose from. The sheet does not load lazily — pass an
  /// already-materialised list (typically `Catalog.exercises` or similar).
  final List<T> items;

  /// Renders the primary label for each item (e.g. exercise name).
  final String Function(T) labelOf;

  /// Optional secondary line (e.g. muscle group, description).
  final String Function(T)? subtitleOf;

  /// When `true`, the sheet stays open and accumulates a list of picks. When
  /// `false`, the first tap closes the sheet with that single item.
  final bool multiSelect;

  /// Items pre-selected when the sheet opens. Matched by `==` against
  /// [items]; pass models with stable `==`/`hashCode` (typically id-based).
  final List<T> initialSelection;

  /// Sheet title rendered in the header.
  final String title;

  const CatalogPickerSheet({
    super.key,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
    this.multiSelect = false,
    this.initialSelection = const [],
    required this.title,
  });

  /// Opens the picker in a modal bottom sheet and returns the user's
  /// selection — `null` on dismiss/cancel, `List<T>` on confirm.
  static Future<List<T>?> show<T>(
    BuildContext context, {
    required List<T> items,
    required String Function(T) labelOf,
    String Function(T)? subtitleOf,
    bool multiSelect = false,
    List<T> initialSelection = const [],
    String title = 'Pick',
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => CatalogPickerSheet<T>(
            items: items,
            labelOf: labelOf,
            subtitleOf: subtitleOf,
            multiSelect: multiSelect,
            initialSelection: initialSelection,
            title: title,
          ),
    );
  }

  @override
  State<CatalogPickerSheet<T>> createState() => _CatalogPickerSheetState<T>();
}

class _CatalogPickerSheetState<T> extends State<CatalogPickerSheet<T>> {
  late final TextEditingController _searchController = TextEditingController();
  late final Set<T> _selected = {...widget.initialSelection};
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((item) => widget.labelOf(item).toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _onTapItem(T item) {
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(item)) {
          _selected.remove(item);
        } else {
          _selected.add(item);
        }
      });
    } else {
      Navigator.of(context).pop(<T>[item]);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.toList(growable: false));
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final l = WorkoutRunnerLocalizationsScope.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final filtered = _filtered;

    return AnimatedPadding(
      duration: reduceMotion ? Duration.zero : t.motionFast,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      curve: Curves.easeOut,
      child: SizedBox(
        height: screenHeight * 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: t.border)),
          ),
          padding: EdgeInsets.fromLTRB(t.space4, t.space3, t.space4, t.space4),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: EdgeInsets.only(bottom: t.space3),
                decoration: BoxDecoration(
                  color: t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header: title + cancel
              Row(
                children: [
                  Expanded(child: Text(widget.title, style: t.titleLarge)),
                  TextButton(
                    onPressed: _cancel,
                    child: Text(
                      l.actionCancel,
                      style: t.title.copyWith(color: t.textMuted),
                    ),
                  ),
                ],
              ),
              SizedBox(height: t.space3),
              // Search
              _SearchBox(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
              SizedBox(height: t.space3),
              // List / empty state
              Expanded(
                child:
                    filtered.isEmpty
                        ? _EmptyState(query: _query)
                        : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder:
                              (_, _) => SizedBox(height: t.space2),
                          itemBuilder: (ctx, i) {
                            final item = filtered[i];
                            final selected = _selected.contains(item);
                            return _CatalogRow<T>(
                              item: item,
                              label: widget.labelOf(item),
                              subtitle: widget.subtitleOf?.call(item),
                              selected: selected,
                              onTap: () => _onTapItem(item),
                            );
                          },
                        ),
              ),
              SizedBox(height: t.space3),
              // Done
              RunnerPillButton(
                label: l.actionOk,
                style: RunnerButtonStyle.accent,
                expand: true,
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({required this.controller, required this.onChanged});

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
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: t.textMuted, size: 20),
          SizedBox(width: t.space2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: t.accent,
              style: t.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: t.bodyMuted.copyWith(color: t.textDim),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogRow<T> extends StatelessWidget {
  final T item;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _CatalogRow({
    required this.item,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    return RunnerCard(
      onTap: onTap,
      borderColor: selected ? t.accent : t.border,
      padding: EdgeInsets.symmetric(horizontal: t.space3, vertical: t.space3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: t.space1),
                  Text(
                    subtitle!,
                    style: t.bodyMuted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: t.space2),
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? t.accent : t.textDim,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final t = WorkoutRunnerTheme.of(context);
    final message =
        query.isEmpty ? 'Nothing here yet' : 'No results for "$query"';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: t.textDim, size: 40),
          SizedBox(height: t.space2),
          Text(message, style: t.bodyMuted),
        ],
      ),
    );
  }
}
