import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_page.dart';
import 'add_post_page.dart';
import 'post_history_page.dart';
import 'notification_page.dart';
import 'profile_page.dart';
import 'widgets/logout_dialog.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 20),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: const Color(0xFFE0E0E0), backgroundImage: auth.user?.fotoUrl != null ? NetworkImage(auth.user!.fotoUrl!) : null, child: auth.user?.fotoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(auth.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.black87, size: 28),
                  title: const Text('Beranda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () => _nav(context, const HomePage()),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.add_comment, color: Colors.black87, size: 28),
                  title: const Text('Tambah Postingan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  shape: const Border(),
                  children: [
                    _subTile(context, 'Tambah Postingan', const AddPostPage()),
                    _subTile(context, 'Riwayat Postingan', const PostHistoryPage()),
                  ],
                ),
                ExpansionTile(
                  leading: const Icon(Icons.notifications, color: Colors.black87, size: 28),
                  title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  iconColor: Colors.black,
                  textColor: Colors.black,
                  shape: const Border(),
                  children: [
                    _subTile(context, 'Laporan Penemuan Barang', const NotificationPage()),
                  ],
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.black87, size: 28),
                  title: const Text('Setting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  onTap: () => _nav(context, const ProfilePage()),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout, color: Colors.red, size: 28),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              confirmLogout(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,
        transitionDuration: Duration.zero,
      ),
    );
  }

  Widget _subTile(BuildContext context, String title, Widget page) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Row(
        children: [
          const Text('•', style: TextStyle(color: Colors.grey, fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15))),
        ],
      ),
      onTap: () => _nav(context, page),
    );
  }
}
