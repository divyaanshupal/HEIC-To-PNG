import 'dart:convert';
import 'dart:html' as html;
import 'package:converter/api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HeicToPngWeb extends StatefulWidget {
  const HeicToPngWeb({super.key});

  @override
  State<HeicToPngWeb> createState() => _HeicToPngWebState();
}

class _HeicToPngWebState extends State<HeicToPngWeb> {
  String? _status = 'Select a .HEIC file to convert';

  Future<void> pickAndConvert() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['heic'],
  );

  if (result == null || result.files.isEmpty) return;

  final fileBytes = result.files.single.bytes!;
  final fileName = result.files.single.name;

  setState(() {
    _status = 'Uploading and converting...';
  });

  final apiKey = secrets.apiKey; // Replace with your actual key
  final base64 = base64Encode(fileBytes);

  try {
    // Step 1: Create Job
    final jobResponse = await http.post(
      Uri.parse('https://api.cloudconvert.com/v2/jobs'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tasks': {
          'import-1': {
            'operation': 'import/base64',
            'file': base64,
            'filename': fileName,
          },
          'convert-1': {
            'operation': 'convert',
            'input': 'import-1',
            'input_format': 'heic',
            'output_format': 'png',
          },
          'export-1': {
            'operation': 'export/url',
            'input': 'convert-1',
            'inline': true,
            'archive_multiple_files': false,
          }
        }
      }),
    );

    if (jobResponse.statusCode != 201) {
      throw Exception('Job creation failed: ${jobResponse.body}');
    }

    final jobData = jsonDecode(jobResponse.body);
    final jobId = jobData['data']['id'];

    // Step 2: Poll job status until it's finished
    Map<String, dynamic>? exportTask;
    while (true) {
      final statusResponse = await http.get(
        Uri.parse('https://api.cloudconvert.com/v2/jobs/$jobId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      final jobStatusData = jsonDecode(statusResponse.body);
      final tasks = jobStatusData['data']['tasks'] as List;

      exportTask = tasks.firstWhere(
        (task) => task['name'] == 'export-1',
        orElse: () => null,
      );

      if (exportTask != null && exportTask['status'] == 'finished') {
        break;
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    final fileUrl = exportTask['result']['files'][0]['url'];

    html.AnchorElement(href: fileUrl)
      ..setAttribute('download', fileName.replaceAll('.heic', '.png'))
      ..click();

    setState(() {
      _status = 'Done! PNG downloaded.';
    });
  } catch (e) {
    setState(() {
      _status = 'Conversion failed: $e';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HEIC to PNG Converter (Web)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickAndConvert,
              child: const Text('Select HEIC and Convert'),
            ),
          ],
        ),
      ),
    );
  }
}
