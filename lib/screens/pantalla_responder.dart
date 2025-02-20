import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class EncuestaPage extends StatefulWidget {
  final int encuestaId;

  const EncuestaPage({super.key, required this.encuestaId});

  @override
  State<EncuestaPage> createState() => _EncuestaPageState();
}

class _EncuestaPageState extends State<EncuestaPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _encuesta;
  List<dynamic> _preguntas = [];
  final Map<int, dynamic> _respuestas = {};
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEncuesta();
  }

  /// **Obtiene la encuesta desde la API**
  Future<void> _cargarEncuesta() async {
    try {
      String? token = await _storage.read(key: "access_token");

      final response = await http.get(
        Uri.parse('https://1.conteosa.com/api/encuestas/${widget.encuestaId}/'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _encuesta = data;
          _preguntas = data["secciones"][0]["preguntas"] ?? [];
          _cargando = false;
        });

        print("📌 Preguntas extraídas: $_preguntas");
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
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Encuesta")),
        body: Center(child: Text(_error!, style: TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_encuesta?["titulo"] ?? "Encuesta")),
      body: _construirFormulario(),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardarEncuesta,
        child: const Icon(Icons.save),
      ),
    );
  }

  /// **Construye la lista de preguntas dinámicamente**
  Widget _construirFormulario() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _preguntas.length,
      itemBuilder: (context, index) {
        final pregunta = _preguntas[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _construirPregunta(pregunta),
        );
      },
    );
  }

  /// **Genera el widget para cada tipo de pregunta**
  Widget _construirPregunta(Map<String, dynamic> pregunta) {
    switch (pregunta["tipo"]) {
      case "text":
        return _campoTexto(pregunta);
      case "number":
        return _campoNumero(pregunta);
      case "radio":
        return _campoRadio(pregunta);
      case "datetime":
        return _campoFechaHora(pregunta);
      default:
        return const SizedBox.shrink();
    }
  }

  /// **Crea un TextField para preguntas de tipo "text"**
  Widget _campoTexto(Map<String, dynamic> pregunta) {
    final int preguntaId = pregunta["id"];
    final controller =
        TextEditingController(text: _respuestas[preguntaId] ?? "");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta["etiqueta"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: pregunta["placeholder"] ?? "",
            border: const OutlineInputBorder(),
          ),
          onChanged: (valor) {
            setState(() {
              _respuestas[preguntaId] = valor;
            });
          },
        ),
      ],
    );
  }

  /// **Crea un TextField para preguntas de tipo "number"**
  Widget _campoNumero(Map<String, dynamic> pregunta) {
    final int preguntaId = pregunta["id"];
    final controller =
        TextEditingController(text: _respuestas[preguntaId]?.toString() ?? "");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta["etiqueta"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onChanged: (valor) {
            setState(() {
              _respuestas[preguntaId] = int.tryParse(valor) ?? valor;
            });
          },
        ),
      ],
    );
  }

  /// **Crea un grupo de opciones tipo "radio"**
  Widget _campoRadio(Map<String, dynamic> pregunta) {
    final int preguntaId = pregunta["id"];
    final List<dynamic> opciones = pregunta["opciones"] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta["etiqueta"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ...opciones.map((opcion) {
          return RadioListTile(
            title: Text(opcion),
            value: opcion,
            groupValue: _respuestas[preguntaId],
            onChanged: (valor) {
              setState(() {
                _respuestas[preguntaId] = valor;
              });
            },
          );
        }),
      ],
    );
  }

  /// **Crea un campo para seleccionar fecha/hora**
  Widget _campoFechaHora(Map<String, dynamic> pregunta) {
    final int preguntaId = pregunta["id"];
    String? fechaSeleccionada = _respuestas[preguntaId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta["etiqueta"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () async {
            DateTime? fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (fecha != null) {
              TimeOfDay? hora = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );

              if (hora != null) {
                DateTime fechaHora = DateTime(
                  fecha.year,
                  fecha.month,
                  fecha.day,
                  hora.hour,
                  hora.minute,
                );
                setState(() {
                  _respuestas[preguntaId] =
                      DateFormat("yyyy-MM-dd HH:mm").format(fechaHora);
                });
              }
            }
          },
          child: Text(fechaSeleccionada ?? "Seleccionar fecha y hora"),
        ),
      ],
    );
  }

  /// **Guarda y valida la encuesta**
  void _guardarEncuesta() {
    for (var pregunta in _preguntas) {
      if (pregunta["required"] == true &&
          (_respuestas[pregunta["id"]] == null ||
              _respuestas[pregunta["id"]].toString().trim().isEmpty)) {
        _mostrarError("La pregunta '${pregunta["etiqueta"]}' es obligatoria.");
        return;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
          title: const Text("Respuestas"),
          content: Text(jsonEncode(_respuestas))),
    );
  }

  void _mostrarError(String mensaje) {
    showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(title: const Text("Error"), content: Text(mensaje)));
  }
}
