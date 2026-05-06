import 'package:condotop/views/registro_ocorrencia_form.dart';
import 'package:flutter/material.dart';

class RegistrarReclamacao extends StatelessWidget {
  const RegistrarReclamacao({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistroOcorrenciaForm(
      '/reclamacoes/',
      'Registrar Reclamação',
      'data_reclamacao',
      'Reclamação cadastrada com sucesso!',
      'Por favor, descreva o motivo da reclamação',
      'Descreva o que aconteceu...',
      'Erro ao registrar reclamação. Tente novamente.',
    );
  }
}
