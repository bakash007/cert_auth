import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SViewall extends StatefulWidget {
  const SViewall({super.key});

  @override
  State<SViewall> createState() => _ViewallState();
}

class _ViewallState extends State<SViewall> {
  List<Map<String, dynamic>> students = [];

  Future<void> fetchStudentData() async {
    try {
      String data = await rootBundle.loadString('assets/updated_file_uploads.json');
      List jsonData = json.decode(data);
      setState(() {
        students = List<Map<String, dynamic>>.from(jsonData);
      });
    } catch (exception) {
      print("Error loading JSON: $exception");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("JSON Data View")),
      body: students.isEmpty
          ? Center(child: CircularProgressIndicator()) // Show loader
          : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  elevation: 10,
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    title: Text("BLOCKNAME"),
                    subtitle: Text(
                      "${student["name"] ?? "Unknown"}\n"
                      "${student["roll_no"] ?? "No Purpose"}\n"
                      "${student["file_name"] ?? "Not Specified"}"
		      "${student["hash"] ?? "Not Specified"}"
		      "${student["encrypted_cid"] ?? "Not Specified"}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
