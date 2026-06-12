import 'package:flutter/material.dart';
import 'add_post_page.dart';
import 'post_history_page.dart';
import 'app_drawer.dart';

class PrePostPage extends StatelessWidget {
  const PrePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC7D6FF),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Builder(builder: (ctx) => GestureDetector(onTap: () => Scaffold.of(ctx).openDrawer(), child: const Icon(Icons.menu, size: 28))),
                  const SizedBox(width: 12),
                  Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, _, _) => const Icon(Icons.find_replace, size: 40)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFDCE6FF),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _btn(context, 'Tambah Postingan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPostPage()))),
                    const SizedBox(height: 16),
                    _btn(context, 'Riwayat Postingan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostHistoryPage()))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String text, VoidCallback onPressed) {
    return SizedBox(
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
