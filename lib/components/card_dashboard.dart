import 'package:flutter/material.dart';

class CardDashboard extends StatelessWidget {
  IconData icon;
  String text;
  CardDashboard(this.icon, this.text);  

  @override
  Widget build(BuildContext context) {
    return Container(
                  width: MediaQuery.of(context).size.width * 0.38,
                  height: MediaQuery.of(context).size.height * 0.18,
                  child: Card(
                    color: Color.fromARGB(255, 0, 68, 170),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(icon,
                            color: Colors.white,
                            size: 40,
                            ),
                          Text(text,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,),
                        ],
                      ),
                    ),
                  ),
                );
  }
}