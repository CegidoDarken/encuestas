import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuesta por Secciones',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PaginaEncuesta(),
    );
  }
}

class PaginaEncuesta extends StatefulWidget  {
  const PaginaEncuesta({Key? key}) : super(key: key);

  @override
  State<PaginaEncuesta> createState() => _PaginaEncuestaState();
}

class _PaginaEncuestaState extends State<PaginaEncuesta> {
  /// JSON de ejemplo (en un caso real podrías cargarlo de assets o de una API).
  final String _jsonEncuesta = """
  {
    "titulo": "Encuesta por Secciones",
    "secciones": [
      {
        "titulo": "Información Personal",
        "campos": [
          {
            "tipo": "text",
            "etiqueta": "Nombre",
            "placeholder": "Ingresa tu nombre",
            "required": true
          },
          {
            "tipo": "number",
            "etiqueta": "Edad",
            "placeholder": "Ingresa tu edad",
            "required": false
          }
        ]
      },
      {
        "titulo": "Preferencias",
        "campos": [
          {
            "tipo": "dropdown",
            "etiqueta": "Género de música favorito",
            "opciones": ["Rock", "Pop", "Reggaetón", "Clásica"],
            "required": true
          },
          {
            "tipo": "text",
            "etiqueta": "Cantante o banda favorita",
            "placeholder": "Ingresa un nombre",
            "required": false
          }
        ]
      }
    ]
  }
  """;

  /// Aquí almacenaremos el JSON original parseado.
  Map<String, dynamic>? _jsonOriginal;

  /// Esta será la "copia" (o estructura espejo) donde
  /// cada campo tiene además la propiedad "valor" para
  /// guardar la respuesta del usuario.
  Map<String, dynamic>? _jsonConValores;

  /// Índice de la sección actual.
  int _indiceSeccionActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarYPrepararEncuesta();
  }

  /// Lee el JSON y crea la estructura temporal que incluirá la propiedad "valor".
  void _cargarYPrepararEncuesta() {
    // Parseamos el JSON original
    final data = jsonDecode(_jsonEncuesta);

    // Guardamos el original solo por referencia, si lo necesitas.
    _jsonOriginal = data;

    // Ahora creamos una copia donde cada campo tenga 'valor'.
    // Para ello, recorremos las secciones y sus campos.
    Map<String, dynamic> copia = {
      "titulo": data["titulo"],
      "secciones": [],
    };

    // Recorrer secciones
    for (var seccion in data["secciones"]) {
      Map<String, dynamic> nuevaSeccion = {
        "titulo": seccion["titulo"],
        "campos": [],
      };

      for (var campo in seccion["campos"]) {
        // Copiamos las propiedades existentes
        Map<String, dynamic> nuevoCampo = {
          "tipo": campo["tipo"],
          "etiqueta": campo["etiqueta"],
          "placeholder": campo["placeholder"],
          "required": campo["required"] ?? false,
          // Si hay opciones (para dropdown), las copiamos
          if (campo["opciones"] != null) "opciones": campo["opciones"],
          // AÑADIMOS la propiedad 'valor', que inicia en vacío
          "valor": "",
        };
        nuevaSeccion["campos"].add(nuevoCampo);
      }

      copia["secciones"].add(nuevaSeccion);
    }

    setState(() {
      _jsonConValores = copia;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si aún no se ha parseado o copiado, mostramos un loader
    if (_jsonConValores == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Tomamos la lista de secciones
    final List secciones = _jsonConValores!["secciones"];

    // Sabemos si estamos en la última sección
    final bool esUltimaSeccion = _indiceSeccionActual == secciones.length - 1;

    // Extraemos la sección actual
    final seccionActual = secciones[_indiceSeccionActual];

    return Scaffold(
      appBar: AppBar(
        title: Text(_jsonConValores!["titulo"] ?? "Encuesta"),
      ),
      body: _construirSeccion(seccionActual),
      bottomNavigationBar: _barraNavegacion(esUltimaSeccion),
    );
  }

  /// Construye el contenido de la sección actual.
  Widget _construirSeccion(Map<String, dynamic> seccion) {
    final campos = seccion["campos"] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Text(
            seccion["titulo"] ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Generamos widgets para los campos de la sección
          ...List.generate(
            campos.length,
            (index) {
              final campo = campos[index];
              return Column(
                children: [
                  _construirCampo(campo),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Construye un widget según el tipo de campo
  Widget _construirCampo(Map<String, dynamic> campo) {
    switch (campo["tipo"]) {
      case "text":
      case "number":
        return _campoTexto(campo);
      case "dropdown":
        return _campoDropdown(campo);
      // Aquí podrías manejar más tipos: checkbox, radio, etc.
      default:
        return const SizedBox.shrink(); // Widget vacío en caso desconocido
    }
  }

  /// Widget para campos de texto o número,
  /// reutiliza la propiedad 'valor' para mostrar/guardar su contenido.
  Widget _campoTexto(Map<String, dynamic> campo) {
    // Observa cómo usamos un TextEditingController
    // para controlar y mostrar la respuesta.
    final controller = TextEditingController(text: campo["valor"] ?? "");
    final esRequerido = campo["required"] ?? false;
    final tipoTeclado =
        (campo["tipo"] == "number") ? TextInputType.number : TextInputType.text;

    return TextField(
      controller: controller,
      keyboardType: tipoTeclado,
      decoration: InputDecoration(
        labelText: campo["etiqueta"],
        hintText: campo["placeholder"],
        border: const OutlineInputBorder(),
      ),
      onChanged: (valor) {
        campo["valor"] = valor; // Guardamos en la copia del JSON
      },
    );
  }

  /// Widget para dropdown (combobox)
  /// También maneja la propiedad 'valor' para el elemento seleccionado.
  Widget _campoDropdown(Map<String, dynamic> campo) {
    final opciones = List<String>.from(campo["opciones"] ?? []);
    final esRequerido = campo["required"] ?? false;
    String? valorSeleccionado = (campo["valor"] != "") ? campo["valor"] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campo["etiqueta"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: valorSeleccionado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: opciones.map((op) {
            return DropdownMenuItem<String>(
              value: op,
              child: Text(op),
            );
          }).toList(),
          onChanged: (nuevoValor) {
            setState(() {
              campo["valor"] = nuevoValor ?? "";
            });
          },
        ),
      ],
    );
  }

  /// Barra de navegación inferior para ir atrás y siguiente/guardar
  Widget _barraNavegacion(bool esUltimaSeccion) {
    final secciones = _jsonConValores!["secciones"] as List;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_indiceSeccionActual > 0)
            ElevatedButton(
              onPressed: _irSeccionAnterior,
              child: const Text("Atrás"),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // Primero validamos la sección actual
              if (!_validarSeccion(_indiceSeccionActual)) {
                return;
              }

              // Si es la última, guardamos las respuestas
              if (esUltimaSeccion) {
                _guardarEncuesta();
              } else {
                // De lo contrario, avanzamos
                _irSiguienteSeccion();
              }
            },
            child: Text(esUltimaSeccion ? "Guardar" : "Siguiente"),
          ),
        ],
      ),
    );
  }

  /// Verifica que todos los campos 'required' de la sección tengan un valor
  bool _validarSeccion(int indice) {
    final seccion = (_jsonConValores!["secciones"] as List)[indice];
    final campos = seccion["campos"] as List;

    for (var campo in campos) {
      if (campo["required"] == true) {
        final valor = (campo["valor"] ?? "").toString().trim();
        if (valor.isEmpty) {
          _mostrarError("El campo '${campo["etiqueta"]}' es requerido.");
          return false;
        }
      }
    }
    return true;
  }

  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error de validación"),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _irSiguienteSeccion() {
    setState(() {
      _indiceSeccionActual++;
    });
  }

  void _irSeccionAnterior() {
    setState(() {
      _indiceSeccionActual--;
    });
  }

  /// Finalmente, convertimos _jsonConValores en JSON y lo mostramos
  void _guardarEncuesta() {
    // Aquí podrías hacer una llamada a tu backend o guardarlo localmente.
    // De ejemplo, solo mostraremos el JSON resultante en un cuadro de diálogo.

    final String resultado = jsonEncode(_jsonConValores);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Encuesta Guardada"),
        content: SingleChildScrollView(
          child: Text(resultado),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}
