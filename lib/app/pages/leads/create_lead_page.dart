import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';

class CreateLeadPage extends StatefulWidget {
  const CreateLeadPage({super.key});

  @override
  State<CreateLeadPage> createState() => _CreateLeadPageState();
}

class _CreateLeadPageState extends State<CreateLeadPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final orgCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  String leadType = "Display";
  DateTime? followUpDate;
  final DateTime contactDate = DateTime.now();

  File? visitingCard;
  bool saving = false;

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => visitingCard = File(img.path));
    }
  }

  // ================= SAVE LEAD =================
  Future<void> saveLead() async {
    if (!_formKey.currentState!.validate()) return;
    if (saving) return;

    setState(() => saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      final req = http.MultipartRequest(
        "POST",
        Uri.parse(ApiConstants.leadsCreate),
      );
      req.headers.addAll(ApiConstants.authHeaders(token));

      req.fields.addAll({
        "name": nameCtrl.text.trim(),
        "org_name": orgCtrl.text.trim(),
        "mobile": "+91${mobileCtrl.text.trim()}",
        "email": emailCtrl.text.trim(),
        "lead_type": leadType,
        "description": descCtrl.text.trim(),
        "contact_date": contactDate.toString().split(" ").first,
        "status": "pending",
      });

      if (followUpDate != null) {
        req.fields["follow_up_date"] = followUpDate!
            .toString()
            .split(" ")
            .first;
      }

      if (visitingCard != null) {
        req.files.add(
          await http.MultipartFile.fromPath(
            "visiting_card",
            visitingCard!.path,
          ),
        );
      }

      final res = await req.send();

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context);
      } else {
        _toast("Failed to save lead");
      }
    } catch (e) {
      _toast("Something went wrong");
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(title: const Text("Create Lead")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _section("Basic Details", [
                _textField("Lead Name", nameCtrl, validator: _required),
                _textField("Organization", orgCtrl, validator: _required),
                _mobileField(),
                _textField(
                  "Email (optional)",
                  emailCtrl,
                  keyboard: TextInputType.emailAddress,
                ),
              ]),
              const SizedBox(height: 16),
              _section("Lead Info", [
                DropdownButtonFormField<String>(
                  value: leadType,
                  decoration: _decoration("Lead Type"),
                  items:
                      const [
                            "Display",
                            "Ads",
                            "Referral",
                            "Cold Call",
                            "Website",
                            "Other",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => leadType = v!),
                ),
                const SizedBox(height: 14),
                _dateTile(
                  "Contact Date",
                  contactDate.toString().split(" ").first,
                  auto: true,
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickFollowUpDate,
                  child: _dateTile(
                    "Follow-Up Date",
                    followUpDate == null
                        ? "Select"
                        : followUpDate!.toString().split(" ").first,
                  ),
                ),
                const SizedBox(height: 14),
                _textField("Description (optional)", descCtrl, maxLines: 3),
              ]),
              const SizedBox(height: 16),
              _section("Visiting Card", [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload"),
                    ),
                    const SizedBox(width: 12),
                    visitingCard == null
                        ? const Text("No image selected")
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              visitingCard!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ],
                ),
              ]),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveLead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Save Lead",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _textField(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
        decoration: _decoration(label),
      ),
    );
  }

  Widget _mobileField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: mobileCtrl,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: _decoration(
          "Mobile Number",
        ).copyWith(prefixText: "+91 ", counterText: ""),
        validator: (v) {
          if (v == null || v.isEmpty) return "Mobile number required";
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
            return "Enter valid 10-digit Indian number";
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _dateTile(String label, String value, {bool auto = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month),
            const SizedBox(width: 12),
            Expanded(child: Text("$label: $value")),
            if (auto)
              const Text("(auto)", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  void _pickFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => followUpDate = picked);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? "This field is required" : null;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
