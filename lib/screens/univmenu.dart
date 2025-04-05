import 'package:flutter/material.dart';
import 'package:cverifier/screens/univupload.dart';
import 'package:cverifier/screens/viewblock.dart';


class SMenuSystem extends StatefulWidget {
  const SMenuSystem({super.key});

  @override
  State<SMenuSystem> createState() => _MenuSystemState();
}

class _MenuSystemState extends State<SMenuSystem> {
  final List<Widget> pages=[
    UUpload(),
    SViewall()
  ];
  int currentIndexValue=0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      body: pages[currentIndexValue],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndexValue,
        onTap: (index){
          setState(() {
            currentIndexValue=index;
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.upload_file),
              label: "UPLOAD"),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_comfortable_rounded),
              label: "ViEW BLOCKCHAIN")
        ],
      ),
    );
  }
}
