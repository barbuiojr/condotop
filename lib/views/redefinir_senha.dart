import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class RedefinirSenha extends StatefulWidget {
  const RedefinirSenha({super.key});

  @override
  State<RedefinirSenha> createState() => _RedefinirSenhaState();
}

class _RedefinirSenhaState extends State<RedefinirSenha> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _apiService = ApiService();
  final _sessionService = SessionService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _redefinirSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final idMorador = _sessionService.getIdMorador();
    if (idMorador == null) {
      setState(() {
        _errorMessage = 'Não foi possível identificar o usuário logado.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.put(
        '/moradores/redefinir-senha/$idMorador',
        {
          'senha': _novaSenhaController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _sessionService.clearSession();

        if (!mounted) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível redefinir a senha.';
      });
    } catch (e) {
      var msg = 'Não foi possível redefinir a senha.';
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['message'] != null) {
          msg = data['message'].toString();
        } else if (data['detail'] != null) {
          msg = data['detail'].toString();
        } else if (data['error'] != null) {
          msg = data['error'].toString();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = msg;
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
                  onPressed: _isLoading ? null : _redefinirSenha,
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
