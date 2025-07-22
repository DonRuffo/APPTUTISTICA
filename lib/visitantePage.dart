import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ectour/login_page.dart';
import 'package:ectour/services/review_service.dart';

class VisitorHomePage extends StatefulWidget {
  const VisitorHomePage({super.key});

  @override
  State<VisitorHomePage> createState() => _VisitorHomePageState();
}

class _VisitorHomePageState extends State<VisitorHomePage> {
  Future<List<Map<String, dynamic>>> _fetchLugares() async {
    final lugaresRes = await Supabase.instance.client
        .from('lugares')
        .select('id, lugar, descripcion')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(lugaresRes);
  }

  Future<List<Map<String, dynamic>>> _fetchImagenesLugar(String lugarId) async {
    final res = await Supabase.instance.client
        .from('imagenes_lugar')
        .select('url')
        .eq('lugar_id', lugarId);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> _fetchReviews(String lugarId) async {
    final res = await Supabase.instance.client
        .from('reviews')
        .select('content, created_at, user_id')
        .eq('post_id', lugarId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  @override
  Widget build(BuildContext context) {
    // Colores igual que login y crearLugar
    const Color cafeClaro = Color(0xFFD7CCC8); // Café claro
    const Color cafeOscuro = Color(0xFF6D4C41); // Café oscuro
    const Color acentoVerde = Color(0xFF81C784); // Verde suave

    return Scaffold(
      backgroundColor: cafeClaro,
      appBar: AppBar(
        backgroundColor: cafeOscuro,
        title: const Text('Sitios turísticos publicados', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
        future: _fetchLugares(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: [38;5;9m${snapshot.error}[0m'));
          }
          final lugares = snapshot.data ?? [];
          if (lugares.isEmpty) {
            return const Center(
              child: Text('No hay sitios turísticos publicados.'),
            );
          }
          return ListView.builder(
            itemCount: lugares.length,
            itemBuilder: (context, index) {
              final lugar = lugares[index];
              final reviewController = TextEditingController();
              bool isLoading = false;
              return StatefulBuilder(
                builder: (context, setState) {
                  return Card(
                    color: Colors.white.withOpacity(0.97),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: cafeOscuro.withOpacity(0.15), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchImagenesLugar(lugar['id'].toString()),
                              builder: (context, imgSnapshot) {
                                if (imgSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 180,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (imgSnapshot.hasError) {
                                  return const SizedBox(
                                    height: 180,
                                    child: Center(child: Text('Error al cargar imágenes')),
                                  );
                                }
                                final imagenes = imgSnapshot.data ?? [];
                                if (imagenes.isEmpty) {
                                  return const SizedBox(
                                    height: 180,
                                    child: Center(child: Text('Sin imágenes')),
                                  );
                                }
                                return SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imagenes.length,
                                    itemBuilder: (context, imgIndex) {
                                      final url = imagenes[imgIndex]['url'];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            url,
                                            width: 250,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const SizedBox(
                                                  width: 250,
                                                  height: 180,
                                                  child: Center(child: Text('No se pudo cargar')),
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          ListTile(
                            title: Text(
                              lugar['lugar'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cafeOscuro,
                                fontSize: 20,
                              ),
                            ),
                            subtitle: Text(
                              lugar['descripcion'] ?? '',
                              style: TextStyle(color: cafeOscuro.withOpacity(0.8)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchReviews(lugar['id'].toString()),
                              builder: (context, reviewSnapshot) {
                                if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Cargando reseñas...');
                                }
                                if (reviewSnapshot.hasError) {
                                  return Text('Error al cargar reseñas');
                                }
                                final reviews = reviewSnapshot.data ?? [];
                                if (reviews.isEmpty) {
                                  return const Text('No hay reseñas aún.');
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reseñas:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ...reviews.map(
                                      (review) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Text(
                                          '• ${review['users']?['display_name'] ?? 'Usuario'}: ${review['content']}',
                                          style: TextStyle(fontSize: 14, color: cafeOscuro),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Deja tu reseña:'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: reviewController,
                                        decoration: InputDecoration(
                                          hintText: 'Escribe tu reseña...',
                                          filled: true,
                                          fillColor: cafeClaro.withOpacity(0.4),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: cafeOscuro),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.send, color: acentoVerde),
                                            tooltip: 'Enviar reseña',
                                            onPressed: () async {
                                              final content = reviewController.text.trim();
                                              if (content.isEmpty) return;
                                              final userId = Supabase.instance.client.auth.currentUser?.id;
                                              if (userId == null) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Debes iniciar sesión para dejar una reseña.'),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }
                                              setState(() => isLoading = true);
                                              try {
                                                await guardarResena(
                                                  lugarId: lugar['id'].toString(),
                                                  userId: userId,
                                                  contenido: content,
                                                );
                                                reviewController.clear();
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Reseña enviada.'),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e')),
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
