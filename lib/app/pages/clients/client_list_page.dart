import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../models/client_model.dart';

class ClientListPage extends StatefulWidget {
  const ClientListPage({super.key});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  List<ClientModel> clients = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  fetchClients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    final id = prefs.getInt('employeeId');
    print("Employee ID: $id");

    print("Fetching clients with token: $token");
    final res = await http.get(
      Uri.parse(ApiConstants.clients),
      headers: ApiConstants.authHeaders(token),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)["data"];
      clients = (data as List).map((e) => ClientModel.fromJson(e)).toList();
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Clients")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
          ? const Center(child: Text("No clients assigned"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clients.length,
              itemBuilder: (_, i) => _clientCard(clients[i]),
            ),
    );
  }

  Widget _clientCard(ClientModel c) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: c.profile != null
                ? NetworkImage(c.profile!)
                : null,
            child: c.profile == null
                ? const Icon(Icons.person, size: 30, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(c.mobile, style: TextStyle(color: Colors.grey.shade700)),
                if ((c.city ?? "").isNotEmpty)
                  Text("${c.city}", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
