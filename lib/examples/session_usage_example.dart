// EXEMPLO DE COMO USAR O SessionService
// Este arquivo é apenas para referência, você pode deletá-lo depois

import 'package:condotop/utils/session_service.dart';

// ============================================
// EXEMPLO 1: Acessar informações básicas
// ============================================
void exemploBasico() {
  final session = SessionService();
  
  // Verificar se está autenticado
  if (session.isAuthenticated()) {
    // Obter token
    final token = session.getToken();
    print('Token: $token');
    
    // Obter dados completos do usuário
    final userData = session.getUserData();
    print('Dados do usuário: $userData');
    
    // Obter informações específicas
    final userId = session.getUserId();
    final email = session.getUserEmail();
    final name = session.getUserName();
    
    print('ID: $userId');
    print('Email: $email');
    print('Nome: $name');
  }
}

// ============================================
// EXEMPLO 2: Usar em um Widget (StatefulWidget)
// ============================================
/*
import 'package:flutter/material.dart';
import 'package:condotop/utils/session_service.dart';

class MeuWidget extends StatefulWidget {
  @override
  _MeuWidgetState createState() => _MeuWidgetState();
}

class _MeuWidgetState extends State<MeuWidget> {
  final SessionService _session = SessionService();
  
  @override
  Widget build(BuildContext context) {
    // Verificar autenticação
    if (!_session.isAuthenticated()) {
      return Text('Usuário não autenticado');
    }
    
    // Obter dados
    final userName = _session.getUserName() ?? 'Usuário';
    final userEmail = _session.getUserEmail() ?? '';
    
    return Column(
      children: [
        Text('Bem-vindo, $userName!'),
        Text('Email: $userEmail'),
        // Acessar dados completos
        Text('ID: ${_session.getUserId()}'),
      ],
    );
  }
}
*/

// ============================================
// EXEMPLO 3: Usar em um Widget (StatelessWidget)
// ============================================
/*
import 'package:flutter/material.dart';
import 'package:condotop/utils/session_service.dart';

class PerfilUsuario extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = SessionService();
    
    if (!session.isAuthenticated()) {
      return Center(child: Text('Faça login para ver seu perfil'));
    }
    
    final userData = session.getUserData();
    
    return Scaffold(
      appBar: AppBar(title: Text('Perfil')),
      body: Column(
        children: [
          Text('Nome: ${session.getUserName()}'),
          Text('Email: ${session.getUserEmail()}'),
          Text('ID: ${session.getUserId()}'),
          // Acessar qualquer campo personalizado
          if (userData != null)
            Text('Telefone: ${userData['telefone'] ?? 'Não informado'}'),
        ],
      ),
    );
  }
}
*/

// ============================================
// EXEMPLO 4: Fazer logout
// ============================================
void exemploLogout() {
  final session = SessionService();
  
  // Limpar toda a sessão
  session.clearSession();
  
  // Verificar se foi limpo
  print('Autenticado: ${session.isAuthenticated()}'); // false
  print('Token: ${session.getToken()}'); // null
}

// ============================================
// EXEMPLO 5: Acessar campos personalizados
// ============================================
void exemploCamposPersonalizados() {
  final session = SessionService();
  final userData = session.getUserData();
  
  if (userData != null) {
    // Acessar qualquer campo que foi salvo
    final telefone = userData['telefone'];
    final endereco = userData['endereco'];
    final perfil = userData['perfil'];
    
    print('Telefone: $telefone');
    print('Endereço: $endereco');
    print('Perfil: $perfil');
  }
}

