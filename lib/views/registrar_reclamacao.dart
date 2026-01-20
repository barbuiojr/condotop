import 'dart:convert';

import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:flutter/material.dart';

class RegistrarReclamacao extends StatefulWidget {
  const RegistrarReclamacao({super.key});

  @override
  State<RegistrarReclamacao> createState() => _RegistrarReclamacaoState();
}

class _RegistrarReclamacaoState extends State<RegistrarReclamacao> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _sessionService = SessionService();
  final _apiService = ApiService();
  String _urgencia = 'Média';
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _registrarReclamacao() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final descricao = _descricaoController.text.trim();
        final idMorador = _sessionService.getIdMorador();
        final idCondominio = _sessionService.getIdCondominio();

        if (idMorador == null || idCondominio == null) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Erro: Dados do usuário não encontrados. Faça login novamente.';
          });
          return;
        }

        // Criar body para a API (sem data_entrada e hora_entrada, ou null)
        final body = {
          'id_condominio': idCondominio,
          'id_morador': idMorador,
          'urgencia': _urgencia,
          'descricao': descricao,
          'data_reclamacao': DateTime.now().toIso8601String(),
        };

        // Debug: imprimir o body
        print('📤 Enviando para API: $body');

        // Enviar para a API
        final response = await _apiService.post('/reclamacoes/', body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Criar JSON para o QR code (mesmo formato)
          final jsonString = jsonEncode(body);

          setState(() {
            _isLoading = false;
          });

          // Debug: imprimir o JSON gerado
          print('✅ Reclamação cadastrada com sucesso: $jsonString');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.data['message'] ??
                response.data['error'] ??
                'Erro ao criar autorização de visitante';
          });
        }
      } catch (e) {
        String errorMsg = 'Erro ao gerar QR code';
        if (e.toString().contains('DioException')) {
          try {
            final errorData = (e as dynamic).response?.data;
            if (errorData != null && errorData is Map) {
              errorMsg = errorData['message'] ??
                  errorData['error'] ??
                  errorData['detail'] ??
                  errorMsg;
            }
          } catch (_) {}
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });

        print('❌ Erro ao gerar QR code: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: orangeColor,
        centerTitle: true,
        title: const Text(
          "Registrar Reclamação",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Combobox de urgência
              Text(
                "Urgência",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _urgencia,
                items: const [
                  DropdownMenuItem(
                    value: 'Alta',
                    child: Text('Alta'),
                  ),
                  DropdownMenuItem(
                    value: 'Média',
                    child: Text('Média'),
                  ),
                  DropdownMenuItem(
                    value: 'Baixa',
                    child: Text('Baixa'),
                  ),
                ],
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _urgencia = value;
                  });
                },
              ),

              const SizedBox(height: 20),

              // Campo de descrição
              Text(
                "Descrição",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descricaoController,
                  maxLines: 5,
                  minLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, descreva o motivo da reclamação';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: orangeColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: "Descreva o que aconteceu...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mensagens
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Botão registrar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registrarReclamacao,
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          "Registrar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRegistrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Aqui você poderá integrar com a API futuramente.
      // Por enquanto, apenas simulamos um sucesso.
      await Future.delayed(const Duration(milliseconds: 600));

      setState(() {
        _isLoading = false;
        _successMessage = 'Reclamação registrada com sucesso!';
      });

      _descricaoController.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao registrar reclamação. Tente novamente.';
      });
    }
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: color,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
      ),
    );
  }
}
