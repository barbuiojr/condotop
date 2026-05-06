import 'dart:async';

import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/device_login_info.dart';
import 'package:condotop/utils/fcm_token_service.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();
  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedUsernameKey = 'remembered_username';
  static const String _rememberedPasswordKey = 'remembered_password';

  // Future<String> _resolveFcmTokenForSync() async {
  //   for (var attempt = 0; attempt < 5; attempt++) {
  //     final token = await FcmTokenService.fetchAndCacheToken(
  //       debugSource: 'sync-${attempt + 1}',
  //     );
  //     if (token.isNotEmpty) {
  //       return token;
  //     }
  //     await Future.delayed(Duration(seconds: attempt + 1));
  //   }

  //   return '';
  // }

  int? _extractMoradorIdFromResponse(Map<String, dynamic> data) {
    final directId = data['id_morador'] ?? data['idMorador'] ?? data['id'];
    if (directId is int) {
      return directId;
    }
    if (directId is String) {
      return int.tryParse(directId);
    }

    final user = data['user'] ?? data['usuario'];
    if (user is Map) {
      final userMap = Map<String, dynamic>.from(user);
      final nestedId =
          userMap['id_morador'] ?? userMap['idMorador'] ?? userMap['id'];
      if (nestedId is int) {
        return nestedId;
      }
      if (nestedId is String) {
        return int.tryParse(nestedId);
      }
    }

    return null;
  }

  void _syncFcmTokenInBackground({
    required Map<String, dynamic> loginData,
    String initialToken = '',
  }) {
    unawaited(() async {
      try {
        var token = initialToken;
        if (token.isEmpty) {
          // token = await _resolveFcmTokenForSync();
        }

        if (token.isEmpty) {
          print('⚠️ fcm_token indisponível para sincronizar após login.');
          return;
        }

        final moradorId = _sessionService.getIdMorador() ??
            _extractMoradorIdFromResponse(loginData);

        if (moradorId == null) {
          print(
              '⚠️ Não foi possível identificar id_morador para salvar fcm_token.');
          return;
        }

        await _apiService.put('/moradores/$moradorId', {'fcm_token': token});
        print('✅ fcm_token sincronizado no morador $moradorId.');
      } catch (e) {
        print('❌ Falha ao sincronizar fcm_token após login: $e');
      }
    }());
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final deviceLoginInfo = await getDeviceLoginInfo();
      print('📱 Informacoes do dispositivo no login: $deviceLoginInfo');

      // final fcmToken = await FcmTokenService.getTokenForLogin();
      // print('🔔 Login com fcm_token preenchido: ${fcmToken.isNotEmpty}');
      // print('🔔 fcm_token no login: $fcmToken');

      final response = await _apiService.post(
        '/auth/login',
        {
          'usuario': username,
          'senha': password,
          'fcm_token': "",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Debug: imprimir resposta completa
        print('📦 Resposta do login: $data');

        // Salvar token na sessão
        if (data['token'] != null) {
          _sessionService.saveToken(data['token']);
        } else if (data['access_token'] != null) {
          _sessionService.saveToken(data['access_token']);
        }

        // Salvar informações do usuário na sessão
        // Priorizar objeto 'user' ou 'usuario', mas também salvar dados do nível raiz
        Map<String, dynamic> userDataToSave = {};

        if (data['user'] != null && data['user'] is Map) {
          userDataToSave = Map<String, dynamic>.from(data['user']);
        } else if (data['usuario'] != null && data['usuario'] is Map) {
          userDataToSave = Map<String, dynamic>.from(data['usuario']);
        }

        // Adicionar campos do nível raiz que não estão no objeto user
        // Isso garante que id_morador e id_condominio sejam salvos mesmo se estiverem no nível raiz
        data.forEach((key, value) {
          if (key != 'token' &&
              key != 'access_token' &&
              key != 'user' &&
              key != 'usuario') {
            if (!userDataToSave.containsKey(key)) {
              userDataToSave[key] = value;
            }
          }
        });

        // Se não encontrou user/usuario, salvar tudo exceto token
        if (userDataToSave.isEmpty) {
          data.forEach((key, value) {
            if (key != 'token' && key != 'access_token') {
              userDataToSave[key] = value;
            }
          });
        }

        // Debug: imprimir dados que serão salvos
        print('💾 Dados a serem salvos na sessão: $userDataToSave');

        _sessionService.saveUserData(userDataToSave);
        // _syncFcmTokenInBackground(loginData: data, initialToken: fcmToken);

        return {
          'success': true,
          'message': 'Login realizado com sucesso',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao fazer login',
        };
      }
    } catch (e) {
      String errorMessage = 'Erro ao fazer login';

      // Debug: imprimir erro completo
      print('❌ Erro no login: $e');

      // Tentar extrair mensagem de erro da resposta da API
      try {
        if (e.toString().contains('DioException')) {
          final errorResponse = (e as dynamic).response;
          if (errorResponse != null) {
            print('📦 Status code: ${errorResponse.statusCode}');
            print('📦 Error data: ${errorResponse.data}');

            if (errorResponse.data != null) {
              final errorData = errorResponse.data;

              // Verificar se tem a mensagem de usuário não ativado
              if (errorData is Map) {
                if (errorData['detail'] != null) {
                  errorMessage = errorData['detail'].toString();
                  print('✅ Mensagem extraída (detail): $errorMessage');
                } else if (errorData['message'] != null) {
                  errorMessage = errorData['message'].toString();
                  print('✅ Mensagem extraída (message): $errorMessage');
                } else if (errorData['error'] != null) {
                  errorMessage = errorData['error'].toString();
                  print('✅ Mensagem extraída (error): $errorMessage');
                }
              }
            }
          }
        }
      } catch (ex) {
        print('⚠️ Erro ao extrair mensagem: $ex');
        // Se não conseguir extrair, usar mensagens padrão
      }

      // Mensagens padrão baseadas no código de status
      if (errorMessage == 'Erro ao fazer login') {
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Usuário ou senha inválidos';
        } else if (e.toString().contains('403') ||
            e.toString().contains('Forbidden')) {
          errorMessage = 'Acesso negado';
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Tempo de conexão esgotado';
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  Future<void> logout() async {
    _sessionService.clearSession();
  }

  Future<void> saveRememberedCredentials({
    required String username,
    required String password,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_rememberMeKey, remember);

    if (remember) {
      await prefs.setString(_rememberedUsernameKey, username);
      await prefs.setString(_rememberedPasswordKey, password);
      return;
    }

    await prefs.remove(_rememberedUsernameKey);
    await prefs.remove(_rememberedPasswordKey);
  }

  Future<Map<String, dynamic>> getRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final remember = prefs.getBool(_rememberMeKey) ?? false;
    final username = prefs.getString(_rememberedUsernameKey) ?? '';
    final password = prefs.getString(_rememberedPasswordKey) ?? '';

    return {
      'remember': remember,
      'username': username,
      'password': password,
    };
  }
}
