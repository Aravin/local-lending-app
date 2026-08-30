import 'package:flutter/material.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

/// Brand-aligned [ChoiceChip] with readable selected and unselected contrast.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = FlavorConfig.primaryColor;
    final labelColor = selected ? Colors.white : scheme.onSurface;
    return ChoiceChip(
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: labelColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: primary,
      backgroundColor: scheme.surfaceContainerLowest,
      disabledColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return scheme.surfaceContainerLowest;
      }),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: labelColor,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? primary : scheme.outline),
    );
  }
}
