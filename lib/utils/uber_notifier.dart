import 'dart:async';

import 'package:condotop/utils/api.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Serviço global para monitorar solicitações de Uber
/// e exibir um pop-up quando a entrada for autorizada,
/// em qualquer lugar do app.
class UberNotifier {
  UberNotifier._internal();
  static final UberNotifier instance = UberNotifier._internal();

  final ApiService _apiService = ApiService();
  final SessionService _sessionService = SessionService();

  Timer? _timer;
  bool _isChecking = false;

  Map<String, dynamic>? _ultimaSolicitacaoUber;

  /// Inicia o polling global.
  void start() {
    // Já está rodando
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkUber();
    });
  }

  /// Para o polling global.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool _isAutorizado(Map<String, dynamic> solicitacao) {
    final entradaOk = solicitacao['entrada_ok'];
    return entradaOk == 1 || entradaOk == true;
  }

  Future<void> _checkUber() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final idMorador = _sessionService.getIdMorador();
      if (idMorador == null) {
        _isChecking = false;
        return;
      }

      Response? response;

      // Tentar diferentes endpoints possíveis (mesma lógica da tela)
      try {
        response = await _apiService.get('/acessos', query: {
          'id_morador': idMorador,
        });
      } catch (_) {
        try {
          response = await _apiService.get('/acessos');
        } catch (_) {
          try {
            response = await _apiService.get('/acessos/morador/$idMorador');
          } catch (_) {
            // Se nada funcionar, apenas sair
          }
        }
      }

      if (response == null ||
          response.statusCode != 200 ||
          response.data == null) {
        _isChecking = false;
        return;
      }

      List<dynamic> solicitacoes = [];

      if (response.data is List) {
        solicitacoes = response.data as List;
      } else if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['data'] is List) {
          solicitacoes = data['data'] as List;
        } else if (data['acessos'] is List) {
          solicitacoes = data['acessos'] as List;
        }
      }

      Map<String, dynamic>? solicitacaoUber;

      for (var solicitacao in solicitacoes) {
        try {
          final sol = solicitacao as Map<String, dynamic>;
          final tipoServico =
              sol['tipo_servico']?.toString().toLowerCase() ?? '';
          final solIdMorador = sol['id_morador'] ?? sol['idMorador'];
          final cancelado = sol['cancelado'];

          if (tipoServico == 'uber' &&
              solIdMorador == idMorador &&
              (cancelado == null || cancelado == false || cancelado == 0)) {
            solicitacaoUber = sol;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      if (solicitacaoUber == null) {
        _isChecking = false;
        return;
      }

      final autorizadoAgora = _isAutorizado(solicitacaoUber);
      final jaConhecida = _ultimaSolicitacaoUber != null &&
          (_ultimaSolicitacaoUber!['id'] ?? _ultimaSolicitacaoUber!['id_acesso']) ==
              (solicitacaoUber['id'] ?? solicitacaoUber['id_acesso']);
      final estavaAutorizadaAntes =
          jaConhecida && _isAutorizado(_ultimaSolicitacaoUber!);

      _ultimaSolicitacaoUber = solicitacaoUber;

      // Se acabou de ser autorizada (transição de não autorizado -> autorizado)
      if (autorizadoAgora && !estavaAutorizadaAntes) {
        _mostrarPopupAutorizadoGlobal(solicitacaoUber);
      }
    } catch (_) {
      // Silenciar erros para não quebrar o app
    } finally {
      _isChecking = false;
    }
  }

  void _mostrarPopupAutorizadoGlobal(Map<String, dynamic> solicitacao) {
    final navigatorKey = ApiService.navigatorKey;
    final context = navigatorKey?.currentContext;
    if (context == null) return;

    final veiculo = solicitacao['veiculo']?.toString() ?? 'N/A';
    final placa = solicitacao['placa']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Uber autorizado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A portaria autorizou a entrada do seu Uber.',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.directions_car_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      veiculo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.confirmation_number_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Placa: $placa',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}


