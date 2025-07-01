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
  final TextEditingController _imagenController = TextEditingController();

  final supabase = Supabase.instance.client;
  String? uploadedImageUrl;

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

  Future<void> pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          result.files.single.name;
      try {
        await supabase.storage
            .from('lugares-img')
            .uploadBinary(fileName, fileBytes);
        final url = supabase.storage.from('lugares-img').getPublicUrl(fileName);
        setState(() {
          uploadedImageUrl = url;
          _imagenController.text = url; // Mostrar la URL en el campo
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Imagen subida correctamente')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ninguna imagen')),
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
                  child: TextField(
                    controller: _imagenController,
                    decoration: InputDecoration(labelText: 'Imagen URL'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: pickAndUploadImage,
                  child: const Text('Subir Imagen'),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_usuarioController.text.isNotEmpty &&
                    _mensajeController.text.isNotEmpty &&
                    uploadedImageUrl != null) {
                  final data = {
                    'lugar': _usuarioController.text,
                    'descripcion': _mensajeController.text,
                    'imagen': uploadedImageUrl,
                  };
                  await supabase.from('lugares').insert(data);
                  _usuarioController.clear();
                  _mensajeController.clear();
                  _imagenController.clear();
                  setState(() {
                    uploadedImageUrl = null;
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
                        'Completa todos los campos y sube una imagen',
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
