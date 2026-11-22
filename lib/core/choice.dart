/// A selectable entry in a menu: [id] is stable, [label] is shown to the user.
///
/// Shared by audio tracks, subtitle tracks and languages so that the same
/// menu widget can render all of them.
class Choice {
  const Choice({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is Choice && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}
