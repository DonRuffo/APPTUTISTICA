import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_upload_app/login_page.dart';

class VisitorHomePage extends StatefulWidget {
  const VisitorHomePage({super.key});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  Future<List<Map<String, dynamic>>> _fetchPostsWithPhoto() async {
    final postsRes = await Supabase.instance.client
        .from('lugares')
        .select('id, lugar, descripcion')
        .order('created_at', ascending: false);
    final posts = List<Map<String, dynamic>>.from(postsRes);
    for (final post in posts) {
      final photosRes = await Supabase.instance.client
          .from('photos')
          .select('url')
          .eq('post_id', post['id'])
          .limit(1);
      post['photo_url'] = (photosRes.isNotEmpty) ? photosRes[0]['url'] : null;
    }
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitios turísticos publicados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPostsWithPhoto(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text('No hay sitios turísticos publicados.'),
            );
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final reviewController = TextEditingController();
              bool isLoading = false;
              return StatefulBuilder(
                builder: (context, setState) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post['photo_url'] != null)
                          Image.network(
                            post['photo_url'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ListTile(
                          title: Text(post['title'] ?? ''),
                          subtitle: Text(post['description'] ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Deja tu reseña:'),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: reviewController,
                                      decoration: const InputDecoration(
                                        hintText: 'Escribe tu reseña...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.send),
                                          tooltip: 'Enviar reseña',
                                          onPressed: () async {
                                            final content = reviewController
                                                .text
                                                .trim();
                                            if (content.isEmpty) return;
                                            setState(() => isLoading = true);
                                            try {
                                              final userId = Supabase
                                                  .instance
                                                  .client
                                                  .auth
                                                  .currentUser
                                                  ?.id;
                                              await Supabase.instance.client
                                                  .from('reviews')
                                                  .insert({
                                                    'post_id': post['id'],
                                                    'user_id': userId,
                                                    'content': content,
                                                  });
                                              reviewController.clear();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Reseña enviada.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                  ),
                                                );
                                              }
                                            } finally {
                                              setState(() => isLoading = false);
                                            }
                                          },
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}