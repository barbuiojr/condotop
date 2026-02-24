import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/editar_perfil.dart';
import 'package:flutter/material.dart';

class DocumentosGerais extends StatefulWidget {
  const DocumentosGerais({super.key});

  @override
  State<DocumentosGerais> createState() => _DocumentosGeraisState();
}

class _DocumentosGeraisState extends State<DocumentosGerais> {
  SessionService _session = SessionService();
  bool _isLoading = false;
  final orangeColor = const Color.fromARGB(255, 255, 0, 0);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            )),
        backgroundColor: Color.fromARGB(225, 0, 68, 170),
        centerTitle: true,
        title: Text(
          "Documentos Gerais",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditarPerfil(),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading
                    ? Colors.grey.shade400
                    : const Color.fromARGB(225, 0, 68, 170),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isLoading ? 0 : 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Editar perfil",
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
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _session.clearSession();
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/login', (route) => false);
                    },
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Sair",
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
        ],
      ),
    );
  }
}
