import 'package:dio/dio.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/login.dart';
import 'package:flutter/material.dart';

class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: "http://192.168.0.150:8000/api",
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: const {
      "Content-Type": "application/json",
    },
  ));

  static GlobalKey<NavigatorState>? navigatorKey;
  final SessionService _sessionService = SessionService();

  ApiService() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print("➡️ Enviando requisição: ${options.method} ${options.path}");

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
          print("❌ Erro: ${error.response?.statusCode}");

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

  Future<Response> post(String url, dynamic data) async {
    return await dio.post(url, data: data);
  }

  Future<Response> put(String url, dynamic data) async {
    return await dio.put(url, data: data);
  }

  Future<Response> delete(String url) async {
    return await dio.delete(url);
  }
}
