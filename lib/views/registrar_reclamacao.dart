import 'package:condotop/views/registro_ocorrencia_form.dart';
import 'package:flutter/material.dart';

class RegistrarReclamacao extends StatelessWidget {
  const RegistrarReclamacao({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistroOcorrenciaForm(
      endpoint: '/reclamacoes/',
      tituloTela: 'Registrar Reclamação',
      dataField: 'data_reclamacao',
      successMessage: 'Reclamação cadastrada com sucesso!',
      descricaoValidatorMessage: 'Por favor, descreva o motivo da reclamação',
      descricaoHint: 'Descreva o que aconteceu...',
      errorFallbackMessage: 'Erro ao registrar reclamação. Tente novamente.',
    );
  }
}
