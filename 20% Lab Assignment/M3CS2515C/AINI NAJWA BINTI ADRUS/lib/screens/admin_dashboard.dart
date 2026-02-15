import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') authProvider.logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== WELCOME =====
            const Text(
              'Welcome, Admin 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'System overview',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

// ===== USER STATUS =====
            const Row(
              children: [
                StatusCard(
                  title: 'Total Users',
                  value: '120',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                SizedBox(width: 16),
                StatusCard(
                  title: 'Active Users',
                  value: '85',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ===== OPEN WEB BUTTON =====
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Web Management'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => _openPortal(
                context,
                title: 'Web Management System',
                url: 'https://uitm.edu.my',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== OPEN PORTAL METHOD =====
  Future<void> _openPortal(
    BuildContext context, {
    required String title,
    required String url,
  }) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        url: url,
      ),
    );

    if (!context.mounted) return;

    if (shouldOpen == true) {
      final uri = Uri.parse(url);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

// ===== STATUS CARD WIDGET =====
class StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatusCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== CONFIRMATION DIALOG =====
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String url;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(title),
      content: Text(
        'Do you want to open this portal?\n\n$url',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open'),
        ),
      ],
    );
  }
}
