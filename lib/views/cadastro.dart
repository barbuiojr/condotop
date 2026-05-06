import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:condotop/utils/api.dart';
import 'package:condotop/views/login.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _blocoController = TextEditingController();
  final _uhController = TextEditingController();
  final _senhaController = TextEditingController();

  // CPF lookup (reused from autorizar_visitante flow)
  static const String _cpfApiKey =
      '31ddf121ff9267b4850063e325c2138b7bad987004543248b7db08a9453a2e7f';
  final Dio _cpfDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  bool _isConsultingCpf = false;
  String? _ultimoCpfConsultado;
  bool _nomeReadOnly = false;

  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isLoadingCondominios = false;
  String? _errorMessage;
  String? _successMessage;

  List<dynamic> _condominios = [];
  dynamic _condominioSelecionado;
  dynamic _isProprietario;

  @override
  void initState() {
    super.initState();
    _carregarCondominios();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _blocoController.dispose();
    _uhController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarCondominios() async {
    setState(() {
      _isLoadingCondominios = true;
      // Não limpar _errorMessage aqui para não apagar erros de cadastro
    });

    try {
      final response = await _apiService.get('/condominios/');

      if (response.statusCode == 200) {
        // Se a resposta for 200, mesmo que vazia, é sucesso
        setState(() {
          if (response.data != null && response.data is List) {
            _condominios = response.data;
            // Debug: imprimir os condomínios recebidos
            print('📦 Condomínios recebidos:');
            for (var cond in _condominios) {
              print('  - $cond');
            }
          } else {
            _condominios = [];
          }
          _isLoadingCondominios = false;
        });
      } else {
        // Só mostrar erro se não for 200 (erro do servidor)
        setState(() {
          _condominios = [];
          _isLoadingCondominios = false;
          // Não definir _errorMessage aqui para não mostrar erro na tela
        });
      }
    } catch (e) {
      // Em caso de erro de conexão, apenas deixar a lista vazia
      // Não mostrar mensagem de erro na tela
      setState(() {
        _condominios = [];
        _isLoadingCondominios = false;
        // Não definir _errorMessage aqui para não mostrar erro na tela
      });
    }
  }

  Future<void> _handleCadastro() async {
    if (_formKey.currentState!.validate()) {
      if (_condominioSelecionado == null) {
        setState(() {
          _errorMessage = 'Por favor, selecione um condomínio';
        });
        return;
      }

      if (_isProprietario == null) {
        setState(() {
          _errorMessage = 'Por favor, selecione se é proprietário ou inquilino';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final idCondominio = _condominioSelecionado['id'] ??
            _condominioSelecionado['id_condominio'] ??
            0;

        String fcmToken = '';
        try {
          // fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
        } catch (_) {}

        final body = {
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'telefone':
              _telefoneController.text.trim().replaceAll(RegExp(r'[^\d]'), ''),
          'cpf': _cpfController.text.trim().replaceAll(RegExp(r'[^\d]'), ''),
          'bloco': _blocoController.text.trim(),
          'uh': _uhController.text.trim(), // UH deve ser string, não número
          'id_condominio': idCondominio,
          'proprietario': _isProprietario ? 1 : 0,
          'senha': _senhaController.text,
          'fcm_token': fcmToken,
        };

        // Debug: imprimir o corpo da requisição
        print('📤 Corpo da requisição de cadastro:');
        print(body);
        print('📤 JSON: ${body.toString()}');

        final response = await _apiService.post('/moradores/cadastro', body);

          if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _successMessage = 'Cadastro realizado com sucesso!';
            _isLoading = false;
          });

          // Aguardar um pouco e redirecionar para login
          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        } else {
          setState(() {
            _errorMessage = response.data['message'] ??
                response.data['error'] ??
                'Erro ao realizar cadastro';
            _isLoading = false;
          });
        }
      } catch (e) {
        String errorMsg = 'Erro ao realizar cadastro';
        if (e.toString().contains('DioException')) {
          try {
            final errorData = (e as dynamic).response?.data;
            if (errorData != null && errorData is Map) {
              errorMsg = errorData['message'] ?? errorData['error'] ?? errorData["detail"] ?? errorMsg;
            }
          } catch (_) {}
        }

        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  String _apenasDigitos(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  void _onCpfChanged(String value) {
    final cpf = _apenasDigitos(value);
    if (cpf.length < 11) {
      setState(() {
        _nomeController.clear();
        _ultimoCpfConsultado = null;
        _nomeReadOnly = false;
        _errorMessage = null;
      });
      return;
    }

    if (cpf == _ultimoCpfConsultado || _isConsultingCpf) return;

    _consultarCpf(cpf);
  }

  Future<void> _consultarCpf(String cpf) async {
    if (!mounted) return;
    setState(() {
      _isConsultingCpf = true;
      _errorMessage = null;
    });

    try {
      final response = await _cpfDio.get(
        'https://apicpf.com/api/consulta',
        queryParameters: {'cpf': cpf},
        options: Options(headers: {
          'X-API-KEY': _cpfApiKey,
          'Accept': 'application/json',
        }),
      );

      String? nome;
      if (response.data != null) {
        // tentar extrair nome de forma robusta (mesma lógica usada em autorizar_visitante)
        dynamic data = response.data;
        String? extractName(dynamic d) {
          if (d is Map) {
            const possibleKeys = ['nome', 'Nome', 'NOME', 'name'];
            for (final key in possibleKeys) {
              final value = d[key];
              if (value is String && value.trim().isNotEmpty) return value.trim();
            }
            for (final v in d.values) {
              final nested = extractName(v);
              if (nested != null && nested.isNotEmpty) return nested;
            }
          }
          if (d is List) {
            for (final item in d) {
              final nested = extractName(item);
              if (nested != null && nested.isNotEmpty) return nested;
            }
          }
          return null;
        }

        nome = extractName(data);
      }

      if ((response.statusCode == 200 || response.statusCode == 201) && nome != null && nome.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _nomeController.text = nome!;
          _ultimoCpfConsultado = cpf;
          _nomeReadOnly = true; // bloquear edição do nome
        });
      } else {
        if (!mounted) return;
        setState(() {
          _nomeController.clear();
          _ultimoCpfConsultado = null;
          _nomeReadOnly = false; // liberar edição em caso de falha
          _errorMessage = 'CPF consultado, mas o nome não foi retornado.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      String mensagem = 'Erro ao consultar CPF. Tente novamente.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          mensagem = data['message']?.toString() ?? data['error']?.toString() ?? data['detail']?.toString() ?? mensagem;
        }
      }

      setState(() {
        _nomeController.clear();
        _ultimoCpfConsultado = null;
        _nomeReadOnly = false; // liberar edição em caso de erro
        _errorMessage = mensagem;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isConsultingCpf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: blueColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título do formulário
                const Text(
                  "Criar Conta",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Preencha os dados para se cadastrar",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),

                // Mensagem de sucesso
                if (_successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Mensagem de erro
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

                // ComboBox Condomínio
                _buildCondominioDropdown(blueColor),

                const SizedBox(height: 12),

                // Campo CPF (moved to be first after condomínio)
                _buildInput(
                  controller: _cpfController,
                  hint: "CPF",
                  icon: Icons.badge_outlined,
                  color: blueColor,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CpfInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu CPF';
                    }
                    final cpfDigits = value.replaceAll(RegExp(r'[^\d]'), '');
                    if (cpfDigits.length != 11) {
                      return 'CPF deve ter 11 dígitos';
                    }
                    return null;
                  },
                  onChanged: _onCpfChanged,
                ),

                const SizedBox(height: 12),

                // Campo Nome (moved to after CPF)
                _buildInput(
                  controller: _nomeController,
                  hint: "Nome completo",
                  icon: Icons.person_outline_rounded,
                  color: blueColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                  readOnly: _nomeReadOnly,
                ),

                const SizedBox(height: 12),

                // Campo Email (kept below Nome)
                _buildInput(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email_outlined,
                  color: blueColor,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Campo Telefone
                _buildInput(
                  controller: _telefoneController,
                  hint: "Telefone",
                  icon: Icons.phone_outlined,
                  color: blueColor,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _TelefoneBrInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu telefone';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Campo Bloco
                _buildInput(
                  controller: _blocoController,
                  hint: "Bloco",
                  icon: Icons.apartment_outlined,
                  color: blueColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o bloco';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Campo UH (Unidade Habitacional)
                _buildInput(
                  controller: _uhController,
                  hint: "UH",
                  icon: Icons.home_outlined,
                  color: blueColor,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a UH';
                    }
                    if (int.tryParse(value) == null) {
                      return 'UH deve ser um número';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Campo Senha
                _buildInput(
                  controller: _senhaController,
                  hint: "Senha",
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  color: blueColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Dropdown Proprietário/Inquilino
                _buildProprietarioDropdown(blueColor),

                const SizedBox(height: 20),

                // Botão Cadastrar
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isLoadingCondominios)
                        ? null
                        : _handleCadastro,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isLoading || _isLoadingCondominios)
                          ? Colors.grey.shade400
                          : orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: (_isLoading || _isLoadingCondominios) ? 0 : 4,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Cadastrar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Link Voltar para Login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Já tem uma conta? Entrar",
                        style: TextStyle(
                          color: blueColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: blueColor,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCondominioDropdown(Color color) {
    // Substituído por campo de busca com sugestões filtradas
    return _CondominioSearchField(
      condominios: _condominios,
      isLoading: _isLoadingCondominios,
      onSelected: (value) {
        setState(() {
          _condominioSelecionado = value;
          _errorMessage = null;
        });
      },
    );
  }

  Widget _buildProprietarioDropdown(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<bool>(
          value: _isProprietario,
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
              vertical: 4,
            ),
            prefixIcon: Icon(
              Icons.home_work_outlined,
              color: color,
              size: 22,
            ),
            hintText: 'Escolha uma opção', // Texto genérico para o hint
          ),
          items: const [
            DropdownMenuItem<bool>(value: true, child: Text('Proprietário')),
            DropdownMenuItem<bool>(value: false, child: Text('Inquilino')),
          ],
          onChanged: (v) {
            setState(() {
              _isProprietario = v!;
              _errorMessage = null;
            });
          },
          validator: (v) {
            if (v == null) return 'Por favor, selecione proprietário ou inquilino';
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    void Function(String)? onChanged,
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
        onChanged: onChanged,
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

// Widget de busca local para condomínios
class _CondominioSearchField extends StatefulWidget {
  final List<dynamic> condominios;
  final bool isLoading;
  final void Function(dynamic) onSelected;

  const _CondominioSearchField({
    required this.condominios,
    required this.isLoading,
    required this.onSelected,
  });

  @override
  State<_CondominioSearchField> createState() => _CondominioSearchFieldState();
}

class _CondominioSearchFieldState extends State<_CondominioSearchField> {
  final TextEditingController _ctrl = TextEditingController();
  List<dynamic> _filtered = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.condominios;
  }

  @override
  void didUpdateWidget(covariant _CondominioSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _filtered = widget.condominios;
  }

  void _onChanged(String v) {
    final q = v.toLowerCase();
    setState(() {
      _filtered = widget.condominios
          .where((c) => (c['nome'] ?? c['descricao'] ?? c['condominio'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q))
          .toList();
      _showSuggestions = v.isNotEmpty && _filtered.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color.fromARGB(225, 0, 68, 170);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            controller: _ctrl,
            onChanged: _onChanged,
            readOnly: widget.isLoading,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Por favor, selecione um condomínio';
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
              prefixIcon: Icon(
                Icons.business_outlined,
                color: color,
                size: 22,
              ),
              hintText: widget.isLoading ? 'Carregando condomínios...' : 'Digite o nome do condomínio',
            ),
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final item = _filtered[i];
                final nome = item['nome'] ?? item['descricao'] ?? item['condominio'] ?? 'Condomínio';
                return ListTile(
                  title: Text(nome.toString()),
                  onTap: () {
                    _ctrl.text = nome.toString();
                    widget.onSelected(item);
                    setState(() => _showSuggestions = false);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
