/// Modèle pour un enfant dans la liste admin (avec infos parent)
class AdminKidModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? parentId;
  final String? parentEmail;
  final String? parentFirstName;
  final String? parentLastName;
  final String? grade;
  final String? school;
  final bool isActive;

  AdminKidModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.parentId,
    this.parentEmail,
    this.parentFirstName,
    this.parentLastName,
    this.grade,
    this.school,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get parentName {
    if (parentFirstName != null && parentLastName != null) {
      return '$parentFirstName $parentLastName'.trim();
    }
    return parentEmail ?? '—';
  }

  factory AdminKidModel.fromJson(Map<String, dynamic> json) {
    return AdminKidModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      parentId: json['parentId']?.toString(),
      parentEmail: json['parentEmail'] as String?,
      parentFirstName: json['parentFirstName'] as String?,
      parentLastName: json['parentLastName'] as String?,
      grade: json['grade'] as String?,
      school: json['school'] as String?,
      isActive: json['isActive'] ?? true,
    );
  }
}
