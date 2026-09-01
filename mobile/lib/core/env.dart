import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  /// Troca `localhost` pelo host real da API em URLs absolutas devolvidas
  /// pelo backend (ex.: links de exportação servidos pelo WhiteNoise).
  static String rewriteAbsoluteUrl(String url) {
    if (!url.contains('localhost')) return url;
    final host = Uri.tryParse(baseUrl)?.host;
    if (host == null || host.isEmpty) return url;
    return url.replaceFirst('localhost', host);
  }
}
