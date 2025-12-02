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
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          errorMessage = 'Usuário ou senha inválidos';
        } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
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
}

