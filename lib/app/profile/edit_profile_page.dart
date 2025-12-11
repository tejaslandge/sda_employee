// lib/app/profile/edit_profile_page.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_constants.dart';

class EditProfilePage extends StatefulWidget {
  final int id;
  final String name;
  final String mobile;
  final String? city;
  final String? state;
  final String? profileImage;

  const EditProfilePage({
    super.key,
    required this.id,
    required this.name,
    required this.mobile,
    this.city,
    this.state,
    this.profileImage,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameCtrl;
  late TextEditingController mobileCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;

  File? newImage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.name);
    mobileCtrl = TextEditingController(text: widget.mobile);
    cityCtrl = TextEditingController(text: widget.city ?? '');
    stateCtrl = TextEditingController(text: widget.state ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    super.dispose();
  }

  String _fixUrl(String? img) {
    if (img == null || img.trim().isEmpty) return '';
    var s = img.replaceAll('\\', '/');
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) s = s.substring(1);
    return '${ApiConstants.fileURL}/$s';
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => newImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('pickImage error: $e');
    }
  }

  Future<bool> _uploadProfile(Map<String, String> fields, File? image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final request = http.MultipartRequest('POST', Uri.parse(ApiConstants.updateProfile));
      if (token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(fields);

      if (image != null) {
        final multipartFile = await http.MultipartFile.fromPath('profile', image.path);
        request.files.add(multipartFile);
      }

      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();

      try {
        final Map<String, dynamic> js = jsonDecode(respStr);
        return js['status'] == true;
      } catch (e) {
        debugPrint('EditProfile: non-json response: $respStr');
        return false;
      }
    } catch (e) {
      debugPrint('uploadProfile error: $e');
      return false;
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);

    final fields = {
      'name': nameCtrl.text.trim(),
      'city': cityCtrl.text.trim(),
      'state': stateCtrl.text.trim(),
      // 'id' not required by sanctum backend (user comes from token), but keep if backend expects it:
      'id': widget.id.toString(),
    };

    final ok = await _uploadProfile(fields, newImage);
    setState(() => saving = false);

    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('employeeName', fields['name'] ?? '');
      await prefs.setString('employeeCity', fields['city'] ?? '');
      await prefs.setString('employeeState', fields['state'] ?? '');
      if (newImage != null) await prefs.setString('employeeProfile', newImage!.path);

      if (!mounted) return;
      Navigator.pop(context, {
        'id': widget.id,
        'name': fields['name'],
        'mobile': widget.mobile,
        'city': fields['city'],
        'state': fields['state'],
        'profile': newImage != null ? newImage!.path : (widget.profileImage ?? ''),
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xff4f46e5);
    final corrected = _fixUrl(widget.profileImage);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(backgroundColor: primary, centerTitle: true, elevation: 0, title: const Text('Edit Profile', style: TextStyle(color: Colors.white))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Hero(
              tag: 'profile_pic',
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: newImage != null ? FileImage(newImage!) : (corrected.isNotEmpty ? NetworkImage(corrected) as ImageProvider : null),
                    child: newImage == null && corrected.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: primary, shape: BoxShape.circle), child: const Icon(Icons.edit, color: Colors.white, size: 20)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 26),
            _buildField('Name', nameCtrl, Icons.person),
            const SizedBox(height: 12),
            _buildField('Mobile', mobileCtrl, Icons.phone_android, enabled: false),
            const SizedBox(height: 12),
            _buildField('City', cityCtrl, Icons.location_city),
            const SizedBox(height: 12),
            _buildField('State', stateCtrl, Icons.map),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: saving ? null : _save,
                child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool enabled = true}) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff4f46e5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
