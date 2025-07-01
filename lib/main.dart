import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_upload_app/crearLugar.dart';
import 'login_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mqpsbzrziuppiigkbiva.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xcHNienJ6aXVwcGlpZ2tiaXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzMjIzNzIsImV4cCI6MjA2Njg5ODM3Mn0.yiCxB62ygVCmULMttRlrnC3HXmmh-vmCj4CAQYbD5zo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Upload App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const CrLugarPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}