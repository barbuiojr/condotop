import 'package:flutter/material.dart';

class AtasDocs extends StatefulWidget {
  const AtasDocs({super.key});

  @override
  State<AtasDocs> createState() => _AtasDocsState();
}

class _AtasDocsState extends State<AtasDocs> {
  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
        ),
        backgroundColor: blueColor,
        centerTitle: true,
        title: const Text(
          "Atas/Docs",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 80,
                color: blueColor,
              ),
              SizedBox(height: 16),
              Text(
                'Atas e Documentos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: blueColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Em breve você poderá acessar atas de reuniões e documentos do condomínio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
