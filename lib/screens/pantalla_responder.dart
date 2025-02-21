import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class EncuestaPage extends StatefulWidget {
  final int encuestaId;

  const EncuestaPage({Key? key, required this.encuestaId}) : super(key: key);

  @override
  State<EncuestaPage> createState() => _EncuestaPageState();
}

class _EncuestaPageState extends State<EncuestaPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _encuesta;
  List<dynamic> _secciones = [];
  int _indiceSeccionActual = 0;
  Map<int, dynamic> _respuestas = {};
  bool _cargando = true;
  String? _error;
  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();
    _cargarEncuesta();
    _obtenerUbicacion();
  }

  /// **📡 Obtiene la encuesta desde la API**
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
          _secciones = data["secciones"] ?? [];
          _cargando = false;
        });
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
        body: Center(
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final bool esUltimaSeccion = _indiceSeccionActual == _secciones.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(_encuesta?["titulo"] ?? "Encuesta")),
      body: _construirSeccion(_secciones[_indiceSeccionActual]),
      bottomNavigationBar: _barraNavegacion(esUltimaSeccion),
    );
  }

  /// **📌 Construye las secciones dinámicamente**
  Widget _construirSeccion(Map<String, dynamic> seccion) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(seccion["titulo"],
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._construirPreguntas(seccion["preguntas"] ?? []),
        ],
      ),
    );
  }

  List<Widget> _construirPreguntas(List<dynamic> preguntas) {
    return preguntas.map((pregunta) {
      switch (pregunta["tipo"]) {
        case "text":
          return _campoTexto(pregunta);
        case "radio":
          return _campoRadio(pregunta);
        case "number":
          return _campoNumero(pregunta);
        case "datetime":
          return _campoFechaHora(pregunta);
        default:
          return const SizedBox.shrink();
      }
    }).toList();
  }

  Widget _campoTexto(Map<String, dynamic> pregunta) {
    final int id = pregunta["id"];
    return _inputField(
      pregunta,
      TextField(
        controller: TextEditingController(text: _respuestas[id] ?? ""),
        onChanged: (valor) => _respuestas[id] = valor,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: pregunta["etiqueta"]),
      ),
    );
  }

  Widget _campoNumero(Map<String, dynamic> pregunta) {
    final int id = pregunta["id"];
    return _inputField(
      pregunta,
      TextField(
        keyboardType: TextInputType.number,
        onChanged: (valor) => _respuestas[id] = int.tryParse(valor) ?? valor,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: pregunta["etiqueta"]),
      ),
    );
  }

  Widget _campoRadio(Map<String, dynamic> pregunta) {
    final int id = pregunta["id"];
    final List<dynamic> opciones = pregunta["opciones"] ?? [];
    return _inputField(
      pregunta,
      Column(
        children: opciones.map((opcion) {
          return RadioListTile(
            title: Text(opcion),
            value: opcion,
            groupValue: _respuestas[id],
            onChanged: (valor) => setState(() => _respuestas[id] = valor),
          );
        }).toList(),
      ),
    );
  }

  /// **📍 Obtiene la ubicación actual**
  Future<void> _obtenerUbicacion() async {
    Position posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitud = posicion.latitude;
      _longitud = posicion.longitude;
    });
  }

  Future<void> _guardarEncuesta() async {
    await _obtenerUbicacion();

    String? userIdString = await _storage.read(key: "user_id");
    int? userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (userId == null) {
      _mostrarError("No se pudo obtener el ID del usuario.");
      return;
    }

    List<Map<String, dynamic>> respuestasLista =
        _respuestas.entries.map((entry) {
      int preguntaId = entry.key;
      var respuestaValor = entry.value;

      return {
        "user_id": userId,
        "pregunta_id": preguntaId,
        "respuesta": respuestaValor.toString(),
        "latitud": _latitud,
        "longitud": _longitud,
      };
    }).toList();

    Map<String, dynamic> datosFinales = {"respuestas": respuestasLista};

    // ✅ Imprime el JSON en la consola en lugar de enviarlo
    print("📡 JSON generado para enviar:");
    print(jsonEncode(datosFinales));

    String? token = await _storage.read(key: "access_token");

    final response = await http.post(
      Uri.parse('https://1.conteosa.com/api/guardar_respuestas/'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(datosFinales),
    );

    if (response.statusCode == 201) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Guardado Correctamente"),
          content: SingleChildScrollView(
              child: Text("Respuestas guardadas correctamente")),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error al guardar"),
          content: SingleChildScrollView(child: Text(response.body)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Widget _inputField(Map<String, dynamic> pregunta, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(pregunta["etiqueta"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _campoFechaHora(Map<String, dynamic> pregunta) {
    final int id = pregunta["id"];
    return _inputField(
      pregunta,
      ElevatedButton(
        onPressed: () async {
          DateTime? fecha = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (fecha != null) {
            setState(
                () => _respuestas[id] = DateFormat("yyyy-MM-dd").format(fecha));
          }
        },
        child: Text(_respuestas[id] ?? "Seleccionar fecha"),
      ),
    );
  }

  Widget _barraNavegacion(bool esUltimaSeccion) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_indiceSeccionActual > 0)
            ElevatedButton(
                onPressed: () => setState(() => _indiceSeccionActual--),
                child: const Text("Atrás")),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _validarSeccionActual()
                ? (esUltimaSeccion
                    ? _guardarEncuesta()
                    : setState(() => _indiceSeccionActual++))
                : null,
            child: Text(esUltimaSeccion ? "Guardar" : "Siguiente"),
          ),
        ],
      ),
    );
  }

  bool _validarSeccionActual() {
    final preguntas = _secciones[_indiceSeccionActual]["preguntas"] ?? [];
    for (var pregunta in preguntas) {
      final int id = pregunta["id"];
      if (pregunta["required"] == true &&
          (_respuestas[id] == null ||
              _respuestas[id].toString().trim().isEmpty)) {
        _mostrarError("La pregunta '${pregunta["etiqueta"]}' es obligatoria.");
        return false;
      }
    }
    return true;
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
