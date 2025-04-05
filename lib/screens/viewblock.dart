import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SViewall extends StatefulWidget {
  const SViewall({super.key});

  @override
  State<SViewall> createState() => _SViewallState();
}

class _SViewallState extends State<SViewall> {
  List<Map<String, dynamic>> blocks = [];

  Future<void> fetchBlockchainData() async {
    try {
      String data = await rootBundle.loadString('blockchain_final.json');
      List jsonData = json.decode(data);
      setState(() {
        blocks = List<Map<String, dynamic>>.from(jsonData);
      });
    } catch (exception) {
      print("Error loading JSON: $exception");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBlockchainData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Blockchain Data View")),
      body: blocks.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : ListView.builder(
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                var block = blocks[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ExpansionTile(
                    title: Text(
                      "Block: ${block["blockName"]}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text("Student Name")),
                            DataColumn(label: Text("Roll No")),
                            DataColumn(label: Text("File Name")),
                            DataColumn(label: Text("Date Time")),
                            DataColumn(label: Text("SHA256 Checksum")),
                            DataColumn(label: Text("Encrypted CID")),
                          ],
                          rows: (block["files"] as List).map((file) {
                            return DataRow(cells: [
                              DataCell(Text(file["studentName"] ?? "Unknown")),
                              DataCell(Text(file["rollNumber"] ?? "No Roll")),
                              DataCell(Text(file["fileName"] ?? "No File")),
                              DataCell(Text(file["dateTime"] ?? "No Date")),
                              DataCell(Text(file["sha256"] ?? "No Hash")),
                              DataCell(Text(file["encryptedCID"] ?? "No CID")),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
