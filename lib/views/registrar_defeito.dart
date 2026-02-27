import 'package:condotop/views/registrar_reclamacao.dart';
import 'package:flutter/material.dart';

class RegistrarDefeito extends StatelessWidget {
  const RegistrarDefeito({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistrarReclamacao(
      endpoint: '/defeitos/',
      tituloTela: 'Registrar Defeito',
      dataField: 'data_defeito',
      successMessage: 'Defeito cadastrado com sucesso!',
      descricaoValidatorMessage: 'Por favor, descreva o defeito',
      descricaoHint: 'Descreva o defeito encontrado...',
      errorFallbackMessage: 'Erro ao registrar defeito. Tente novamente.',
    );
  }
}
