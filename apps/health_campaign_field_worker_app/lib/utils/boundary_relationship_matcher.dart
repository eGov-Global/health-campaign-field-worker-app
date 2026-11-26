// Pure matching logic for MDMS BOUNDARY_RELATIONSHIP entries.
//
// Import-free on purpose: unit tests must compile even when unrelated
// lib files are broken, and the Isar/freezed config types must not leak
// in here. Callers map their config rows into [BoundaryRelationshipEntry].

/// Plain-value view of one BOUNDARY_RELATIONSHIP MDMS entry.
class BoundaryRelationshipEntry {
  final String boundaryType;

  /// Hierarchy this entry belongs to. Entries with a null/empty value are
  /// legacy (pre-multi-hierarchy) data that match any hierarchy.
  final String? hierarchyType;

  final String parentBoundaryType;
  final List<String> childBoundaryTypes;

  const BoundaryRelationshipEntry({
    required this.boundaryType,
    this.hierarchyType,
    this.parentBoundaryType = '',
    this.childBoundaryTypes = const [],
  });
}

/// Resolves the positional `[parent, current, child]` boundary-type list
/// for the project-facility search from boundaryRelationship entries.
///
/// Match priority:
/// 1. entry scoped to [hierarchyType] (exact, case-sensitive) with the
///    assigned boundary type;
/// 2. legacy entry (null/empty hierarchyType) with the assigned boundary
///    type.
///
/// Returns null when nothing matches — the caller falls back to the
/// boundary-tree derivation.
List<String>? resolveBoundaryTypesFromRelationship({
  required List<BoundaryRelationshipEntry> entries,
  required String? hierarchyType,
  required String assignedBoundaryType,
}) {
  BoundaryRelationshipEntry? match;

  if (hierarchyType != null && hierarchyType.isNotEmpty) {
    for (final entry in entries) {
      if (entry.hierarchyType == hierarchyType &&
          entry.boundaryType == assignedBoundaryType) {
        match = entry;
        break;
      }
    }
  }

  if (match == null) {
    for (final entry in entries) {
      final entryHierarchy = entry.hierarchyType;
      if ((entryHierarchy == null || entryHierarchy.isEmpty) &&
          entry.boundaryType == assignedBoundaryType) {
        match = entry;
        break;
      }
    }
  }

  if (match == null) return null;

  final firstChild = match.childBoundaryTypes.isNotEmpty
      ? match.childBoundaryTypes.first
      : '';

  return [
    if (match.parentBoundaryType.isNotEmpty) match.parentBoundaryType,
    match.boundaryType,
    if (firstChild.isNotEmpty) firstChild,
  ];
}
