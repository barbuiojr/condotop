import 'package:condotop/views/login.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            // color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 12, right: 12),
                  padding: const EdgeInsets.only(top: 80),
                  alignment: Alignment.topCenter,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    // a partir do momento que eu uso BoxDecoration o atributo color nao pode mais ficar diretamente no container
                    color: Color.fromARGB(225, 0, 68, 170),
                  ),
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.maxFinite,
                  child: Text(
                    "Bem Vindo ao",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28
                      ,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 200),
                  width: double.maxFinite,
                  // color: Colors.red,
                  child: Image.asset(
                    "assets/logo/logo_condotop.png",
                    height: 200,
                  ),
                )
              ],
            ),
          ),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Container amarelo
              Container(
                // color: Colors.amber,
                alignment: Alignment.bottomCenter,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Stack(
                  children: [
                    // Container Laranja
                    Container(
                      margin: EdgeInsets.only(left: 12, right: 12),
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
