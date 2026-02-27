import 'dart:convert';

import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:flutter/material.dart';

class ListaOcorrenciasSindico extends StatefulWidget {
  const ListaOcorrenciasSindico({
    super.key,
    required this.tituloTela,
    required this.endpoint,
    required this.tituloItem,
    required this.mensagemVazia,
  });

  final String tituloTela;
  final String endpoint;
  final String tituloItem;
  final String mensagemVazia;

  @override
  State<ListaOcorrenciasSindico> createState() =>
      _ListaOcorrenciasSindicoState();
}

class _ListaOcorrenciasSindicoState extends State<ListaOcorrenciasSindico> {
  final _apiService = ApiService();
  final _sessionService = SessionService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _ocorrencias = [];

  @override
  void initState() {
    super.initState();
    _carregarOcorrencias();
  }

  Future<void> _carregarOcorrencias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final idCondominio = _sessionService.getIdCondominio();

      dynamic data;
      try {
        final response = await _apiService.get(
          widget.endpoint,
          query: idCondominio != null ? {'id_condominio': idCondominio} : null,
        );
        data = response.data;
      } catch (_) {
        final response = await _apiService.get(widget.endpoint);
        data = response.data;
      }

      final ocorrencias = _extrairLista(data);

      final filtradas = idCondominio == null
          ? ocorrencias
          : ocorrencias.where((item) {
              final itemCondominio = _toInt(
                item['id_condominio'] ??
                    item['idCondominio'] ??
                    item['condominio_id'] ??
                    item['condominioId'],
              );
              return itemCondominio == null || itemCondominio == idCondominio;
            }).toList();

      filtradas.sort((a, b) {
        final dateA = _extractDate(a);
        final dateB = _extractDate(b);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      final enriquecidas = await _enriquecerComNomes(filtradas);

      if (!mounted) {
        return;
      }

      setState(() {
        _ocorrencias = enriquecidas;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível carregar os dados.';
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
      for (final key in [
        'data',
        'items',
        'result',
        'defeitos',
        'reclamacoes'
      ]) {
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

  DateTime? _extractDate(Map<String, dynamic> item) {
    final raw = item['created_at'] ??
        item['data_reclamacao'] ??
        item['data_defeito'] ??
        item['data'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  int? _extractMoradorId(Map<String, dynamic> item) {
    return _toInt(
      item['id_morador'] ??
          item['idMorador'] ??
          item['morador_id'] ??
          item['moradorId'],
    );
  }

  int? _extractCondominioId(Map<String, dynamic> item) {
    return _toInt(
      item['id_condominio'] ??
          item['idCondominio'] ??
          item['condominio_id'] ??
          item['condominioId'],
    );
  }

  Future<List<Map<String, dynamic>>> _enriquecerComNomes(
    List<Map<String, dynamic>> items,
  ) async {
    final nomesMoradores = <int, String>{};
    final nomesCondominios = <int, String>{};

    final idsMorador = <int>{};
    final idsCondominio = <int>{};

    for (final item in items) {
      final idMorador = _extractMoradorId(item);
      final nomeMoradorPresente =
          ((item['nome_morador'] ?? item['nomeMorador'])?.toString().trim() ??
                  '')
              .isNotEmpty;

      if (idMorador != null && !nomeMoradorPresente) {
        idsMorador.add(idMorador);
      }

      final idCondominio = _extractCondominioId(item);
      final nomeCondominioPresente =
          ((item['nome_condominio'] ?? item['nomeCondominio'])
                      ?.toString()
                      .trim() ??
                  '')
              .isNotEmpty;

      if (idCondominio != null && !nomeCondominioPresente) {
        idsCondominio.add(idCondominio);
      }
    }

    for (final id in idsMorador) {
      final nome = await _buscarNomeMorador(id);
      if (nome != null && nome.trim().isNotEmpty) {
        nomesMoradores[id] = nome.trim();
      }
    }

    for (final id in idsCondominio) {
      final nome = await _buscarNomeCondominio(id);
      if (nome != null && nome.trim().isNotEmpty) {
        nomesCondominios[id] = nome.trim();
      }
    }

    return items.map((item) {
      final novoItem = Map<String, dynamic>.from(item);

      final idMorador = _extractMoradorId(item);
      if (idMorador != null && nomesMoradores.containsKey(idMorador)) {
        novoItem['nome_morador'] = nomesMoradores[idMorador];
      }

      final idCondominio = _extractCondominioId(item);
      if (idCondominio != null && nomesCondominios.containsKey(idCondominio)) {
        novoItem['nome_condominio'] = nomesCondominios[idCondominio];
      }

      return novoItem;
    }).toList();
  }

  Future<String?> _buscarNomeMorador(int idMorador) async {
    try {
      final response = await _apiService.get('/moradores/$idMorador');
      final data = response.data;

      if (data is Map) {
        final mappedData = Map<String, dynamic>.from(data);

        final rootNome = mappedData['nome'] ?? mappedData['name'];
        if (rootNome != null && rootNome is! Map) {
          return rootNome.toString();
        }

        final nestedData = mappedData['data'];
        if (nestedData is Map) {
          final nestedMap = Map<String, dynamic>.from(nestedData);
          final nestedNome = nestedMap['nome'] ?? nestedMap['name'];
          if (nestedNome != null) {
            return nestedNome.toString();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _buscarNomeCondominio(int idCondominio) async {
    try {
      final response = await _apiService.get('/condominios/$idCondominio');
      final data = response.data;

      if (data is Map) {
        final mappedData = Map<String, dynamic>.from(data);

        final rootNome = mappedData['nome'] ??
            mappedData['nome_condominio'] ??
            mappedData['condominio'];
        if (rootNome != null && rootNome is! Map) {
          return rootNome.toString();
        }

        final nestedData = mappedData['data'];
        if (nestedData is Map) {
          final nestedMap = Map<String, dynamic>.from(nestedData);
          final nestedNome = nestedMap['nome'] ??
              nestedMap['nome_condominio'] ??
              nestedMap['condominio'];
          if (nestedNome != null) {
            return nestedNome.toString();
          }
        }
      }
    } catch (_) {}

    return null;
  }

  String _tituloOcorrencia(Map<String, dynamic> item) {
    final descricao = (item['descricao'] ??
            item['titulo'] ??
            item['assunto'] ??
            item['motivo'])
        ?.toString()
        .trim();

    if (descricao != null && descricao.isNotEmpty) {
      return descricao;
    }

    final id = item['id'] ?? item['id_defeito'] ?? item['id_reclamacao'];
    return id != null
        ? '${widget.tituloItem} #$id'
        : '${widget.tituloItem} sem título';
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blueColor,
        centerTitle: true,
        title: Text(
          widget.tituloTela,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _ocorrencias.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          widget.mensagemVazia,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregarOcorrencias,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _ocorrencias.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _ocorrencias[index];
                          final urgencia =
                              (item['urgencia'] ?? 'Não informada').toString();

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: Color.fromARGB(40, 0, 68, 170),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: blueColor,
                                ),
                              ),
                              title: Text(
                                _tituloOcorrencia(item),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Urgência: $urgencia',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalheOcorrenciaSindico(
                                      tituloTela:
                                          'Detalhes ${widget.tituloItem}',
                                      item: item,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class DetalheOcorrenciaSindico extends StatelessWidget {
  const DetalheOcorrenciaSindico({
    super.key,
    required this.tituloTela,
    required this.item,
  });

  final String tituloTela;
  final Map<String, dynamic> item;

  String _labelFromKey(String key) {
    final normalized = key.toLowerCase();
    if (normalized == 'nome_morador' || normalized == 'nomemorador') {
      return 'Nome do morador';
    }
    if (normalized == 'nome_condominio' || normalized == 'nomecondominio') {
      return 'Nome do condomínio';
    }

    final withSpaces = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();

    if (withSpaces.isEmpty) {
      return key;
    }

    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }

  bool _isDateKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('data') ||
        normalized.contains('date') ||
        normalized.contains('created_at') ||
        normalized.contains('updated_at');
  }

  bool _isIdKey(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'id' ||
        normalized.startsWith('id_') ||
        normalized.endsWith('_id') ||
        normalized.startsWith('id');
  }

  String _formatDateBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value.trim());
      return parsed;
    }

    return null;
  }

  String _valueToText(String key, dynamic value) {
    if (value == null) {
      return 'Não informado';
    }

    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }

    if (_isDateKey(key)) {
      final parsedDate = _tryParseDate(value);
      if (parsedDate != null) {
        return _formatDateBr(parsedDate);
      }
    }

    final text = value.toString().trim();
    return text.isEmpty ? 'Não informado' : text;
  }

  @override
  Widget build(BuildContext context) {
    const blueColor = Color.fromARGB(225, 0, 68, 170);

    final hasNomeMorador =
        (item['nome_morador']?.toString().trim().isNotEmpty ?? false) ||
            (item['nomeMorador']?.toString().trim().isNotEmpty ?? false);
    final hasNomeCondominio =
        (item['nome_condominio']?.toString().trim().isNotEmpty ?? false) ||
            (item['nomeCondominio']?.toString().trim().isNotEmpty ?? false);

    final entries = item.entries.where((entry) {
      final key = entry.key;

      if (_isIdKey(key)) {
        return false;
      }

      if (hasNomeMorador &&
          (key == 'id_morador' ||
              key == 'idMorador' ||
              key == 'morador_id' ||
              key == 'moradorId')) {
        return false;
      }

      if (hasNomeCondominio &&
          (key == 'id_condominio' ||
              key == 'idCondominio' ||
              key == 'condominio_id' ||
              key == 'condominioId')) {
        return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blueColor,
        centerTitle: true,
        title: Text(
          tituloTela,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in entries)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelFromKey(entry.key),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: blueColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _valueToText(entry.key, entry.value),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
