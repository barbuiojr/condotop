import 'package:flutter/material.dart';
import 'package:condotop/utils/auth_service.dart';
import 'package:condotop/views/dashboar.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        // Redirecionar para dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erro ao fazer login';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ---------- TOPO ----------
                      Container(
                        height: size.height * 0.42,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // FUNDO AZUL
                            Container(
                              width: double.infinity,
                              height: size.height * 0.30,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(225, 0, 68, 170),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(top: 40),
                              child: const Text(
                                "Bem-vindo ao",
                                style: TextStyle(
                                  fontSize: 28,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // LOGO
                            Positioned(
                              bottom: size.height * 0.02,
                              child: Image.asset(
                                "assets/logo/logo_condotop.png",
                                height: 180,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---------- FORMULÁRIO ----------
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Mensagem de erro
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: Colors.red.shade300),
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

                              // Usuário
                              _buildInput(
                                controller: _usernameController,
                                hint: "Usuário",
                                obscure: false,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira seu usuário';
                                  }
                                  return null;
                                },
                              ),

                              // Senha
                              _buildInput(
                                controller: _passwordController,
                                hint: "Senha",
                                obscure: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira sua senha';
                                  }
                                  return null;
                                },
                              ),

                              // BOTÃO ENTRAR
                              SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLoading
                                        ? Colors.grey
                                        : const Color.fromARGB(
                                            255, 255, 102, 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: _isLoading ? 0 : 3,
                                    shadowColor: Colors.black.withOpacity(0.2),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          "Entrar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  "Cadastrar-se",
                                  style: TextStyle(
                                    color: Color.fromARGB(225, 0, 68, 170),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),

                // ---------- RODAPÉ ----------
                // Stack(
                //   alignment: Alignment.bottomCenter,
                //   children: [
                //     Container(
                //       width: double.infinity,
                //       height: size.height * 0.13,
                //       decoration: BoxDecoration(
                //         color: const Color.fromARGB(255, 255, 102, 1),
                //         borderRadius: const BorderRadius.only(
                //           topLeft: Radius.circular(20),
                //           topRight: Radius.circular(20),
                //         ),
                //       ),
                //     ),
                //     Positioned(
                //       bottom: size.height * 0.02,
                //       child: Image.asset(
                //         "assets/logo/logo_ss.png",
                //         height: 100,
                //       ),
                //     ),
                //   ],
                // ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black54),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}
