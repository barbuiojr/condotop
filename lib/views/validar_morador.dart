import 'package:flutter/material.dart';

import '../utils/api.dart';
import '../utils/session_service.dart';

class ValidarMorador extends StatefulWidget {
  const ValidarMorador({super.key});

  @override
  State<ValidarMorador> createState() => _ValidarMoradorState();
}

class _ValidarMoradorState extends State<ValidarMorador> {
  final _apiService = ApiService();
  final _sessionService = SessionService();

  List moradoresInativos = [];

  buscaMoradorInativos() async {
    final idCondominio = _sessionService.getIdCondominio();
    try {
      final response =
          await _apiService.get('/moradores/inativos/$idCondominio');
      print("Moradores inativos: ${response.data}");
      moradoresInativos = response.data;
      setState(() {});
    } catch (e) {
      print("Erro ao buscar moradores inativos: $e");
    }
  }

  validarMorador(int idMorador) async {
    try {
      await _apiService.put('/moradores/aprovar/$idMorador', {"status": 1});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Morador validado com sucesso!")),
      );
      // Atualizar a lista de moradores inativos após a validação
      buscaMoradorInativos();
    } catch (e) {
      print("Erro ao validar morador: $e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    buscaMoradorInativos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 102, 1),
        centerTitle: true,
        title: Text(
          "Condotop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        mainAxisAlignment: moradoresInativos.isNotEmpty
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          moradoresInativos.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: moradoresInativos.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title:
                          Text("Morador: ${moradoresInativos[index]['nome']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bloco: ${moradoresInativos[index]['bloco']}"),
                          Text("UH: ${moradoresInativos[index]['uh']}"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          validarMorador(moradoresInativos[index]['id']);
                        },
                        child: Text("Validar"),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text("Nenhum morador para validar"),
                ),
        ],
      ),
    );
  }
}
