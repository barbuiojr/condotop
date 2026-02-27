import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/app_snackbar.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:flutter/material.dart';

class CadastroAreasComuns extends StatefulWidget {
  const CadastroAreasComuns({super.key});

  @override
  State<CadastroAreasComuns> createState() => _CadastroAreasComunsState();
}

class _CadastroAreasComunsState extends State<CadastroAreasComuns> {
  final _apiService = ApiService();
  final _sessionService = SessionService();
  final _nomeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _areas = [];

  @override
  void initState() {
    super.initState();
    _carregarAreas();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _carregarAreas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final idCondominio = _sessionService.getIdCondominio();
    if (idCondominio == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível identificar o condomínio.';
      });
      return;
    }

    try {
      dynamic data;

      try {
        final response = await _apiService.get(
          '/areas-comuns/',
          query: {'id_condominio': idCondominio},
        );
        data = response.data;
      } catch (_) {
        final response =
            await _apiService.get('/areas-comuns/condominio/$idCondominio');
        data = response.data;
      }

      final lista = _extrairLista(data).where((item) {
        final itemCondominio = _toInt(
          item['id_condominio'] ??
              item['idCondominio'] ??
              item['condominio_id'] ??
              item['condominioId'],
        );
        return itemCondominio == null || itemCondominio == idCondominio;
      }).toList()
        ..sort((a, b) {
          final nomeA = (a['nome'] ?? '').toString().toLowerCase();
          final nomeB = (b['nome'] ?? '').toString().toLowerCase();
          return nomeA.compareTo(nomeB);
        });

      if (!mounted) {
        return;
      }

      setState(() {
        _areas = lista;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar as áreas comuns.';
      });
    }
  }

  List<Map<String, dynamic>> _extrairLista(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      for (final key in ['data', 'items', 'areas_comuns', 'areas']) {
        final value = map[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _cadastrarArea() async {
    final nome = _nomeController.text.trim();
    final idCondominio = _sessionService.getIdCondominio();

    if (nome.isEmpty) {
      AppSnackbar.showError(context, 'Informe o nome da área comum.');
      return;
    }

    if (idCondominio == null) {
      AppSnackbar.showError(
          context, 'Não foi possível identificar o condomínio.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final body = {
        'id_condominio': idCondominio,
        'nome': nome,
      };

      final response = await _apiService.post('/areas-comuns/', body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _nomeController.clear();
        AppSnackbar.showSuccess(context, 'Área comum cadastrada com sucesso!');
        await _carregarAreas();
      } else {
        AppSnackbar.showError(
            context, 'Não foi possível cadastrar a área comum.');
      }
    } catch (_) {
      AppSnackbar.showError(
          context, 'Não foi possível cadastrar a área comum.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);
    const orangeColor = Color.fromARGB(255, 255, 102, 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blueColor,
        centerTitle: true,
        title: const Text(
          'Áreas Comuns',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarAreas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome da área comum',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _cadastrarArea,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaving ? Colors.grey.shade400 : orangeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cadastrar área comum',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              )
            else if (_areas.isEmpty)
              const Text(
                'Nenhuma área comum cadastrada ainda.',
                textAlign: TextAlign.center,
              )
            else
              ..._areas.map((area) {
                final nome = (area['nome'] ?? 'Sem nome').toString();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(nome),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
