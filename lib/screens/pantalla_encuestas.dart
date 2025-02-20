import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pantalla_responder.dart';

class PantallaEncuestas extends StatefulWidget {
  const PantallaEncuestas({super.key});

  @override
  _PantallaEncuestasState createState() => _PantallaEncuestasState();
}

class _PantallaEncuestasState extends State<PantallaEncuestas> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<dynamic> _encuestas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEncuestas();
  }

  Future<void> _cargarEncuestas() async {
    try {
      String? token = await _storage.read(key: "access_token");

      final response = await http.get(
        Uri.parse('https://1.conteosa.com/api/encuestas/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> encuestas = jsonDecode(response.body);

        setState(() {
          _encuestas = encuestas.where((e) => e['disponible'] == true).toList();
          _cargando = false;
        });
      } else {
        throw Exception("Error al obtener encuestas");
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Encuestas Disponibles")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : _encuestas.isEmpty
                  ? const Center(child: Text("No hay encuestas disponibles"))
                  : ListView.builder(
                      itemCount: _encuestas.length,
                      itemBuilder: (context, index) {
                        final encuesta = _encuestas[index];

                        return ListTile(
                          title: Text(encuesta["titulo"]),
                          subtitle: Text(
                              "Fecha de creación: ${encuesta["fecha_creacion"]}"),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EncuestaPage(encuestaId: encuesta["id"]),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
