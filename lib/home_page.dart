import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _todoController = TextEditingController();

  // ==============================
  // TAMBAH TUGAS
  // ==============================
  void _tambahList() async {
    final user = _auth.currentUser;

    if (user != null && _todoController.text.trim().isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('todos')
          .add({
        'task': _todoController.text.trim(),
        'completed': false, // ✅ INI KUNCI CHECKBOX
        'createdAt': FieldValue.serverTimestamp(),
      });

      _todoController.clear();
    }
  }

  // ==============================
  // LOGOUT
  // ==============================
  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Column(
        children: [
          // ==============================
          // LIST TODO
          // ==============================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada tugas'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final completed = doc['completed'] ?? false;

                    return ListTile(
                      leading: Checkbox(
                        value: completed,
                        onChanged: (value) {
                          doc.reference.update({
                            'completed': value,
                          });
                        },
                      ),
                      title: Text(
                        doc['task'],
                        style: TextStyle(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ==============================
          // INPUT TUGAS
          // ==============================
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: const InputDecoration(
                      hintText: 'Masukkan Tugas Baru',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _tambahList,
                  icon: const Icon(Icons.add_circle, size: 30),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}