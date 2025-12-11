import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({super.key});

  @override
  State<EmployeeLoginPage> createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final Color primary = const Color(0xff4f46e5);
  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final phone = phoneController.text.trim();
    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _msg("Enter valid 10-digit number");
      return;
    }

    setState(() => loading = true);
    try {
      final res = await http.post(Uri.parse(ApiConstants.requestOtp),
          headers: ApiConstants.jsonHeaders,
          body: jsonEncode({"mobile": phone}));
      final j = jsonDecode(res.body);
      if (res.statusCode == 200 && j["status"] == true) {
        _msg("OTP sent");
        Navigator.pushNamed(context, "/otp", arguments: phone);
      } else {
        _msg(j["message"] ?? "Failed to send OTP");
      }
    } catch (e) {
      _msg("Network error: $e");
    }
    if (mounted) setState(() => loading = false);
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 90, bottom: 40),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                    child: Image.asset("assets/icon/app_icon.png", fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 18),
                  const Text("Employee Login", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mobile Number", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: primary.withOpacity(.12), borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18))),
                          child: Text("+91", style: TextStyle(fontSize: 18, color: primary, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(hintText: "Enter mobile number", counterText: "", border: InputBorder.none, contentPadding: EdgeInsets.only(left: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),
                  GestureDetector(
                    onTap: loading ? null : _requestOtp,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: primary),
                      child: Center(child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Request OTP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
