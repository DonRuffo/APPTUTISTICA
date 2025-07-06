import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> guardarResena({
  required String lugarId,
  required String userId,
  required String contenido,
}) async {
  await Supabase.instance.client.from('reviews').insert({
    'post_id': lugarId,     // O 'lugar_id' según tu esquema
    'user_id': userId,
    'content': contenido,
    'created_at': DateTime.now().toIso8601String(), // Opcional, si tienes esta columna
  });
}