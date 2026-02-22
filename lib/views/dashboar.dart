import 'package:condotop/components/card_dashboard.dart';
import 'package:condotop/utils/session_service.dart';
import 'package:condotop/views/autorizar_visitante.dart';
import 'package:condotop/views/documentos_gerais.dart';
import 'package:condotop/views/registrar_reclamacao.dart';
import 'package:condotop/views/reserva_area_comum.dart';
import 'package:condotop/views/solicitacao_uber.dart';
import 'package:condotop/views/validar_morador.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final SessionService _session = SessionService();

  @override
  Widget build(BuildContext context) {
    // Exemplo: Obter informações da sessão
    // final userName = _session.getUserName() ?? 'Usuário';
    // final userEmail = _session.getUserEmail();
    // final userId = _session.getUserId();
    final userTipo = _session.getUserTipo();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 102, 1),
        centerTitle: true,
        title: Text(
          "Condotop",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        // Exemplo: Adicionar ações no AppBar com informações da sessão
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentosGerais(),
                  ),
                );
              },
              icon: Icon(
                Icons.person_outline,
                color: Colors.white,
              )),
          // Você pode adicionar um ícone de perfil ou menu aqui
          // que mostra as informações do usuário
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CardDashboard(
                    Icons.qr_code_2_outlined,
                    "Autorizar\nvisitante",
                    AutorizarVisitante(),
                  ),
                  CardDashboard(
                    Icons.emoji_transportation_outlined,
                    "Autorizar\nUber",
                    SolicitacaoUber(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CardDashboard(
                    Icons.deck_outlined,
                    "Reserva de\nÁrea comum",
                    const ReservaAreaComum(),
                  ),
                  CardDashboard(
                    Icons.comment_sharp,
                    "Registrar\nReclamação",
                    RegistrarReclamacao(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  userTipo == "S"
                      ? CardDashboard(
                          Icons.person_outline,
                          "Validar\nMorador",
                          const ValidarMorador(),
                        )
                      : Container(),
                ],
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceAround,
              //   children: [
              //     CardDashboard(
              //       Icons.event_available_outlined,
              //       "Agendar\nMudança",
              //       AgendarMudanca(),
              //     ),
              //     CardDashboard(
              //       Icons.handyman_outlined,
              //       "Informar\nDefeito",
              //       InformarDefeito(),
              //     ),
              //   ],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceAround,
              //   children: [
              //     CardDashboard(
              //       Icons.settings_remote_outlined,
              //       "Solicitar Tag\nou Controle",
              //       SolicitarTagControle(),
              //     ),
              //     CardDashboard(
              //       Icons.folder_outlined,
              //       "Documentos\nGerais",
              //       DocumentosGerais(),
              //     ),
              //   ],
              // ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Container(
              //       width: MediaQuery.of(context).size.width * 0.85,
              //       height: 100,
              //       child: Card(
              //         color: Color.fromARGB(255, 0, 68, 170),
              //         child: Padding(
              //           padding: const EdgeInsets.only(top: 12, bottom: 12),
              //           child: Column(
              //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //             crossAxisAlignment: CrossAxisAlignment.center,
              //             children: [
              //               Icon(
              //                 Icons.featured_play_list_outlined,
              //                 color: Colors.white,
              //                 size: 40,
              //               ),
              //               Text(
              //                 "Mural",
              //                 style: TextStyle(
              //                   color: Colors.white,
              //                   fontWeight: FontWeight.w500,
              //                 ),
              //                 textAlign: TextAlign.center,
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     )
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
