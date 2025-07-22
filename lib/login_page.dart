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
    // Definición de colores
    const Color cafeClaro = Color(0xFFD7CCC8); // Café claro
    const Color cafeOscuro = Color(0xFF6D4C41); // Café oscuro
    const Color acentoVerde = Color(0xFF81C784); // Verde suave

    return Scaffold(
      backgroundColor: cafeClaro,
      appBar: AppBar(
        backgroundColor: cafeOscuro,
        title: const Text('Login Buho - Turistico', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cafeOscuro.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 64, color: cafeOscuro),
                const SizedBox(height: 12),
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cafeOscuro,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: cafeOscuro),
                    filled: true,
                    fillColor: cafeClaro.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cafeOscuro),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock, color: cafeOscuro),
                    filled: true,
                    fillColor: cafeClaro.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cafeOscuro),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person, color: cafeOscuro),
                    filled: true,
                    fillColor: cafeClaro.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cafeOscuro),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: userType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de usuario',
                    filled: true,
                    fillColor: cafeClaro.withOpacity(0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cafeOscuro),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Visitante', child: Text('Visitante')),
                    DropdownMenuItem(value: 'Publicador', child: Text('Publicador')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      userType = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cafeOscuro,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: login,
                    child: const Text('Iniciar sesión', style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: signup,
                  style: TextButton.styleFrom(
                    foregroundColor: acentoVerde,
                  ),
                  child: const Text('Registrarse', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
