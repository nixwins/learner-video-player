import 'dart:math' as math;

const defaultPanelWidth = 420.0;
const minPanelWidth = 320.0;
const _maxPanelFraction = 0.6;

/// Keeps the side panel usable: not narrower than [minPanelWidth] and never
/// more than 60% of the [available] window width.
double clampPanelWidth(double width, double available) {
  final max = math.max(minPanelWidth, available * _maxPanelFraction);
  return width.clamp(minPanelWidth, max).toDouble();
}
