import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async';


class UUpload extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFE16A54),
        colorScheme: ColorScheme.light(
          secondary: Color(0xFFE16A54),
        ),
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      home: FileUploadPage(),
    );
  }
}

class FileUploadPage extends StatefulWidget {
  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  List<Map<String, dynamic>> uploadedFiles = [];
  TextEditingController blockController = TextEditingController();
  bool isLoading = false; // New state variable

  Future<void> pickBulkFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        uploadedFiles = result.files.map((file) {
          return {
            'fileName': file.name,
            'studentName': '', // Editable field
            'rollNumber': '', // Editable field
            'dateTime': DateTime.now().toIso8601String(), // Capture timestamp
          };
        }).toList();
      });
    }
  }

void createBlock() async {
  String blockName = blockController.text.trim();
  if (blockName.isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Please enter a Block Name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  setState(() {
    isLoading = true; // Show loading bar
  });

  Map<String, dynamic> finalData = {
    'blockName': blockName,
    'files': uploadedFiles.map((file) {
      return {
        'fileName': file['fileName'],
        'studentName': file['studentName'],
        'rollNumber': file['rollNumber'],
        'dateTime': file['dateTime'],
      };
    }).toList(),
  };
 // **Formatted JSON**
    String jsonData = JsonEncoder.withIndent('  ').convert(finalData);

    // Convert to Blob & Download
    final blob = html.Blob([jsonData], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "selected_files.json")
      ..click();
    html.Url.revokeObjectUrl(url);


  try {
    // **Send JSON to Go Backend**
    String apiUrl = "http://localhost:8080/create-block";
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(finalData),
    );

    // Simulate loading for 5-7 seconds
    await Future.delayed(Duration(seconds: 5 + (DateTime.now().millisecondsSinceEpoch % 3)));

    if (response.statusCode == 200) {
       // Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Block "$blockName" has been processed successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
    } else {
      throw Exception("Failed to process block");
    }
  } catch (e) {
    print("Error: $e");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to process block. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } finally {
    setState(() {
      isLoading = false; // Hide loading bar after process finishes
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Upload & Block Creation'),
        centerTitle: true,
        backgroundColor: Color(0xFFE16A54),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: pickBulkFiles,
                      icon: Icon(Icons.upload_file),
                      label: Text('Bulk Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE16A54),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Display selected files
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: uploadedFiles.length,
                itemBuilder: (context, index) {
                  final file = uploadedFiles[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('File Name: ${file['fileName']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text('Date & Time: ${file['dateTime']}'),
                          SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(labelText: 'Student Name'),
                            onChanged: (value) {
                              uploadedFiles[index]['studentName'] = value;
                            },
                          ),
                          SizedBox(height: 10),
                          TextField(
                            decoration: InputDecoration(labelText: 'Roll Number'),
                            onChanged: (value) {
                              uploadedFiles[index]['rollNumber'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Block Name Input
              TextField(
                controller: blockController,
                decoration: InputDecoration(
                  labelText: 'Enter Block Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                ),
              ),
              SizedBox(height: 20),

              // **Loading Indicator**
              if (isLoading) LinearProgressIndicator(),

              SizedBox(height: 10),

              // Create Block Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : createBlock,
                  icon: Icon(Icons.lock_open),
                  label: Text('Create Block'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE16A54),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
