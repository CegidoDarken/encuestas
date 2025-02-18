import 'package:encuestas/screens/encuesta_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true; // Para ocultar/mostrar la contraseña

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4B1E59), // Fondo oscuro elegante
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o Icono
                SizedBox(
                height: 80, // Tamaño del icono
                  child: Image.asset("assets/ADN1.png", fit: BoxFit.contain),
                   ),

                // Texto de Bienvenida
                Text(
                  "ENCUESTAS",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFED70D),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Inicia sesión para continuar",
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 30),

                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    hintText: "Correo electrónico",
                    prefixIcon: Icon(Icons.email, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    } /*else if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Correo inválido';
                    }*/
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    hintText: "Contraseña",
                    prefixIcon: Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    } 
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Botón de Iniciar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFED70D), // Color del botón
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_emailController.text == "admin" &&
                            _passwordController.text == "admin") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Inicio de sesión exitoso")),
                          );
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PaginaEncuesta()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Credenciales incorrectas")),
                          );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Iniciando sesión...")),
                        );
                      }
                    },
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Enlace "¿Olvidaste tu contraseña?"
                TextButton(
                  onPressed: () {
                    // Aquí puedes navegar a una pantalla de recuperación de contraseña
                  },
                  child: Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
