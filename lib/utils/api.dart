import 'package:dio/dio.dart';

class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: "http://localhost:8000/api",
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
    headers: {
      "Content-Type": "application/json",
    },
  ));

  ApiService() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print("➡️ Enviando requisição: ${options.method} ${options.path}");

          // Exemplo: adicionar token automaticamente
          final token = "seu_token_de_preferencia";
          options.headers["Authorization"] = "Bearer $token";

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print("⬅️ Resposta recebida: ${response.statusCode}");
          return handler.next(response);
        },
        onError: (error, handler) {
          print("❌ Erro: ${error.response?.statusCode}");

          // Exemplo: se token expirou → redireciona para login
          if (error.response?.statusCode == 401) {
            // lógica de refresh token ou redirect
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
