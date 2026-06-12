import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

import 'widgets/logout_dialog.dart';
import 'app_drawer.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telpCtrl;
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  File? _fotoFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _telpCtrl = TextEditingController(text: user?.noTelp ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _telpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _usernameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      _showSnack('Nama, username, dan email wajib diisi');
      return;
    }
    if (_passCtrl.text.isNotEmpty && _passCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Password dan konfirmasi password tidak cocok');
      return;
    }

    final err = await context.read<AuthProvider>().updateProfile(
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      noTelp: _telpCtrl.text.trim(),
      password: _passCtrl.text.isNotEmpty ? _passCtrl.text : null,
      fotoPath: _fotoFile?.path,
    );

    if (!mounted) return;
    if (err == null) {
      _showSnack('Profil berhasil diperbarui!');
      Navigator.pop(context);
    } else {
      _showSnack(err);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setState(() => _fotoFile = File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (picked != null) setState(() => _fotoFile = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }

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
              if (v == 1) { Navigator.pop(context); }
              if (v == 2) { confirmLogout(context); }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AuthProvider auth) {
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
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(borderRadius: BorderRadius.circular(14.5), child: _fotoFile != null ? Image.file(_fotoFile!, fit: BoxFit.cover) : (auth.user?.fotoUrl != null ? Image.network(auth.user!.fotoUrl!, fit: BoxFit.cover) : const Center(child: Icon(Icons.person, size: 100, color: Colors.grey)))),
                        ),
                        Positioned(right: 5, bottom: 5, child: Icon(Icons.camera_alt, color: Colors.black.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(auth.user?.role.toUpperCase() ?? 'USER', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              const Text('Nama', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_nameCtrl, 'Nama Lengkap'),
              const SizedBox(height: 12),
              const Text('Username', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_usernameCtrl, 'Username'),
              const SizedBox(height: 12),
              const Text('Email', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_emailCtrl, 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              const Text('No Telp', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_telpCtrl, 'Nomor telepon', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              const Text('Ubah Password', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              _field(_passCtrl, 'Password baru (kosongkan jika tidak diubah)', obscure: _obscurePass,
                  suffix: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePass = !_obscurePass))),
              const SizedBox(height: 12),
              _field(_confirmPassCtrl, 'Konfirmasi password baru', obscure: _obscureConfirm,
                  suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B65FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
