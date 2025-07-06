import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final supabase = Supabase.instance.client;
  String userType = 'Visitante';

  Future<void> login() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      final user = response.user;
      final userTypeFromMeta = user?.userMetadata?['user_type'];
      if (userTypeFromMeta != null) {
        if (userTypeFromMeta == userType) {
          setState(() {
            userType = userTypeFromMeta;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bienvenido $userTypeFromMeta')),
          );
          // Navega a la pantalla correspondiente
          if (userTypeFromMeta == 'Publicador') {
            Navigator.of(context).pushReplacementNamed('/crLugar');
          } else if (userTypeFromMeta == 'Visitante') {
            Navigator.of(context).pushReplacementNamed('/visitante');
          }
        } else {
          // Cierra la sesión si el tipo no coincide
          await supabase.auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No puedes iniciar sesión como "$userType". '
                'Tu cuenta está registrada como "$userTypeFromMeta".',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el tipo de usuario.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    }
  }

  Future<void> signup() async {
    try {
      await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
        data: {
          'user_type': userType,
          'display_name': nameController.text.trim(), // Guardar el nombre
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa tu correo para confirmar tu cuenta.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrarse: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: userType,
              decoration: const InputDecoration(labelText: 'Tipo de usuario'),
              items: const [
                DropdownMenuItem(value: 'Visitante', child: Text('Visitante')),
                DropdownMenuItem(
                  value: 'Publicador',
                  child: Text('Publicador'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  userType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Iniciar sesión'),
            ),
            TextButton(onPressed: signup, child: const Text('Registrarse')),
          ],
        ),
      ),
    );
  }
}
