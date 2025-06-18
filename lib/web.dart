import 'dart:convert';
import 'dart:html' as html;
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

    final uri = Uri.parse('https://api.cloudconvert.com/v2/import/base64');
    final apiKey = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiZjQ0ZjhkNmEzNmIzYjdiYWE0MmY5NDEwMzA1OTVlYzFkMjg4YzNmMTBmNDc1MDU1NzhlMTZhMDk3NmQ0ZjJlN2YxZjE4ZjkxNzhmNzIyOTgiLCJpYXQiOjE3NTAyMzY5NTUuOTY1MTA5LCJuYmYiOjE3NTAyMzY5NTUuOTY1MTEsImV4cCI6NDkwNTkxMDU1NS45NTk3NzIsInN1YiI6IjcyMjM0ODM3Iiwic2NvcGVzIjpbInVzZXIucmVhZCIsInVzZXIud3JpdGUiLCJ0YXNrLnJlYWQiLCJ0YXNrLndyaXRlIiwid2ViaG9vay5yZWFkIiwid2ViaG9vay53cml0ZSIsInByZXNldC5yZWFkIiwicHJlc2V0LndyaXRlIl19.kXvWcod1CXgfhjl7ThLTORW7DQXMk_6lTkpMetb8ktkjlLue48G-v7RNxFaZ83iHze1GprSGcdNaVnHAKsu9bfVnSgb7wCdI9yPbAnR93hdjfaE7CRsIMcgi0-6-zx7Yy15bdOD0QwgS8Dfn8XKFU3U6KqewoukST2-MgTeD199L1CCHYiusjkfOTTIj5CDhK35FMKc_l1pKYcMtCUo0nNz7fTC5qPlKwAKTFBCy8SYpGdqq9F-XRek7vcGxuFAnpnBgbGPyDgMJmHgRpZrkBJHYQrlBJMtIZ4y9KRzerIWeeZMUyd5Ar58kt0qxxv16l-mRPZSUbO6T86jXpq7_vkobF8cYDe1-FmETDXDEuQlHerUmwkldONK-muxpaBQkNdP52z4ncHd-JDVX6dXepJBW6Ivd1dHY56O6-YPcGX74xeikEcXjCCvOmwBhYbm5i-UlnaGYWzZSZHKF6UbpQhyB9IBujlUqvEbRDS0amBFUbCcxbG8A-MjNh9zhwmmFjW9ck1lNm1hmkmHSmvElmC_CI-mB4dz_sGwE4dAvdpjLZyibI79dmOIzDdRXxK0Y6eNUPDF2LTaT9Sfnema-RFX9zrC_y6_CXmSYXKGOh4NMbDXWx_Zl18E5U7eEkqCIrIl80ujmKm2lT4NcPMAWX8MK-7r5wL8rXnsdjfZaiZI'; // Replace here

    // Step 1: Upload file
    final base64 = base64Encode(fileBytes);
    final uploadResponse = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'file': base64,
        'filename': fileName,
      }),
    );

    final uploadData = jsonDecode(uploadResponse.body);
    final uploadTaskId = uploadData['data']['id'];

    // Step 2: Create convert task
    final convertResponse = await http.post(
      Uri.parse('https://api.cloudconvert.com/v2/jobs'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tasks': {
          'import-my-file': {
            'operation': 'import/base64',
            'file': base64,
            'filename': fileName
          },
          'convert-my-file': {
            'operation': 'convert',
            'input': 'import-my-file',
            'input_format': 'heic',
            'output_format': 'png'
          },
          'export-my-file': {
            'operation': 'export/url',
            'input': 'convert-my-file',
            'inline': true,
            'archive_multiple_files': false
          }
        }
      }),
    );

    final jobData = jsonDecode(convertResponse.body);
    final exportUrl = jobData['data']['tasks']
        .firstWhere((t) => t['name'] == 'export-my-file')['result']['files'][0]['url'];

    // Step 3: Download result
    html.AnchorElement(href: exportUrl)
      ..setAttribute('download', fileName.replaceAll('.heic', '.png'))
      ..click();

    setState(() {
      _status = 'Done! PNG downloaded.';
    });
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
