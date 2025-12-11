// lib/login/otp_verification_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sms_autofill/sms_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> with CodeAutoFill {
  final Color primary = const Color(0xff4f46e5);
  String otp = "";
  bool loading = false;
  int seconds = 300;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    listenForCode();
    _startTimer();
  }

  @override
  void codeUpdated() {
    if (!mounted) return;
    final codeValue = code ?? "";
    if (codeValue.isNotEmpty) {
      setState(() => otp = codeValue);
      if (otp.length == 6) _verifyOtp();
    }
  }

  void _startTimer() {
    timer?.cancel();
    seconds = 300;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (seconds == 0) {
        t.cancel();
      } else {
        setState(() => seconds--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (otp.length != 6 || seconds == 0) return;
    if (loading) return;

    setState(() => loading = true);
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"mobile": widget.phoneNumber, "otp": otp}),
      );

      // Try decode safely
      Map<String, dynamic> j;
      try {
        j = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        _showMsg("Invalid server response");
        return;
      }

      if (res.statusCode == 200 && (j["status"] == true || j["status"] == 'true')) {
        final token = (j['token'] ?? "").toString();

        // Backend may return under "employee" or "user"
        final employee = (j['employee'] ?? j['user']) as Map<String, dynamic>? ?? {};

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('token', token);

        final idVal = employee['id'];
        final idInt = (idVal is int) ? idVal : int.tryParse(idVal?.toString() ?? '') ?? 0;
        await prefs.setInt('employeeId', idInt);
        await prefs.setString('employeeName', (employee['name'] ?? '').toString());
        await prefs.setString('employeeMobile', (employee['mobile'] ?? widget.phoneNumber).toString());
        await prefs.setString('employeeCity', (employee['city'] ?? '').toString());
        await prefs.setString('employeeState', (employee['state'] ?? '').toString());
        await prefs.setString('employeeProfile', (employee['profile'] ?? '').toString());

        // Prepare data map to send to dashboard
        final data = {
          "id": idInt,
          "name": prefs.getString('employeeName') ?? 'Employee',
          "mobile": prefs.getString('employeeMobile') ?? widget.phoneNumber,
          "city": prefs.getString('employeeCity') ?? '',
          "state": prefs.getString('employeeState') ?? '',
          "profile": prefs.getString('employeeProfile') ?? '',
        };

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false, arguments: data);
      } else {
        _showMsg(j['message']?.toString() ?? 'Invalid OTP');
      }
    } catch (e) {
      _showMsg("Network error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String get formattedTimer {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _showMsg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    timer?.cancel();
    cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Header
              Container(
                padding: const EdgeInsets.only(top: 40, bottom: 28),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Image.asset('assets/icon/app_icon.png'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Verify OTP', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Code sent to +91 ${widget.phoneNumber}', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: PinFieldAutoFill(
                  codeLength: 6,
                  currentCode: otp,
                  onCodeChanged: (c) {
                    if (!mounted) return;
                    setState(() => otp = c ?? "");
                    if ((c ?? "").length == 6) _verifyOtp();
                  },
                  decoration: BoxLooseDecoration(
                    strokeColorBuilder: FixedColorBuilder(primary),
                    bgColorBuilder: FixedColorBuilder(Colors.white),
                    radius: const Radius.circular(12),
                    gapSpace: 12,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(seconds > 0 ? 'Expires in $formattedTimer' : 'OTP expired', style: TextStyle(fontSize: 15, color: seconds > 0 ? primary : Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (otp.length == 6 && seconds > 0 && !loading) ? _verifyOtp : null,
                    style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verify OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: seconds == 0 ? () => Navigator.pop(context) : null,
                child: Text(seconds == 0 ? 'Resend OTP' : 'Wait to resend', style: TextStyle(color: seconds == 0 ? primary : Colors.grey)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
