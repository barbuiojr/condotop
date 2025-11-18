import 'package:flutter/material.dart';
import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';

class SolicitacaoUber extends StatefulWidget {
  const SolicitacaoUber({super.key});

  @override
  State<SolicitacaoUber> createState() => _SolicitacaoUberState();
}

class _SolicitacaoUberState extends State<SolicitacaoUber> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _veiculoController = TextEditingController();
  final _apiService = ApiService();
  final _sessionService = SessionService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _placaController.dispose();
    _veiculoController.dispose();
    super.dispose();
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
            _errorMessage = 'Erro: Dados do usuário não encontrados. Faça login novamente.\n'
                'ID Morador: ${idMorador ?? "null"}\n'
                'ID Condomínio: ${idCondominio ?? "null"}';
          });
          return;
        }

        // Preparar body da requisição
        final body = {
          "placa": _placaController.text.trim().toUpperCase(),
          "veiculo": _veiculoController.text.trim(),
          "tipo_servico": "Uber",
          "id_morador": idMorador,
          "id_condominio": idCondominio,
        };

        // Chamar API
        final response = await _apiService.post('/acessos/uber', body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _isLoading = false;
            _successMessage = 'Uber autorizado com sucesso!';
          });

          // Limpar campos após sucesso
          _placaController.clear();
          _veiculoController.clear();

          // Opcional: Voltar para tela anterior após alguns segundos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erro ao autorizar Uber. Tente novamente.';
          });
        }
      } catch (e) {
        String errorMessage = 'Erro ao autorizar Uber';
        
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TOPO
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 60),
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.2,
                        color: const Color.fromARGB(225, 0, 68, 170),
                        child: Image.asset(
                          'assets/logo/logo_condotop_bg.png',
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.10,
                        color: const Color.fromARGB(225, 0, 68, 170),
                        child: const Text(
                          "Morador",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // FORMULÁRIO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Uber",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Mensagem de erro
                          if (_errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Mensagem de sucesso
                          if (_successMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _successMessage!,
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Veículo
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black),
                            ),
                            child: TextFormField(
                              controller: _veiculoController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(10),
                                hintText: "Veículo",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o veículo';
                                }
                                return null;
                              },
                            ),
                          ),

                          // Placa
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black),
                            ),
                            child: TextFormField(
                              controller: _placaController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(10),
                                hintText: "Placa",
                              ),
                              textCapitalization: TextCapitalization.characters,
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
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _autorizarUber,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLoading
                                    ? Colors.grey
                                    : const Color.fromARGB(255, 255, 102, 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: _isLoading ? 0 : 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      "Autorizar",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // RODAPÉ
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.15,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 255, 102, 1),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 58),
                        child: Image.asset(
                          "assets/logo/logo_ss.png",
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
