import 'package:condotop/components/card_dashboard.dart';
import 'package:flutter/material.dart';

import '../utils/api.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final api = ApiService();

  Future carregarDados() async {
    final resposta = await api.get("/acessos");
    print(resposta.data);
  }

  @override
  void initState() {
    // TODO: implement initState

    carregarDados();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 102, 1),
        centerTitle: true,
        title: Text(
          "Condotop",
          style: TextStyle(
              color: Color.fromARGB(255, 204, 204, 204),
              fontWeight: FontWeight.w600),
        ),
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
                      Icons.qr_code_2_outlined, "Autorizar\nvisitante"),
                  CardDashboard(Icons.deck_outlined, "Reserva de\nÁrea comum"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CardDashboard(Icons.handyman_outlined, "Informar\nDefeito"),
                  CardDashboard(Icons.comment_sharp, "Registrar\nReclamação"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CardDashboard(
                      Icons.emoji_transportation_outlined, "Autorizar\nUber"),
                  CardDashboard(
                      Icons.event_available_outlined, "Agendar\nMudança"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CardDashboard(Icons.settings_remote_outlined,
                      "Solicitar Tag\nou Controle"),
                  CardDashboard(Icons.folder_outlined, "Documentos\nGerais"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 100,
                    child: Card(
                      color: Color.fromARGB(255, 0, 68, 170),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.featured_play_list_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                            Text(
                              "Mural",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
