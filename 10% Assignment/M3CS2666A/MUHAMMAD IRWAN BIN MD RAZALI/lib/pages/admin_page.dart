import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  final String managementUrl =
      "https://your-web-management-url.com"; // Change this

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService.logout(context),
          ),
        ],
      ),
      body: Center(
        child: Card(
          elevation: 3,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.web, size: 60, color: Colors.deepPurple.shade300),
                  const SizedBox(height: 20),

                  Text("Web-Based Management System",
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),

                  const SizedBox(height: 10),
                  const Text(
                    "Admin access is only available through the Web-Based Management System.",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  FilledButton.icon(
                    onPressed: () {
                      launchUrl(Uri.parse(managementUrl),
                          mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("Open Web Management"),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}