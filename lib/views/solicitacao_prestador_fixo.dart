import 'package:condotop/views/solicitacao_uber.dart';
import 'package:flutter/material.dart';

class SolicitacaoPrestadorFixo extends StatelessWidget {
  const SolicitacaoPrestadorFixo({super.key});

  @override
  Widget build(BuildContext context) {
    return const SolicitacaoUber(
      nomeServico: 'Prestador',
      tipoServico: 'Prestador',
      tituloTela: 'Autorizar Prestador',
    );
  }
}
