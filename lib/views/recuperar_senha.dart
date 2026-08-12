import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RecuperarSenhaEmail extends StatefulWidget {
  const RecuperarSenhaEmail({super.key});

  @override
  State<RecuperarSenhaEmail> createState() => _RecuperarSenhaEmailState();
}

class _RecuperarSenhaEmailState extends State<RecuperarSenhaEmail> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> enviarEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _apiService.post('/auth/forgot-password/request', {
      'email': _emailController.text.trim(),
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecuperarSenhaOtp(
          email: _emailController.text.trim(),
        ),
      ),
    );
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
          'Esqueci minha senha',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informe seu e-mail',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enviaremos um código OTP no e-mail informado.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _emailController,
                hint: 'E-mail',
                icon: Icons.email_outlined,
                color: blueColor,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe seu e-mail';
                  }
                  if (!value.contains('@')) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    await enviarEmail();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: orangeColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Seguinte',
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

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
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

class RecuperarSenhaOtp extends StatefulWidget {
  const RecuperarSenhaOtp({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<RecuperarSenhaOtp> createState() => _RecuperarSenhaOtpState();
}

class _RecuperarSenhaOtpState extends State<RecuperarSenhaOtp> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _errorMessage;
  bool _isNavigating = false;
  final _apiService = ApiService();

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _otpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  bool _isOtpValido() {
    final otp = _otpCode();
    return otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
  }

  // void _goToNextStep() {
  //   if (_isNavigating) {
  //     return;
  //   }

  //   _isNavigating = true;
  //   Navigator.of(context)
  //       .push(
  //     MaterialPageRoute(
  //       builder: (context) => const RecuperarSenhaNovaSenha(resetToken: ,),
  //     ),
  //   )
  //       .then((_) {
  //     if (mounted) {
  //       _isNavigating = false;
  //     }
  //   });
  // }

  void _validarEContinuar() {
    if (!_isOtpValido()) {
      setState(() {
        _errorMessage = 'Informe os 6 dígitos do código OTP';
      });
      return;
    }
  }

  void _applyPastedOtp(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 6) {
      return;
    }

    final otp = digitsOnly.substring(0, 6);
    for (var i = 0; i < 6; i++) {
      _otpControllers[i].text = otp[i];
    }
    _focusNodes.last.unfocus();

    setState(() {
      _errorMessage = null;
    });

    _validarEContinuar();
  }

  Future<void> _confirmarOtp(String otp) async {
    setState(() {
      // _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.post(
        '/auth/forgot-password/verify-otp',
        {
          'email': widget.email,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => RecuperarSenhaNovaSenha(
                  resetToken: response.data["reset_token"].toString())),
          (route) => false,
        );
        return;
      }

      setState(() {
        // _errorMessage = _messageFrom(response.data) ?? 'Não foi possível confirmar o código.';
        // _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // _errorMessage = _messageFrom(_responseDataFrom(e)) ??
        //     'Não foi possível confirmar o código. Tente novamente.';
        // _isLoading = false;
      });
    }
  }

  Widget _buildOtpBox(int index, Color blueColor) {
    return SizedBox(
      width: 46,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: blueColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            _applyPastedOtp(value);
            print("fim");
            return;
          }

          setState(() {
            _errorMessage = null;
          });

          if (value.isNotEmpty && index < _focusNodes.length - 1) {
            _focusNodes[index + 1].requestFocus();
          }

          if (value.isNotEmpty && index == _focusNodes.length - 1) {
            _focusNodes[index].unfocus();
            _validarEContinuar();

            // aqui vai chamar o metodo de validação do OTP, que você pode implementar conforme sua lógica

            _confirmarOtp(_otpControllers.map((c) => c.text).join().toString());
          }

          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
        onSubmitted: (_) {
          if (index == _focusNodes.length - 1) {
            _validarEContinuar();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);

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
          'Validar código OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Digite o código',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informe os números do OTP enviado para ${widget.email}.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => _buildOtpBox(index, blueColor),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RecuperarSenhaNovaSenha extends StatefulWidget {
  final String resetToken;
  const RecuperarSenhaNovaSenha({super.key, required this.resetToken});

  @override
  State<RecuperarSenhaNovaSenha> createState() =>
      _RecuperarSenhaNovaSenhaState();
}

class _RecuperarSenhaNovaSenhaState extends State<RecuperarSenhaNovaSenha> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  final _apiService = ApiService();

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _finalizarRedefinicao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) {
      return;
    }

    if (_novaSenhaController.text.length < 8) {
      setState(() {
        _errorMessage = 'A nova senha deve ter pelo menos 8 caracteres';
        _isLoading = false;
      });
      return;
    }

    dynamic response = await _apiService.post('/auth/forgot-password/reset', {
      'reset_token': widget.resetToken,
      'nova_senha': _novaSenhaController.text.trim(),
    });

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Senha redefinida com sucesso!');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
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
          'Redefinir Senha',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
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
                controller: _novaSenhaController,
                hint: 'Nova senha',
                icon: Icons.lock_outline_rounded,
                color: blueColor,
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a nova senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildInput(
                controller: _confirmarSenhaController,
                hint: 'Confirmar senha',
                icon: Icons.lock_reset_rounded,
                color: blueColor,
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a nova senha';
                  }
                  if (value != _novaSenhaController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finalizarRedefinicao,
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
                          'Redefinir',
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

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool obscure = false,
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
