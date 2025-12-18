import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadAdPage extends StatefulWidget {
  final int clientId;

  const UploadAdPage({super.key, required this.clientId});

  @override
  State<UploadAdPage> createState() => _UploadAdPageState();
}

class _UploadAdPageState extends State<UploadAdPage> {
  File? image;

  Future<void> pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => image = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Ad")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
                child: image == null
                    ? const Icon(Icons.add_a_photo, size: 50)
                    : Image.file(image!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: image == null ? null : () {},
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
