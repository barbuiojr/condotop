import 'dart:convert';
import 'dart:io';

import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/app_snackbar.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegistroOcorrenciaForm extends StatefulWidget {
  const RegistroOcorrenciaForm({
    super.key,
    this.endpoint = '/reclamacoes/',
    this.tituloTela = 'Registrar Reclamação',
    this.dataField = 'data_reclamacao',
    this.successMessage = 'Reclamação cadastrada com sucesso!',
    this.descricaoValidatorMessage =
        'Por favor, descreva o motivo da reclamação',
    this.descricaoHint = 'Descreva o que aconteceu...',
    this.errorFallbackMessage =
        'Erro ao registrar reclamação. Tente novamente.',
  });

  final String endpoint;
  final String tituloTela;
  final String dataField;
  final String successMessage;
  final String descricaoValidatorMessage;
  final String descricaoHint;
  final String errorFallbackMessage;

  @override
  State<RegistroOcorrenciaForm> createState() => _RegistroOcorrenciaFormState();
}

class _RegistroOcorrenciaFormState extends State<RegistroOcorrenciaForm> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _sessionService = SessionService();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  String _urgencia = 'Média';
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  File? _fotoReclamacao;

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

        final body = {
          'id_condominio': idCondominio,
          'id_morador': idMorador,
          'urgencia': _urgencia,
          'descricao': descricao,
          widget.dataField: DateTime.now().toIso8601String(),
        };

        dynamic payload = body;
        Options? options;
        if (_fotoReclamacao != null) {
          final fileName = _fotoReclamacao!.path.split('/').last;
          payload = FormData.fromMap({
            ...body,
            'foto': await MultipartFile.fromFile(
              _fotoReclamacao!.path,
              filename: fileName,
            ),
          });
          options = Options(
            contentType: 'multipart/form-data',
          );
        }

        // Debug: imprimir o body
        print('📤 Enviando para API: $body');

        // Enviar para a API
        final response =
            await _apiService.post(widget.endpoint, payload, options: options);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Criar JSON para o QR code (mesmo formato)
          final jsonString = jsonEncode(body);

          setState(() {
            _isLoading = false;
            _descricaoController.clear();
            _fotoReclamacao = null;
          });

          AppSnackbar.showSuccess(context, widget.successMessage);

          // Debug: imprimir o JSON gerado
          print('✅ Reclamação cadastrada com sucesso: $jsonString');
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.data['message'] ??
                response.data['error'] ??
                widget.errorFallbackMessage;
          });
        }
      } catch (e) {
        String errorMsg = widget.errorFallbackMessage;
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

  Future<void> _selecionarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _fotoReclamacao = File(picked.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        centerTitle: true,
        title: Text(
          widget.tituloTela,
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
                      return widget.descricaoValidatorMessage;
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
                    hintText: widget.descricaoHint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Foto (opcional)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 45,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _selecionarFoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _fotoReclamacao == null ? 'Adicionar foto' : 'Alterar foto',
                  ),
                ),
              ),
              if (_fotoReclamacao != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        _fotoReclamacao!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _fotoReclamacao = null;
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
