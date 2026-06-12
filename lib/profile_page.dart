import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

import 'edit_profile_page.dart';
import 'app_drawer.dart';
import 'widgets/logout_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFC7D6FF),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, auth),
            Expanded(child: _buildBody(context, auth)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Builder(builder: (ctx) => GestureDetector(onTap: () => Scaffold.of(ctx).openDrawer(), child: const Icon(Icons.menu, size: 28))),
          const SizedBox(width: 12),
          Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.find_replace, size: 40)),
          const SizedBox(width: 12),
          const Spacer(),
          const SizedBox(width: 12),
          PopupMenuButton<int>(
            offset: const Offset(0, 50), color: Colors.white, elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade300)),
            child: CircleAvatar(radius: 20, backgroundColor: Colors.white, backgroundImage: auth.user?.fotoUrl != null ? NetworkImage(auth.user!.fotoUrl!) : null, child: auth.user?.fotoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null),
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(auth.user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ])),
              const PopupMenuDivider(),
              PopupMenuItem(value: 1, child: const Row(children: [Icon(Icons.person), SizedBox(width: 12), Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold))])),
              PopupMenuItem(value: 2, child: const Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 12), Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),
            ],
            onSelected: (v) {
              if (v == 1) { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EditProfilePage())); }
              if (v == 2) { confirmLogout(context); }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider auth) {
    final user = auth.user;

    return Container(
      color: const Color(0xFFDCE6FF),
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black, width: 1.5)),
                  child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(borderRadius: BorderRadius.circular(14.5), child: auth.user?.fotoUrl != null ? Image.network(auth.user!.fotoUrl!, fit: BoxFit.cover) : const Center(child: Icon(Icons.person, size: 100, color: Colors.grey))),
                  ),
                ],
              ),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.role.toUpperCase() ?? 'USER', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              const Text('Nama', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _readField(user?.name ?? '-'),
              const SizedBox(height: 12),
              const Text('Username', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _readField(user?.username ?? '-'),
              const SizedBox(height: 12),
              const Text('Email', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _readField(user?.email ?? '-'),
              const SizedBox(height: 12),
              const Text('No Telp', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _readField(user?.noTelp ?? '-'),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7A59), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Edit', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}
