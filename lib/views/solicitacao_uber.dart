import 'package:flutter/material.dart';

class SolicitacaoUber extends StatefulWidget {
  const SolicitacaoUber({super.key});

  @override
  State<SolicitacaoUber> createState() => _SolicitacaoUberState();
}

class _SolicitacaoUberState extends State<SolicitacaoUber> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // container top
          Container(
            // color: Colors.red,
            // height: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: 60),
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.2,
                  color: Color.fromARGB(225, 0, 68, 170),
                  child: Image.asset(
                    'assets/logo/logo_condotop.png',
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.10,
                  color: Color.fromARGB(225, 0, 68, 170),
                  child: Text(
                    "Morador",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Uber",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.black,
                      ),
                    ),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Veículo",
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.black,
                      ),
                    ),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(5),
                        hintText: "Placa",
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    alignment: Alignment.center,
                    height: 50,
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 102, 1),
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      "Autorizar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Container amarelo
              Container(
                // color: Colors.amber,
                alignment: Alignment.bottomCenter,
                // height: MediaQuery.of(context).size.height * 0.4,
                child: Stack(
                  children: [
                    // Container Laranja
                    Container(
                      // margin: EdgeInsets.only(left: 12, right: 12),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 102, 1),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      width: double.maxFinite,
                      height: MediaQuery.of(context).size.height * 0.15,
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 58),
                child: Image.asset(
                  "assets/logo/logo_ss.png",
                  height: 120,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
