import 'package:dio/dio.dart';

/// Normaliza erros da API DRF para uma mensagem exibível.
///
/// O backend responde com `{"erro": "mensagem"}` nas views customizadas ou
/// com um dict de erros de campo (`{"campo": ["msg", ...]}`) na validação
/// automática do DRF.
class ApiError implements Exception {
  ApiError(this.message, {this.statusCode, this.fields});

  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fields;

  factory ApiError.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final erro = data['erro'] ?? data['detail'] ?? data['non_field_errors'];
      if (erro is String) return ApiError(erro, statusCode: status);
      if (erro is List && erro.isNotEmpty) {
        return ApiError(erro.first.toString(), statusCode: status);
      }

      final fields = <String, List<String>>{};
      data.forEach((key, value) {
        if (value is List) {
          fields[key.toString()] = value.map((v) => v.toString()).toList();
        } else if (value is String) {
          fields[key.toString()] = [value];
        }
      });
      if (fields.isNotEmpty) {
        final first = fields.values.first.first;
        return ApiError(first, statusCode: status, fields: fields);
      }
    }

    if (data is String && data.isNotEmpty && data.length < 300) {
      return ApiError(data, statusCode: status);
    }

    return ApiError(_mensagemPorStatus(status, e.type), statusCode: status);
  }

  static String _mensagemPorStatus(int? status, DioExceptionType type) {
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout) {
      return 'Tempo de conexão esgotado. Verifique a rede.';
    }
    if (type == DioExceptionType.connectionError) {
      return 'Não foi possível conectar ao servidor.';
    }
    switch (status) {
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para esta ação.';
      case 404:
        return 'Recurso não encontrado.';
      case 500:
        return 'Erro interno do servidor.';
      default:
        return 'Ocorreu um erro inesperado.';
    }
  }

  @override
  String toString() => message;
}

/// Executa [fn] convertendo qualquer `DioException` em [ApiError].
Future<T> comApiError<T>(Future<T> Function() fn) async {
  try {
    return await fn();
  } on DioException catch (e) {
    throw ApiError.fromDio(e);
  }
}
