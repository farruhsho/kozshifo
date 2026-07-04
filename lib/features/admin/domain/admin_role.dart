/// View of a backend `RoleOut` for the admin screen: id + name (used for
/// assignment via `role_names`), whether it is a protected system role, and the
/// full set of permission codes it grants (so the roles editor can pre-tick the
/// catalog without a second fetch). `permissionCount` stays derived for the
/// staff-dialog chips. Display & assignment only — no Freezed/codegen needed.
class AdminRole {
  const AdminRole({
    required this.name,
    required this.permissionCodes,
    this.id,
    this.isSystem = false,
    this.description,
  });

  final String? id;
  final String name;
  final bool isSystem;
  final List<String> permissionCodes;
  final String? description;

  int get permissionCount => permissionCodes.length;

  factory AdminRole.fromJson(Map<String, dynamic> json) => AdminRole(
        id: json['id'] as String?,
        name: json['name'] as String,
        isSystem: json['is_system'] as bool? ?? false,
        permissionCodes: [
          for (final p in json['permissions'] as List<dynamic>? ?? const [])
            (p as Map<String, dynamic>)['code'] as String,
        ],
        description: json['description'] as String?,
      );
}
