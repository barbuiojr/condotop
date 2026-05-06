import 'package:condotop/views/registro_ocorrencia_form.dart';
import 'package:flutter/material.dart';

class RegistrarDefeito extends StatelessWidget {
  const RegistrarDefeito({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegistroOcorrenciaForm(
      '/defeitos/',
      'Registrar Defeito',
      'data_defeito',
      'Defeito cadastrado com sucesso!',
      'Por favor, descreva o defeito',
      'Descreva o defeito encontrado...',
      'Erro ao registrar defeito. Tente novamente.',
    );
  }
}
