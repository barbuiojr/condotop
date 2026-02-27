import 'package:condotop/views/autorizacao_veiculo_form.dart';
import 'package:flutter/material.dart';

class SolicitacaoPrestador extends StatelessWidget {
  const SolicitacaoPrestador({super.key});

  @override
  Widget build(BuildContext context) {
    return const AutorizacaoVeiculoForm(
      nomeServico: 'Prestador',
      tipoServico: 'Prestador',
      tituloTela: 'Solicitar Prestador',
    );
  }
}
