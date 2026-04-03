import '../services/api_service.dart';

/// Construit l’URL absolue d’un fichier servi par l’API ([path] commence par `/api/uploads/...`).
String absoluteUploadUrl(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final base = Uri.parse(ApiService.baseUrl);
  return '${base.origin}$path';
}
