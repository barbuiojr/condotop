import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:condotop/utils/api.dart';
import 'package:crypto/crypto.dart';
class AutorizarVisitante extends StatefulWidget {
  const AutorizarVisitante({super.key});

  @override
  State<AutorizarVisitante> createState() => _AutorizarVisitanteState();
}

class _AutorizarVisitanteState extends State<AutorizarVisitante> {
  final GlobalKey _qrKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _sessionService = SessionService();
  final _apiService = ApiService();
  
  String? _qrCodeData;
  String? _qrCodeString;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  String _gerarStringAleatoria(int tamanho) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        tamanho,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<void> _gerarQRCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final nome = _nomeController.text.trim();
        final idMorador = _sessionService.getIdMorador();
        final idCondominio = _sessionService.getIdCondominio();

        if (idMorador == null || idCondominio == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erro: Dados do usuário não encontrados. Faça login novamente.';
          });
          return;
        }

        // Gerar string aleatória para o qrcode
        final qrcodeString = _gerarStringAleatoria(16);

        // Criar body para a API (sem data_entrada e hora_entrada, ou null)
        final body = {
          'nome': nome,
          'id_condominio': idCondominio,
          'id_morador': idMorador,
          'qrcode': qrcodeString,
          'data_entrada': null,
          'hora_entrada': null,
          'validade': 1
        };

        // Debug: imprimir o body
        print('📤 Enviando para API: $body');

        // Enviar para a API
        final response = await _apiService.post('/visitantes/', body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Criar JSON para o QR code (mesmo formato)
          final jsonString = jsonEncode(body);

          // Gera o hash SHA-256
          final bytes = utf8.encode(jsonString);
          final digest = sha256.convert(bytes);
          final sha256String = digest.toString();
          
          setState(() {
            _qrCodeData = sha256String; // 🔐 agora criptografado (hash)
            _qrCodeString = qrcodeString;
            _isLoading = false;
          });

          // Debug: imprimir o JSON gerado
          print('✅ QR Code gerado com sucesso: $jsonString');
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

  Future<Uint8List> _captureQRCode() async {
    try {
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (e) {
      print('Erro ao capturar QR code: $e');
      rethrow;
    }
  }

  Future<void> _compartilharQRCode() async {
    if (_qrCodeData == null) {
      return;
    }

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Capturar QR code como imagem
      final imageBytes = await _captureQRCode();

      // Salvar temporariamente
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qrcode_visitante.png');
      await file.writeAsBytes(imageBytes);

      // Compartilhar a imagem
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'QR Code de Autorização de Visitante\n\nApresente este código na portaria.',
        subject: 'QR Code de Autorização',
      );

      // Fechar loading
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Limpar arquivo temporário após um tempo
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });
    } catch (e) {
      print('Erro ao compartilhar QR code: $e');
      
      // Fechar loading se ainda estiver aberto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _limparFormulario() {
    _nomeController.clear();
    setState(() {
      _qrCodeData = null;
      _qrCodeString = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color.fromARGB(225, 0, 68, 170);
    final orangeColor = const Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        centerTitle: true,
        title: const Text(
          "Autorizar Visitante",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Título
              const Text(
                "QR Code de Autorização",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _qrCodeData == null
                    ? "Preencha o nome do visitante para gerar o QR code"
                    : "Apresente este código na portaria",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(height: 30),

              // Mensagem de erro
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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

              // Campo Nome do Visitante
              if (_qrCodeData == null) ...[
                _buildInput(
                  controller: _nomeController,
                  hint: "Nome completo do visitante",
                  icon: Icons.person_outline_rounded,
                  color: blueColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do visitante';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Botão Gerar QR Code
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _gerarQRCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading
                          ? Colors.grey.shade400
                          : orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isLoading ? 0 : 4,
                      shadowColor: orangeColor.withOpacity(0.4),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.qr_code_2,
                            color: Colors.white,
                            size: 24,
                          ),
                    label: Text(
                      _isLoading ? "Gerando..." : "Gerar QR Code",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // QR Code com RepaintBoundary para captura
                RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: _qrCodeData!,
                          version: QrVersions.auto,
                          size: 280.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Visitante: ${_nomeController.text.trim()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Código: $_qrCodeString',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Botão Compartilhar QR Code
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _compartilharQRCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.green.withOpacity(0.4),
                    ),
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      "Compartilhar QR Code",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Botão Nova Autorização
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _limparFormulario,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: blueColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Nova Autorização",
                      style: TextStyle(
                        color: blueColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
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
