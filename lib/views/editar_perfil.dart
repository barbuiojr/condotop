import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _sessionService = SessionService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _blocoController = TextEditingController();
  final _uhController = TextEditingController();
  final _condominioController = TextEditingController();
  final _statusController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  int? _moradorId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _blocoController.dispose();
    _uhController.dispose();
    _condominioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final idMorador = _sessionService.getIdMorador();
    if (idMorador == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível identificar o usuário logado.';
      });
      return;
    }

    _moradorId = idMorador;

    try {
      final response = await _apiService.get('/moradores/$idMorador');
      final data = Map<String, dynamic>.from(response.data as Map);
      final idCondominio = _extractCondominioId(data);

      final condominioNome = await _loadCondominioNome(idCondominio);
      final statusLabel = _getStatusLabel(
        _parseInt(data['status']) ??
            _parseInt(data['ativo']) ??
            _parseInt(data['situacao']),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nomeController.text = (data['nome'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _telefoneController.text = _formatTelefone(
          (data['telefone'] ?? '').toString(),
        );
        _cpfController.text = _formatCpf(
          (data['cpf'] ?? '').toString(),
        );
        _blocoController.text = (data['bloco'] ?? '').toString();
        _uhController.text = (data['uh'] ?? '').toString();
        _condominioController.text = condominioNome ?? 'Não informado';
        _statusController.text = statusLabel;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar seu perfil.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_moradorId == null) {
      setState(() {
        _errorMessage = 'Não foi possível identificar o usuário logado.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final body = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'cpf': _cpfController.text.trim(),
      'bloco': _blocoController.text.trim(),
      'uh': _uhController.text.trim(),
    };

    try {
      await _apiService.put('/moradores/${_moradorId!}', body);

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _errorMessage = 'Não foi possível atualizar seu perfil.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        backgroundColor: blueColor,
        centerTitle: true,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildInput(
                      controller: _condominioController,
                      hint: 'Condomínio',
                      icon: Icons.location_city_outlined,
                      color: blueColor,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _nomeController,
                      hint: 'Nome',
                      icon: Icons.person_outline_rounded,
                      color: blueColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      color: blueColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu email';
                        }
                        if (!value.contains('@')) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _telefoneController,
                      hint: 'Telefone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      color: blueColor,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _TelefoneBrInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu telefone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _cpfController,
                      hint: 'CPF',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      color: blueColor,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CpfInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu CPF';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _blocoController,
                      hint: 'Bloco',
                      icon: Icons.apartment_outlined,
                      color: blueColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu bloco';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _uhController,
                      hint: 'UH',
                      icon: Icons.home_outlined,
                      color: blueColor,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe sua UH';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: _statusController,
                      hint: 'Status da conta',
                      icon: Icons.verified_user_outlined,
                      color: blueColor,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isSaving ? Colors.grey.shade400 : orangeColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _isSaving ? 0 : 4,
                          shadowColor: orangeColor.withOpacity(0.4),
                        ),
                        child: _isSaving
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
                                'Salvar alterações',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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

  int? _extractCondominioId(Map<String, dynamic> data) {
    final directId = _parseInt(data['id_condominio']) ??
        _parseInt(data['condominio_id']) ??
        _parseInt(data['condominioId']);

    if (directId != null) {
      return directId;
    }

    final condominio = data['condominio'];
    if (condominio is Map) {
      final condominioMap = Map<String, dynamic>.from(condominio);
      return _parseInt(condominioMap['id']) ??
          _parseInt(condominioMap['id_condominio']) ??
          _parseInt(condominioMap['condominio_id']);
    }

    return null;
  }

  Future<String?> _loadCondominioNome(int? idCondominio) async {
    if (idCondominio == null) {
      return null;
    }

    try {
      final response = await _apiService.get('/condominios/$idCondominio');
      final data = response.data;

      if (data is Map) {
        final mappedData = Map<String, dynamic>.from(data);

        final rootNome = mappedData['nome'] ??
            mappedData['nome_condominio'] ??
            mappedData['condominio'];
        if (rootNome != null && rootNome is! Map) {
          return rootNome.toString();
        }

        final nestedData = mappedData['data'];
        if (nestedData is Map) {
          final nestedMap = Map<String, dynamic>.from(nestedData);
          final nestedNome = nestedMap['nome'] ??
              nestedMap['nome_condominio'] ??
              nestedMap['condominio'];
          if (nestedNome != null) {
            return nestedNome.toString();
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao buscar condomínio ($idCondominio): $e');
      return null;
    }

    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String _getStatusLabel(int? status) {
    if (status == 1) {
      return 'Ativo';
    }
    return 'Pendente/Inativo';
  }

  String _formatTelefone(String value) {
    final onlyDigits = value.replaceAll(RegExp(r'\D'), '');
    final formatter = _TelefoneBrInputFormatter();
    return formatter
        .formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: onlyDigits),
        )
        .text;
  }

  String _formatCpf(String value) {
    final onlyDigits = value.replaceAll(RegExp(r'\D'), '');
    final formatter = _CpfInputFormatter();
    return formatter
        .formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: onlyDigits),
        )
        .text;
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool obscure = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
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
        obscureText: obscure,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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

class _TelefoneBrInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final buffer = StringBuffer();

    if (digits.isNotEmpty) {
      buffer.write('(');
      buffer.write(digits.substring(0, digits.length >= 2 ? 2 : digits.length));

      if (digits.length >= 2) {
        buffer.write(')');
      }
    }

    if (digits.length > 2) {
      buffer.write(' ');
      buffer.write(digits.substring(2, 3));
    }

    if (digits.length > 3) {
      final end = digits.length >= 7 ? 7 : digits.length;
      buffer.write(' ');
      buffer.write(digits.substring(3, end));
    }

    if (digits.length > 7) {
      buffer.write('-');
      buffer.write(digits.substring(7));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    final buffer = StringBuffer();

    if (digits.isNotEmpty) {
      final first = digits.length >= 3 ? 3 : digits.length;
      buffer.write(digits.substring(0, first));
    }

    if (digits.length > 3) {
      final second = digits.length >= 6 ? 6 : digits.length;
      buffer.write('.');
      buffer.write(digits.substring(3, second));
    }

    if (digits.length > 6) {
      final third = digits.length >= 9 ? 9 : digits.length;
      buffer.write('.');
      buffer.write(digits.substring(6, third));
    }

    if (digits.length > 9) {
      buffer.write('-');
      buffer.write(digits.substring(9));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
