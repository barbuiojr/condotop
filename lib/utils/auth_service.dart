import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        {
          'usuario': username,
          'senha': password,
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
          if (key != 'token' && key != 'access_token' && key != 'user' && key != 'usuario') {
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
      
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Usuário ou senha inválidos';
      } else if (e.toString().contains('Network')) {
        errorMessage = 'Erro de conexão. Verifique sua internet';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Tempo de conexão esgotado';
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
}

