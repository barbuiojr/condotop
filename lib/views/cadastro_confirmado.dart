import 'package:condotop/views/login.dart';
import 'package:flutter/material.dart';

class CadastroConfirmado extends StatelessWidget {
  const CadastroConfirmado({super.key});

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);
    const orangeColor = Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo/logo_condotop_without_bckground.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 68,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Usuário confirmado com sucesso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: blueColor,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Agora só falta a liberação do síndico. Assim que seu cadastro for aprovado, você poderá fazer login e usar o app normalmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Voltar para a tela de login',
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
      ),
    );
  }
}
