class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'PARENT', 'TEACHER', 'ADMIN'
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parsing robuste du rôle
    String parseRole(dynamic roleData) {
      if (roleData == null) return 'PARENT';
      
      // Si c'est une liste (cas rare mais possible)
      if (roleData is List) {
        if (roleData.isEmpty) return 'PARENT';
        return roleData.first.toString().toUpperCase();
      }
      
      // Si c'est un String
      if (roleData is String) {
        return roleData.toUpperCase();
      }
      
      // Sinon, convertir en String et normaliser
      final roleStr = roleData.toString().toUpperCase();
      
      // Valider que c'est un rôle valide
      if (roleStr == 'ADMIN' || roleStr == 'TEACHER' || roleStr == 'PARENT') {
        return roleStr;
      }
      
      // Par défaut, retourner PARENT
      return 'PARENT';
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: parseRole(json['role']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'isActive': isActive,
    };
  }

  bool get isAdmin => role == 'ADMIN';
  bool get isTeacher => role == 'TEACHER';
  bool get isParent => role == 'PARENT';

  String get fullName => '$firstName $lastName';
  
  /// Retourne la liste des rôles (pour compatibilité si besoin)
  List<String> get roles => [role];
  
  /// Vérifie si l'utilisateur a un rôle spécifique
  bool hasRole(String roleToCheck) {
    return role.toUpperCase() == roleToCheck.toUpperCase();
  }
}
