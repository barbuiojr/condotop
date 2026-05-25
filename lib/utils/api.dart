import 'package:dio/dio.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/login.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String _defaultBaseUrl = 'http://5.161.55.209:8000/api';
  static const String _baseUrlFromEnv =
      String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);

  static String get _resolvedBaseUrl {
    if (_baseUrlFromEnv.endsWith('/')) {
      return _baseUrlFromEnv.substring(0, _baseUrlFromEnv.length - 1);
    }
    return _baseUrlFromEnv;
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {
        "Content-Type": "application/json",
      },
    ),
  );

  // Busca a lista de condomínios do backend
  Future<List<Map<String, dynamic>>> getCondominios() async {
    try {
      final response = await dio.get('/condominios/');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
        if (response.data is Map && response.data['data'] is List) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
      }
    } catch (_) {
      // ignorar e retornar lista vazia em caso de erro
    }
    return <Map<String, dynamic>>[];
  }

  static GlobalKey<NavigatorState>? navigatorKey;
  final SessionService _sessionService = SessionService();

  ApiService() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print("➡️ Enviando requisição: ${options.method} ${options.uri}");

          // Não adicionar token nas rotas de login e cadastro
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/moradores/cadastro')) {
            final token = _sessionService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers["Authorization"] = "Bearer $token";
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print("⬅️ Resposta recebida: ${response.statusCode}");
          return handler.next(response);
        },
        onError: (error, handler) async {
          print(
            "❌ Erro: status=${error.response?.statusCode} tipo=${error.type} msg=${error.message}",
          );

          // Se token expirou → limpar sessão e redirecionar para login
          // Mas não redirecionar se já estiver na rota de login (evita loop e recarregamento)
          if (error.response?.statusCode == 401) {
            final isLoginRoute =
                error.requestOptions.path.contains('/auth/login');

            if (!isLoginRoute) {
              _sessionService.clearSession();

              // Redirecionar para login se tiver navigator key e não estiver na rota de login
              if (navigatorKey?.currentContext != null) {
                navigatorKey!.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Login()),
                  (route) => false,
                );
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Métodos de requisição
  Future<Response> get(String url, {Map<String, dynamic>? query}) async {
    return await dio.get(url, queryParameters: query);
  }

  Future<Response> post(String url, dynamic data, {Options? options}) async {
    return await dio.post(url, data: data, options: options);
  }

  Future<Response> put(String url, dynamic data) async {
    return await dio.put(url, data: data);
  }

  Future<Response> delete(String url) async {
    return await dio.delete(url);
  }
}
