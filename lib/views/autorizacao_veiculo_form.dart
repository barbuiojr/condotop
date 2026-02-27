import 'dart:async';
import 'package:flutter/material.dart';
import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:dio/dio.dart';

class AutorizacaoVeiculoForm extends StatefulWidget {
  const AutorizacaoVeiculoForm({
    super.key,
    this.nomeServico = 'Uber',
    this.tipoServico = 'Uber',
    this.tituloTela = 'Solicitar Uber',
  });

  final String nomeServico;
  final String tipoServico;
  final String tituloTela;

  @override
  State<AutorizacaoVeiculoForm> createState() => _AutorizacaoVeiculoFormState();
}

class _AutorizacaoVeiculoFormState extends State<AutorizacaoVeiculoForm> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _veiculoController = TextEditingController();
  final _apiService = ApiService();
  final _sessionService = SessionService();
  bool _isLoading = false;
  bool _isLoadingSolicitacao = true;
  bool _isDeleting = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _solicitacaoExistente;
  Timer? _pollingTimer;

  String get _nomeServico => widget.nomeServico;
  String get _tipoServico => widget.tipoServico.toLowerCase();
  String get _tituloTela => widget.tituloTela;

  @override
  void initState() {
    super.initState();
    _verificarSolicitacaoExistente().then((_) {
      // Iniciar polling após verificar se houver solicitação existente
      _iniciarPolling();
    });
  }

  @override
  void dispose() {
    _placaController.dispose();
    _veiculoController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _iniciarPolling() {
    // Verificar a cada 5 segundos se a solicitação foi autorizada
    _pollingTimer?.cancel();
    if (_solicitacaoExistente != null && !_isAutorizado()) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_solicitacaoExistente != null && mounted && !_isAutorizado()) {
          _verificarSolicitacaoExistente(silencioso: true);
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _verificarSolicitacaoExistente({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _isLoadingSolicitacao = true;
        _errorMessage = null;
      });
    }

    try {
      final idMorador = _sessionService.getIdMorador();

      if (idMorador == null) {
        setState(() {
          _isLoadingSolicitacao = false;
        });
        return;
      }

      // Tentar diferentes endpoints possíveis
      Response? response;

      // Tentativa 1: Buscar todas as solicitações do morador com query
      try {
        response = await _apiService.get('/acessos', query: {
          'id_morador': idMorador,
        });
        print('✅ Sucesso ao buscar acessos com query');
      } catch (e) {
        print('⚠️ Erro ao buscar acessos com query: $e');
        // Tentativa 2: Buscar sem query parameters
        try {
          response = await _apiService.get('/acessos');
          print('✅ Sucesso ao buscar acessos sem query');
        } catch (e2) {
          print('⚠️ Erro ao buscar acessos sem query: $e2');
          // Tentativa 3: Tentar endpoint específico do morador
          try {
            response = await _apiService.get('/acessos/morador/$idMorador');
            print('✅ Sucesso ao buscar acessos do morador');
          } catch (e3) {
            print('⚠️ Erro ao buscar acessos do morador: $e3');
          }
        }
      }

      if (response != null &&
          response.statusCode == 200 &&
          response.data != null) {
        print('📦 Dados recebidos: ${response.data}');
        List<dynamic> solicitacoes = [];

        // Se a resposta for uma lista
        if (response.data is List) {
          solicitacoes = response.data as List;
          print('📋 Encontradas ${solicitacoes.length} solicitações na lista');
        }
        // Se a resposta for um objeto com uma lista dentro
        else if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          print('📋 Chaves no objeto: ${data.keys.toList()}');
          if (data.containsKey('data') && data['data'] is List) {
            solicitacoes = data['data'] as List;
            print('📋 Encontradas ${solicitacoes.length} solicitações em data');
          } else if (data.containsKey('acessos') && data['acessos'] is List) {
            solicitacoes = data['acessos'] as List;
            print(
                '📋 Encontradas ${solicitacoes.length} solicitações em acessos');
          }
        }

        // Filtrar solicitações ativas do serviço selecionado (não canceladas)
        Map<String, dynamic>? solicitacaoUber;

        for (var solicitacao in solicitacoes) {
          try {
            final sol = solicitacao as Map<String, dynamic>;
            final tipoServico =
                sol['tipo_servico']?.toString().toLowerCase() ?? '';
            final solIdMorador = sol['id_morador'] ?? sol['idMorador'];
            final cancelado = sol['cancelado'];

            print(
                '🔍 Verificando solicitação: tipo=$tipoServico, idMorador=$solIdMorador, cancelado=$cancelado');

            // Verificar se é do serviço correto, do morador correto e não está cancelado
            if (tipoServico == _tipoServico &&
                solIdMorador == idMorador &&
                (cancelado == null || cancelado == false || cancelado == 0)) {
              print('✅ Solicitação de $_nomeServico ativa encontrada!');
              solicitacaoUber = sol;
              break;
            }
          } catch (e) {
            print('⚠️ Erro ao processar solicitação: $e');
            // Continuar procurando
            continue;
          }
        }

        if (solicitacaoUber != null) {
          print('✅ Definindo solicitação existente: $solicitacaoUber');
          final entradaOk = solicitacaoUber['entrada_ok'];
          final foiAutorizado = entradaOk == 1 || entradaOk == true;

          // Verificar se estava autorizado antes (usando o estado atual)
          final estavaAutorizado = _solicitacaoExistente != null &&
              (_solicitacaoExistente!['entrada_ok'] == 1 ||
                  _solicitacaoExistente!['entrada_ok'] == true);

          setState(() {
            _solicitacaoExistente = solicitacaoUber;
            _isLoadingSolicitacao = false;
          });

          // Reiniciar polling se não estiver autorizado
          if (!foiAutorizado) {
            _iniciarPolling();
          } else {
            _pollingTimer?.cancel();
            // Se acabou de ser autorizado, mostrar mensagem
            if (!estavaAutorizado && foiAutorizado) {
              setState(() {
                _successMessage = 'Solicitação autorizada pela portaria!';
              });
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _successMessage = null;
                  });
                }
              });
            }
          }

          return;
        } else {
          print('ℹ️ Nenhuma solicitação de $_nomeServico ativa encontrada');
          _pollingTimer?.cancel();
        }
      }

      if (!silencioso) {
        setState(() {
          _solicitacaoExistente = null;
          _isLoadingSolicitacao = false;
        });
      } else {
        setState(() {
          _solicitacaoExistente = null;
        });
      }
    } catch (e) {
      print('⚠️ Erro ao verificar solicitação existente: $e');
      // Se der erro, assumir que não existe solicitação
      setState(() {
        _solicitacaoExistente = null;
        _isLoadingSolicitacao = false;
      });
    }
  }

  Future<void> _cancelarSolicitacao() async {
    if (_solicitacaoExistente == null) return;

    // Confirmar cancelamento
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitação'),
        content: Text(
            'Tem certeza que deseja cancelar esta solicitação de $_nomeServico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final id = _solicitacaoExistente!['id'] ??
          _solicitacaoExistente!['id_acesso'] ??
          _solicitacaoExistente!['_id'];

      if (id == null) {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Erro: ID da solicitação não encontrado.';
        });
        return;
      }

      // Cancelar solicitação usando PUT
      final response = await _apiService.put('/acessos/uber/$id/cancelar', {});

      if (response.statusCode == 200 || response.statusCode == 204) {
        _pollingTimer?.cancel();
        setState(() {
          _isDeleting = false;
          _solicitacaoExistente = null;
          _successMessage = 'Solicitação cancelada com sucesso!';
        });

        // Limpar mensagem após alguns segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _isDeleting = false;
          _errorMessage = 'Erro ao cancelar solicitação. Tente novamente.';
        });
      }
    } catch (e) {
      String errorMessage = 'Erro ao cancelar solicitação';

      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          if (e.response?.data != null && e.response!.data is Map) {
            final errorData = e.response!.data as Map;
            errorMessage = errorData['message']?.toString() ??
                errorData['error']?.toString() ??
                errorMessage;
          }
        } else if (e.response?.data != null && e.response!.data is Map) {
          final errorData = e.response!.data as Map;
          errorMessage = errorData['message']?.toString() ??
              errorData['error']?.toString() ??
              errorMessage;
        }
      }

      setState(() {
        _isDeleting = false;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _autorizarUber() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        // Debug: imprimir informações da sessão
        _sessionService.printDebugInfo();

        // Obter dados da sessão
        final idMorador = _sessionService.getIdMorador();
        final idCondominio = _sessionService.getIdCondominio();

        if (idMorador == null || idCondominio == null) {
          // Debug adicional
          final userData = _sessionService.getUserData();
          print('❌ Erro: idMorador=$idMorador, idCondominio=$idCondominio');
          print('📋 Dados completos da sessão: $userData');

          setState(() {
            _isLoading = false;
            _errorMessage =
                'Erro: Dados do usuário não encontrados. Faça login novamente.\n'
                'ID Morador: ${idMorador ?? "null"}\n'
                'ID Condomínio: ${idCondominio ?? "null"}';
          });
          return;
        }

        // Preparar body da requisição
        final body = {
          "placa": _placaController.text.trim().toUpperCase(),
          "veiculo": _veiculoController.text.trim(),
          "tipo_servico": widget.tipoServico,
          "id_morador": idMorador,
          "id_condominio": idCondominio,
        };

        // Debug: imprimir body
        print('📤 Body da requisição: $body');

        // Chamar API
        final response = await _apiService.post('/acessos/uber', body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Limpar campos após sucesso
          _placaController.clear();
          _veiculoController.clear();

          // Redirecionar imediatamente para o Dashboard
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          String errorMsg = 'Erro ao autorizar $_nomeServico. Tente novamente.';
          if (response.data != null && response.data is Map) {
            final errorData = response.data as Map;
            if (errorData.containsKey('message')) {
              errorMsg = errorData['message'].toString();
            } else if (errorData.containsKey('error')) {
              errorMsg = errorData['error'].toString();
            }
          }
          setState(() {
            _isLoading = false;
            _errorMessage = errorMsg;
          });
        }
      } catch (e) {
        String errorMessage = 'Erro ao autorizar $_nomeServico';

        // Tratar erros do Dio
        if (e is DioException) {
          print('❌ DioException: ${e.response?.statusCode}');
          print('❌ Response data: ${e.response?.data}');

          if (e.response?.statusCode == 400) {
            // Erro 400 - Bad Request
            if (e.response?.data != null && e.response!.data is Map) {
              final errorData = e.response!.data as Map;
              if (errorData.containsKey('message')) {
                errorMessage = errorData['message'].toString();
              } else if (errorData.containsKey('error')) {
                errorMessage = errorData['error'].toString();
              } else {
                errorMessage =
                    'Dados inválidos. Verifique os campos preenchidos.';
              }
            } else {
              errorMessage =
                  'Dados inválidos. Verifique os campos preenchidos.';
            }
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Sessão expirada. Faça login novamente.';
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Tempo de conexão esgotado';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage = 'Erro de conexão. Verifique sua internet';
          } else if (e.response?.data != null && e.response!.data is Map) {
            final errorData = e.response!.data as Map;
            if (errorData.containsKey('message')) {
              errorMessage = errorData['message'].toString();
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'].toString();
            }
          }
        } else if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized')) {
          errorMessage = 'Sessão expirada. Faça login novamente.';
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Tempo de conexão esgotado';
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _tituloTela,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingSolicitacao
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _solicitacaoExistente != null
              ? _buildSolicitacaoExistente()
              : _buildFormulario(),
    );
  }

  Widget _buildSolicitacaoExistente() {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);
    final solicitacao = _solicitacaoExistente!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: orangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_taxi,
                    color: orangeColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Solicitação Ativa",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              "Você já possui uma solicitação de $_nomeServico ativa",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 32),

            // Mensagem de erro
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Mensagem de sucesso
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Card com informações da solicitação
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusText(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            if (_isAutorizado())
                              Text(
                                _getDataAutorizacao(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    Icons.directions_car_rounded,
                    "Veículo",
                    solicitacao['veiculo']?.toString() ?? 'N/A',
                    blueColor,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.confirmation_number_rounded,
                    "Placa",
                    solicitacao['placa']?.toString() ?? 'N/A',
                    blueColor,
                  ),
                  if (solicitacao['created_at'] != null ||
                      solicitacao['data_criacao'] != null)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today_rounded,
                          "Data",
                          _formatarData(solicitacao['created_at'] ??
                              solicitacao['data_criacao']),
                          blueColor,
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botão para cancelar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _cancelarSolicitacao,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isDeleting ? Colors.grey.shade400 : Colors.red.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isDeleting ? 0 : 4,
                  shadowColor: Colors.red.withOpacity(0.4),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Cancelar Solicitação",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'N/A';
    try {
      if (data is String) {
        final date = DateTime.parse(data);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }

  bool _isAutorizado() {
    if (_solicitacaoExistente == null) return false;
    final entradaOk = _solicitacaoExistente!['entrada_ok'];
    return entradaOk == 1 || entradaOk == true;
  }

  Color _getStatusColor() {
    if (_isAutorizado()) {
      return Colors.green.shade700;
    }
    return Colors.orange.shade700;
  }

  IconData _getStatusIcon() {
    if (_isAutorizado()) {
      return Icons.check_circle;
    }
    return Icons.pending;
  }

  String _getStatusText() {
    if (_isAutorizado()) {
      return "Autorizado";
    }
    return "Aguardando Autorização";
  }

  String _getDataAutorizacao() {
    if (_solicitacaoExistente == null) return '';

    final dataAutorizacao = _solicitacaoExistente!['data_autorizacao'];
    final horaAutorizacao = _solicitacaoExistente!['hora_autorizacao'];

    if (dataAutorizacao != null && horaAutorizacao != null) {
      try {
        final data = dataAutorizacao.toString();
        final hora = horaAutorizacao.toString();
        return 'Autorizado em: $data às $hora';
      } catch (e) {
        return 'Autorizado';
      }
    } else if (dataAutorizacao != null) {
      return 'Autorizado em: ${_formatarData(dataAutorizacao)}';
    }

    return 'Autorizado';
  }

  Widget _buildFormulario() {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: orangeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.local_taxi,
                      color: orangeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _tituloTela,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                "Preencha os dados do veículo",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 32),

              // Mensagem de erro
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Mensagem de sucesso
              if (_successMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Campo Veículo
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _veiculoController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: blueColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    hintText: "Modelo do veículo",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.directions_car_rounded,
                      color: blueColor,
                      size: 24,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o veículo';
                    }
                    return null;
                  },
                ),
              ),

              // Campo Placa
              Container(
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _placaController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: blueColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    hintText: "ABC-1234",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                    prefixIcon: Icon(
                      Icons.confirmation_number_rounded,
                      color: blueColor,
                      size: 24,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a placa';
                    }
                    if (value.length < 7) {
                      return 'Placa deve ter 7 caracteres';
                    }
                    return null;
                  },
                ),
              ),

              // Botão
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _autorizarUber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isLoading ? Colors.grey.shade400 : orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _isLoading ? 0 : 4,
                    shadowColor: orangeColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Autorizar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
