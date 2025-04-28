import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            // color: Colors.red,
            height: MediaQuery.of(context).size.height * 0.43,
            child: Stack(
              children: [
                Container(
                  // margin: EdgeInsets.only(left: 12, right: 12),
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
                      fontSize: 28,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 175),
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
          Container(
            margin: EdgeInsets.only(left: 8, right: 8),
            // color: Colors.amber,
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.black,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(5),
                      border: InputBorder.none,
                      hintText: "Usuário",
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
                      hintText: "Senha",
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
                    "Entrar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "Cadastrar-se",
                  style: TextStyle(
                    color: Color.fromARGB(225, 0, 68, 170),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
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
