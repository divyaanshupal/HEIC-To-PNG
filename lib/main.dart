import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEIC to PNG Converter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String status = 'Select one or more .heic files to convert';

  Future<void> convertHeicToPng() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['heic'],
      allowMultiple: true, // ✅ Multiple file selection
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => status = 'Converting ${result.files.length} file(s)...');

    int successCount = 0;
    int failCount = 0;

    for (final file in result.files) {
      final inputPath = file.path!;
      final fileNameWithoutExt = p.basenameWithoutExtension(inputPath);
      final outputDir = p.dirname(inputPath);
      final outputPath = p.join(outputDir, '$fileNameWithoutExt.png');

      try {
        final process = await Process.run('magick', [inputPath, outputPath]);

        if (process.exitCode == 0) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    setState(() {
      status = '✅ $successCount file(s) converted successfully.\n'
               '${failCount > 0 ? '❌ $failCount file(s) failed.' : ''}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HEIC to PNG Converter')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: convertHeicToPng,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Pick HEIC File(s)'),
              ),
              const SizedBox(height: 20),
              Text(
                status,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
