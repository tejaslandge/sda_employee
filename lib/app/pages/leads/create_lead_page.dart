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
  final name = TextEditingController();
  final org = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final remark = TextEditingController();

  String leadType = "Display";
  DateTime? followUpDate;
  final DateTime contactDate = DateTime.now(); // Always today's date

  File? visitingCard;

  // ---------------- PICK IMAGE ----------------
  pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => visitingCard = File(img.path));
    }
  }

  // ---------------- SAVE LEAD ----------------
  Future<void> saveLead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    /// 🚀 FIX: USE THE REAL ROUTE → /api/createlead
    var req = http.MultipartRequest("POST", Uri.parse(ApiConstants.leadsCreate));
    req.headers.addAll(ApiConstants.authHeaders(token));

    req.fields['name'] = name.text;
    req.fields['org_name'] = org.text;
    req.fields['mobile'] = mobile.text;
    req.fields['email'] = email.text;
    req.fields['lead_type'] = leadType;
    req.fields['remark'] = remark.text;

    if (followUpDate != null) {
      req.fields['follow_up_date'] = followUpDate.toString().split(" ").first;
    }

    req.fields['contact_date'] = contactDate.toString().split(" ").first;
    req.fields['status'] = 'pending';

    if (visitingCard != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          "visiting_card",
          visitingCard!.path,
        ),
      );
    }

    var res = await req.send();
    if (res.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  pickFollowUpDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => followUpDate = picked);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Lead"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              title: "Basic Details",
              children: [
                _inputField("Lead Name", name),
                _inputField("Organization Name", org),
                _inputField("Mobile Number", mobile,
                    keyboard: TextInputType.phone),
                _inputField("Email (optional)", email),
              ],
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: "Lead Information",
              children: [
                DropdownButtonFormField<String>(
                  value: leadType,
                  decoration: _inputDecoration("Lead Type"),
                  items: const [
                    "Display",
                    "Ads",
                    "Referral",
                    "Cold Call",
                    "Website",
                    "Other",
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => leadType = v!),
                ),
                const SizedBox(height: 14),

                _dateBox(
                  "Contact Date",
                  contactDate.toString().split(" ").first,
                  auto: true,
                ),
                const SizedBox(height: 14),

                InkWell(
                  onTap: pickFollowUpDate,
                  child: _dateBox(
                    "Follow-up Date",
                    followUpDate == null
                        ? "Select"
                        : followUpDate.toString().split(" ").first,
                  ),
                ),

                const SizedBox(height: 14),

                _inputField("Remark (optional)", remark, maxLines: 3),
              ],
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: "Visiting Card",
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload"),
                    ),
                    const SizedBox(width: 12),

                    visitingCard == null
                        ? const Text("No file selected")
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              visitingCard!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveLead,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Lead",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController c, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      children: [
        TextField(
          controller: c,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: _inputDecoration(label),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _dateBox(String title, String value, {bool auto = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Text("$title:  $value", style: const TextStyle(fontSize: 15)),
          if (auto)
            const Text("  (auto)", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
