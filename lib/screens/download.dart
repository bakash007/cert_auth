import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class Download extends StatefulWidget {
  Download({super.key});

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController blockController = TextEditingController();
  String? selectedBlock;
  String verificationMessage = "";
  bool isVerified = false;
  List<String> blocks = [];

  @override
  void initState() {
    super.initState();
    loadBlocks();
  }

  Future<void> loadBlocks() async {
    try {
      String jsonString = await rootBundle.loadString('blockchain_final.json');
      List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        blocks = jsonData.map<String>((block) => block['blockName'] as String).toList();
      });
    } catch (e) {
      setState(() {
        verificationMessage = "Error loading block list!";
      });
    }
  }

  Future<void> verifyDetails() async {
    if (rollNoController.text.isEmpty || selectedBlock == null) {
      setState(() {
        verificationMessage = "Please fill all fields";
        isVerified = false;
      });
      return;
    }

    try {
      String jsonString = await rootBundle.loadString('blockchain_final.json');
      List<dynamic> jsonData = json.decode(jsonString);
      bool found = false;

      for (var block in jsonData) {
        if (block['blockName'] == selectedBlock) {
          for (var file in block['files']) {
            if (file['rollNumber'] == rollNoController.text) {
              setState(() {
                isVerified = true;
                verificationMessage = "✅ Verified and Downloaded!.";
              });
              found = true;
              break;
            }
          }
        }
        if (found) break;
      }

      if (!found) {
        setState(() {
          isVerified = false;
          verificationMessage = "❌ Verification failed!";
        });
      }
    } catch (e) {
      setState(() {
        verificationMessage = "Error loading JSON!";
        isVerified = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Download Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.teal.shade400,
          centerTitle: true,
          elevation: 5.0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Welcome to Download Portal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                  SizedBox(height: 10),
                  Text("Provide the details to proceed", style: TextStyle(fontSize: 16, color: Colors.teal.shade700)),
                  SizedBox(height: 30),
                  
                  Card(
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                    shadowColor: Colors.teal.shade300,
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: blockController,
                            decoration: InputDecoration(
                              labelText: selectedBlock ?? "Select Block",
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.school, color: Colors.teal),
                              suffixIcon: PopupMenuButton<String>(
                                icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
                                onSelected: (String value) {
                                  setState(() {
                                    selectedBlock = value;
                                    blockController.text = value;
                                  });
                                },
                                itemBuilder: (BuildContext context) {
                                  return blocks.map((String block) {
                                    return PopupMenuItem<String>(
                                      value: block,
                                      child: Text(block),
                                    );
                                  }).toList();
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                              filled: true,
                              fillColor: Colors.teal.shade50,
                            ),
                            readOnly: true,
                          ),
                          SizedBox(height: 20),
                          
                          TextField(
                            controller: rollNoController,
                            decoration: InputDecoration(
                              labelText: "Roll Number",
                              labelStyle: TextStyle(color: Colors.teal.shade600),
                              prefixIcon: Icon(Icons.format_list_numbered, color: Colors.teal),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                              filled: true,
                              fillColor: Colors.teal.shade50,
                            ),
                          ),
                          SizedBox(height: 30),
                          
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade400,
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                              elevation: 8,
                            ),
                            onPressed: verifyDetails,
                            child: Text("VERIFY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          
                          SizedBox(height: 20),
                          if (verificationMessage.isNotEmpty)
                            Text(
                              verificationMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isVerified ? Colors.green : Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(Download());
}
