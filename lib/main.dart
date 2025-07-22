import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ectour/crearLugar.dart';
import 'package:ectour/visitantePage.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mqpsbzrziuppiigkbiva.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcHNienJ6aXVwcGlpZ2tiaXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMjIzNzIsImV4cCI6MjA2Njg5ODM3Mn0.yiCxB62ygVCmULMttRlrnC3HXmmh-vmCj4CAQYbD5zo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Upload App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/crLugar': (context) => const CrLugarPage(),
        '/visitante': (context) => const VisitorHomePage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getHomePage() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const LoginPage();
    }
    final user = Supabase.instance.client.auth.currentUser;
    final userType = user?.userMetadata?['user_type'];
    if (userType == 'Publicador') {
      return const CrLugarPage();
    } else if (userType == 'Visitante') {
      return const VisitorHomePage();
    } else {
      // Si el tipo no es válido, puedes regresar al login o mostrar error
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getHomePage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return snapshot.data!;
        }
        return const LoginPage();
      },
    );
  }
}
