import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

class FileUploadApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FileUploadScreen(),
    );
  }
}

class FileUploadScreen extends StatefulWidget {
  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  String? fileName;
  Uint8List? fileBytes;
  DateTime? uploadDate;
  bool isFileVerified = false;
  String verificationMessage = "";

  Future<String> calculateSha256(Uint8List fileBytes) async {
    final digest = sha256.convert(fileBytes);
    return digest.toString();
  }

  Future<void> verifyFile() async {
    if (fileBytes == null) {
      setState(() {
        verificationMessage = "No file selected!";
      });
      return;
    }

    try {
      String fileHash = await calculateSha256(fileBytes!);
      String jsonString = await rootBundle.loadString('blockchain_final.json');
      List<dynamic> jsonData = json.decode(jsonString);

      bool found = false;

      for (var block in jsonData) {
        for (var file in block['files']) {
          if (file['sha256'] == fileHash) {
            setState(() {
              isFileVerified = true;
              verificationMessage = "✅ File Verified\nCollege: ${block['blockName']}\nStudent: ${file['studentName']}\nRoll No: ${file['rollNumber']}\nDate&Time: ${file['dateTime']}";
            });
            found = true;
            break;
          }
        }
        if (found) break;
      }

      if (!found) {
        setState(() {
          isFileVerified = false;
          verificationMessage = "❌ File NOT Verified";
        });
      }
    } catch (e) {
      setState(() {
        verificationMessage = "Error loading JSON!";
      });
    }
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        fileName = result.files.single.name;
        fileBytes = result.files.single.bytes;
        uploadDate = DateTime.now();
        isFileVerified = false;
        verificationMessage = "File Selected: $fileName";
      });
    } else {
      setState(() {
        fileName = null;
        fileBytes = null;
        uploadDate = null;
        isFileVerified = false;
        verificationMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload & Verify File",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF4B5D16),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 5.0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4B5D16).withOpacity(0.1),
              Color(0xFF4B5D16).withOpacity(0.3)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "Select a File to Upload",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B5D16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Choose a file from your device to proceed with the verification.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4B5D16),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          child: const Text(
                            "UPLOAD FILE",
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
                const SizedBox(height: 20),

                if (fileName != null || uploadDate != null)
                  Card(
                    elevation: 8.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fileName != null)
                            Text(
                              "File Name: $fileName",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          if (uploadDate != null)
                            Text(
                              "Upload Date: ${uploadDate?.toLocal().toString()}",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B5D16),
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            onPressed: verifyFile,
                            child: const Text(
                              "VERIFY FILE",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (verificationMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Center(
                                child: Text(
                                  verificationMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isFileVerified ? Colors.green : Colors.red,
                                  ),
                                ),
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
    );
  }
}

void main() => runApp(FileUploadApp());
