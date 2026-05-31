import 'package:flutter/material.dart';

import '../utils/api.dart';
import '../utils/app_snackbar.dart';
import '../utils/session_service.dart';

class ValidarMorador extends StatefulWidget {
  const ValidarMorador({super.key});

  @override
  State<ValidarMorador> createState() => _ValidarMoradorState();
}

class _ValidarMoradorState extends State<ValidarMorador> {
  final _apiService = ApiService();
  final _sessionService = SessionService();

  List<Map<String, dynamic>> moradoresInativos = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> _normalizarListaMoradores(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);
      final candidatos = [
        mapData['data'],
        mapData['results'],
        mapData['items'],
        mapData['moradores'],
        mapData['inativos'],
      ];

      for (final candidato in candidatos) {
        if (candidato is List) {
          return candidato
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  int? _parseMoradorId(Map<String, dynamic> morador) {
    final dynamic id =
        morador['id'] ?? morador['id_morador'] ?? morador['morador_id'];
    if (id is int) {
      return id;
    }
    if (id is String) {
      return int.tryParse(id);
    }
    return null;
  }

  Future<void> buscaMoradorInativos() async {
    final idCondominio = _sessionService.getIdCondominio();
    if (idCondominio == null) {
      setState(() {
        _isLoading = false;
        moradoresInativos = [];
      });
      AppSnackbar.showError(
        context,
        'Não foi possível identificar o condomínio do síndico.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await _apiService.get('/moradores/inativos/$idCondominio');
      print("Moradores inativos: ${response.data}");
      final lista = _normalizarListaMoradores(response.data);
      setState(() {
        moradoresInativos = lista;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erro ao buscar moradores inativos: $e");
      AppSnackbar.showError(
        context,
        'Erro ao carregar moradores pendentes de validação.',
      );
    }
  }

  Future<void> validarMorador(int idMorador) async {
    try {
      await _apiService.put('/moradores/aprovar/$idMorador', {"status": 1});
      AppSnackbar.showSuccess(context, "Morador validado com sucesso!");
      // Atualizar a lista de moradores inativos após a validação
      buscaMoradorInativos();
    } catch (e) {
      print("Erro ao validar morador: $e");
      AppSnackbar.showError(context, 'Erro ao validar morador.');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Condotop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : moradoresInativos.isEmpty
              ? const Center(
                  child: Text("Nenhum morador para validar"),
                )
              : ListView.builder(
                  itemCount: moradoresInativos.length,
                  itemBuilder: (context, index) {
                    final morador = moradoresInativos[index];
                    final idMorador = _parseMoradorId(morador);

                    return ListTile(
                      title: Text(
                          "Morador: ${(morador['nome'] ?? '').toString()}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Bloco: ${(morador['bloco'] ?? '-').toString()}"),
                          Text("UH: ${(morador['uh'] ?? '-').toString()}"),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: idMorador == null
                            ? null
                            : () {
                                validarMorador(idMorador);
                              },
                        child: const Text("Validar"),
                      ),
                    );
                  },
                ),
    );
  }
}
