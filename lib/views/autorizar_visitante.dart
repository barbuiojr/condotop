import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AutorizarVisitante extends StatefulWidget {
  const AutorizarVisitante({super.key});

  @override
  State<AutorizarVisitante> createState() => _AutorizarVisitanteState();
}

class _AutorizarVisitanteState extends State<AutorizarVisitante> {
  final String _qrCodeData = 'https://www.globo.com';

  Future<void> _compartilharQRCode() async {
    try {
      // Tentar abrir WhatsApp primeiro
      final mensagem = 'QR Code de Autorização de Visitante\n\nLink: $_qrCodeData';
      final whatsappUrl = 'https://wa.me/?text=${Uri.encodeComponent(mensagem)}';
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Se não conseguir abrir WhatsApp, usar compartilhamento genérico
        await Share.share(mensagem, subject: 'QR Code de Autorização');
      }
    } catch (e) {
      print('Erro ao compartilhar: $e');
      // Fallback para compartilhamento genérico
      await Share.share(
        'QR Code de Autorização de Visitante\n\nLink: $_qrCodeData',
      );
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
              "Apresente este código na portaria",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // QR Code
            Container(
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
                    data: _qrCodeData,
                    version: QrVersions.auto,
                    size: 280.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _qrCodeData,
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
            
            const SizedBox(height: 40),
            
            // Botão Compartilhar via WhatsApp
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
                  "Compartilhar via WhatsApp",
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
    );
  }
}
