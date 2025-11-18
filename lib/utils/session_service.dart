class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  String? _token;
  Map<String, dynamic>? _userData;

  // Salvar token
  void saveToken(String token) {
    _token = token;
  }

  // Obter token
  String? getToken() {
    return _token;
  }

  // Salvar dados do usuário
  void saveUserData(Map<String, dynamic> userData) {
    _userData = userData;
  }

  // Obter dados do usuário
  Map<String, dynamic>? getUserData() {
    return _userData;
  }

  // Verificar se está autenticado
  bool isAuthenticated() {
    return _token != null && _token!.isNotEmpty;
  }

  // Limpar sessão (logout)
  void clearSession() {
    _token = null;
    _userData = null;
  }

  // Obter informações específicas do usuário
  String? getUserId() {
    return _userData?['id']?.toString() ?? _userData?['userId']?.toString();
  }

  String? getUserEmail() {
    return _userData?['email'];
  }

  String? getUserName() {
    return _userData?['name'] ?? _userData?['username'];
  }

  // Obter ID do morador
  int? getIdMorador() {
    if (_userData == null) {
      print('⚠️ SessionService: _userData é null');
      return null;
    }
    
    print('🔍 Buscando id_morador. Dados disponíveis: ${_userData!.keys.toList()}');
    
    // Tentar várias variações de nomes de campo
    final id = _userData?['id_morador'] ?? 
               _userData?['idMorador'] ?? 
               _userData?['morador_id'] ?? 
               _userData?['moradorId'] ??
               _userData?['id'] ??
               _userData?['userId'];
    
    print('🔍 Valor encontrado para id_morador: $id (tipo: ${id.runtimeType})');
    
    if (id is int) return id;
    if (id is String) {
      final parsed = int.tryParse(id);
      print('🔍 String convertida para int: $parsed');
      return parsed;
    }
    
    print('❌ Não foi possível obter id_morador');
    return null;
  }

  // Obter ID do condomínio
  int? getIdCondominio() {
    if (_userData == null) {
      print('⚠️ SessionService: _userData é null');
      return null;
    }
    
    print('🔍 Buscando id_condominio. Dados disponíveis: ${_userData!.keys.toList()}');
    
    // Tentar várias variações de nomes de campo
    final id = _userData?['id_condominio'] ?? 
               _userData?['idCondominio'] ?? 
               _userData?['condominio_id'] ?? 
               _userData?['condominioId'] ??
               _userData?['condominio'] ??
               _userData?['cond_id'];
    
    print('🔍 Valor encontrado para id_condominio: $id (tipo: ${id.runtimeType})');
    
    if (id is int) return id;
    if (id is String) {
      final parsed = int.tryParse(id);
      print('🔍 String convertida para int: $parsed');
      return parsed;
    }
    
    print('❌ Não foi possível obter id_condominio');
    return null;
  }
  
  // Método de debug para ver todos os dados salvos
  void printDebugInfo() {
    print('=== DEBUG SESSION SERVICE ===');
    print('Token: ${_token != null ? "***${_token!.substring(_token!.length - 4)}" : "null"}');
    print('UserData: $_userData');
    print('ID Morador: ${getIdMorador()}');
    print('ID Condomínio: ${getIdCondominio()}');
    print('============================');
  }
}

