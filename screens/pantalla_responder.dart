import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PantallaResponder extends StatefulWidget {
  final int encuestaId;
  const PantallaResponder({super.key, required this.encuestaId});

  @override
  _PantallaResponderState createState() => _PantallaResponderState();
}

class _PantallaResponderState extends State<PantallaResponder> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _encuesta;
  List<dynamic> _preguntas = []; // ✅ Lista de preguntas
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEncuesta();
  }
Future<void> _cargarEncuesta() async {
  try {
    String? token = await _storage.read(key: "access_token");
    final response = await http.get(
      Uri.parse('https://1.conteosa.com/api/encuestas/${widget.encuestaId}/'),
      headers: {"Authorization": "Bearer $token"},
    );

    print("🔹 Código de respuesta: ${response.statusCode}");
    print("🔹 JSON recibido: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      setState(() {
        _encuesta = data;
        _preguntas = data["secciones"][0]["preguntas"] ?? []; // Accede correctamente a las preguntas
        _cargando = false;
      });

      print("📌 Preguntas extraídas: $_preguntas"); // Verificar si _preguntas tiene datos
    } else {
      throw Exception("Error al obtener la encuesta");
    }
  } catch (e) {
    setState(() {
      _error = "Error al cargar la encuesta: $e";
      _cargando = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_encuesta?["titulo"] ?? "Encuesta")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : _preguntas.isEmpty
                  ? const Center(child: Text("No hay preguntas disponibles."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _preguntas.length,
                      itemBuilder: (context, index) {
                        var pregunta = _preguntas[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(pregunta["etiqueta"]),
                            subtitle: Text("Tipo: ${pregunta["tipo"]}"),
                          ),
                        );
                      },
                    ),
    );
  }
}
