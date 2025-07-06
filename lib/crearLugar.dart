import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class CrLugarPage extends StatefulWidget {
  const CrLugarPage({super.key});

  @override
  State<CrLugarPage> createState() => _CrLugarPageState();
}

class _CrLugarPageState extends State<CrLugarPage> {
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();

  final supabase = Supabase.instance.client;
  List<String> uploadedImageUrls = [];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final user = supabase.auth.currentUser;
    final userType = user?.userMetadata?['user_type'];
    if (user == null || userType != 'Publicador') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acceso solo para Publicadores')),
        );
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> pickAndUploadImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      if (result.files.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo puedes seleccionar hasta 5 imágenes.'),
          ),
        );
        return;
      }
      List<String> urls = [];
      for (final file in result.files) {
        final fileBytes = file.bytes;
        if (fileBytes == null) continue;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        try {
          await supabase.storage
              .from('lugares-img')
              .uploadBinary(fileName, fileBytes);
          final url = supabase.storage
              .from('lugares-img')
              .getPublicUrl(fileName);
          urls.add(url);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir ${file.name}: $e')),
          );
        }
      }
      setState(() {
        uploadedImageUrls = urls;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imágenes subidas correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionaron imágenes')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lugares Turisticos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usuarioController,
              decoration: InputDecoration(labelText: 'Lugar'),
            ),
            TextField(
              controller: _mensajeController,
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    uploadedImageUrls.isEmpty
                        ? 'No hay imágenes seleccionadas'
                        : '${uploadedImageUrls.length} imagen(es) seleccionada(s)',
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: pickAndUploadImages,
                  child: const Text('Subir Imágenes'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_usuarioController.text.isNotEmpty &&
                    _mensajeController.text.isNotEmpty &&
                    uploadedImageUrls.isNotEmpty) {
                  // 1. Insertar el lugar
                  final lugarInsert = await supabase
                      .from('lugares')
                      .insert({
                        'lugar': _usuarioController.text,
                        'descripcion': _mensajeController.text,
                      })
                      .select()
                      .single();
                  final lugarId = lugarInsert['id'];
                  // 2. Insertar las imágenes en la tabla imagenes_lugar
                  for (final url in uploadedImageUrls) {
                    await supabase.from('imagenes_lugar').insert({
                      'lugar_id': lugarId,
                      'url': url,
                    });
                  }
                  _usuarioController.clear();
                  _mensajeController.clear();
                  setState(() {
                    uploadedImageUrls = [];
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lugar guardado exitosamente'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa todos los campos y sube al menos una imagen',
                      ),
                    ),
                  );
                }
              },
              child: Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
