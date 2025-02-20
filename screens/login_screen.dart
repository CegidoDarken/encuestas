import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pantalla_encuestas.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isObscure = true;
  bool _cargando = false;
  String? _errorMensaje;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B1E59),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔹 LOGO
                SizedBox(
                  height: 80,
                  child: Image.asset("assets/ADN1.png", fit: BoxFit.contain),
                ),

                // 🔹 TÍTULO
                const Text(
                  "ENCUESTAS",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFED70D)),
                ),
                const SizedBox(height: 10),
                const Text("Inicia sesión para continuar", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 30),

                // 🔹 CAMPO DE EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration("Correo electrónico", Icons.email),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => value == null || value.isEmpty ? "Ingresa tu correo" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 CAMPO DE CONTRASEÑA
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: _inputDecoration("Contraseña", Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                      onPressed: () {
                        setState(() => _isObscure = !_isObscure);
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) => value == null || value.isEmpty ? "Ingresa tu contraseña" : null,
                ),
                const SizedBox(height: 20),

                // 🔹 BOTÓN DE INICIO DE SESIÓN
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFED70D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _cargando ? null : _iniciarSesion,
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Iniciar Sesión", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),

                // 🔹 MENSAJE DE ERROR
                if (_errorMensaje != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _errorMensaje!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 🔹 ¿OLVIDASTE TU CONTRASEÑA?
                TextButton(
                  onPressed: () {
                    // Implementar función de recuperación si es necesario
                  },
                  child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Estilo de los campos de texto
  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white10,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      hintStyle: const TextStyle(color: Colors.white54),
    );
  }

  // 🔹 Función para iniciar sesión
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _errorMensaje = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://1.conteosa.com/api/token/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      print("🔹 Código de respuesta: ${response.statusCode}");
      print("🔹 Cuerpo de respuesta: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String accessToken = data["access"];
        String refreshToken = data["refresh"];

        // 🔹 Guardar los tokens de acceso y actualización
        await _storage.write(key: "access_token", value: accessToken);
        await _storage.write(key: "refresh_token", value: refreshToken);

        // 🔹 Navegar a la pantalla de encuestas disponibles
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PantallaEncuestas()),
        );
      } else {
        throw Exception("Credenciales incorrectas. Verifica tu usuario y contraseña.");
      }
    } catch (e) {
      setState(() => _errorMensaje = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }
}
