/// A consulting room (mirrors backend `CabinetOut`). Plain model — no codegen.
class Cabinet {
  const Cabinet({
    required this.id,
    required this.branchId,
    required this.name,
    this.kind,
    this.isActive = true,
  });

  final String id;
  final String branchId;
  final String name;
  final String? kind;
  final bool isActive;

  factory Cabinet.fromJson(Map<String, dynamic> j) => Cabinet(
        id: j['id'] as String,
        branchId: j['branch_id'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String?,
        isActive: (j['is_active'] as bool?) ?? true,
      );
}
