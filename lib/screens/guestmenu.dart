
import 'package:flutter/material.dart';
import 'package:cverifier/screens/upload.dart';
import 'package:cverifier/screens/viewblock.dart';
import 'package:cverifier/screens/download.dart';

class GMenuSystem extends StatefulWidget {
  const GMenuSystem({super.key});

  @override
  State<GMenuSystem> createState() => _MenuSystemState();
}

class _MenuSystemState extends State<GMenuSystem> {
  final List<Widget> pages = [
    FileUploadApp(),
    SViewall(),
    Download(),
  ];

  int currentIndexValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: pages[currentIndexValue],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndexValue,
        onTap: (index) {
          setState(() {
            currentIndexValue = index;
          });
        },
        selectedItemColor: Colors.teal.shade600,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        selectedFontSize: 14.0,
        unselectedFontSize: 12.0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file, size: 28),
            label: "Upload & Verify",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_comfortable_rounded, size: 28),
            label: "View Blockchain",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download_for_offline, size: 28),
            label: "Download",
          ),
        ],
        backgroundColor: Color(0xFFF5EBE0),
        elevation: 12.0,
      ),


    );
  }
}



