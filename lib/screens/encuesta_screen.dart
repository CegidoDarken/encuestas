import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaginaEncuesta extends StatefulWidget {
  const PaginaEncuesta({super.key});

  @override
  State<PaginaEncuesta> createState() => _PaginaEncuestaState();
}

class _PaginaEncuestaState extends State<PaginaEncuesta> {
  // Almacena el JSON original decodificado
  Map<String, dynamic>? _jsonOriginal;
  // Copia del JSON con la propiedad "valor" para cada campo
  Map<String, dynamic>? _jsonConValores;
  // Índice de la sección actual
  int _indiceSeccionActual = 0;

  @override
  void initState() {
    super.initState();
    _cargarYPrepararEncuesta();
  }

  // Carga el archivo JSON desde assets y crea una copia con "valor": ""
  Future<void> _cargarYPrepararEncuesta() async {
    try {
      final String jsonStr =
          await rootBundle.loadString('assets/data/encuesta.json');
      final data = jsonDecode(jsonStr);
      _jsonOriginal = data;

      final Map<String, dynamic> copia = {
        "titulo": data["titulo"],
        "secciones": [],
      };

      for (var seccion in data["secciones"]) {
        final Map<String, dynamic> nuevaSeccion = {
          "titulo": seccion["titulo"],
          "campos": [],
        };

        for (var campo in seccion["campos"]) {
          final Map<String, dynamic> nuevoCampo = {
            "tipo": campo["tipo"],
            "etiqueta": campo["etiqueta"],
            "placeholder": campo["placeholder"],
            "required": campo["required"] ?? false,
            if (campo["opciones"] != null) "opciones": campo["opciones"],
            "valor": "",
          };
          nuevaSeccion["campos"].add(nuevoCampo);
        }

        copia["secciones"].add(nuevaSeccion);
      }

      setState(() {
        _jsonConValores = copia;
      });
    } catch (e) {
      print('Error al cargar o parsear el JSON: $e');
      setState(() {
        _jsonConValores = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jsonConValores == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List secciones = _jsonConValores!["secciones"];
    final bool esUltimaSeccion = (_indiceSeccionActual == secciones.length - 1);
    final seccionActual = secciones[_indiceSeccionActual];

    return Scaffold(
      appBar: AppBar(
        title: Text(_jsonConValores!["titulo"] ?? "Encuesta"),
      ),
      body: _construirSeccion(seccionActual),
      bottomNavigationBar: _barraNavegacion(esUltimaSeccion),
    );
  }

  // Construye la sección actual
  Widget _construirSeccion(Map<String, dynamic> seccion) {
    final List campos = seccion["campos"];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seccion["titulo"] ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...List.generate(campos.length, (index) {
            final campo = campos[index];
            return Column(
              children: [
                _construirCampo(campo),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Retorna el widget correspondiente según el tipo de campo
  Widget _construirCampo(Map<String, dynamic> campo) {
    switch (campo["tipo"]) {
      case "text":
      case "number":
        return _campoTexto(campo);
      case "dropdown":
        return _campoDropdown(campo);
      case "radio":
        return _campoRadio(campo);
      case "datetime":
        return _campoDatetime(campo);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _campoTexto(Map<String, dynamic> campo) {
    final controller = TextEditingController(text: campo["valor"] ?? "");
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
        campo["valor"] = valor;
      },
    );
  }

  Widget _campoDropdown(Map<String, dynamic> campo) {
    final List<String> opciones = List<String>.from(campo["opciones"] ?? []);
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

  Widget _campoRadio(Map<String, dynamic> campo) {
    final List<String> opciones = List<String>.from(campo["opciones"] ?? []);
    String? valorSeleccionado = (campo["valor"] != "") ? campo["valor"] : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          campo["etiqueta"],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...opciones.map((op) {
          return RadioListTile<String>(
            title: Text(op),
            value: op,
            groupValue: valorSeleccionado,
            onChanged: (value) {
              setState(() {
                campo["valor"] = value ?? "";
              });
            },
          );
        }),
      ],
    );
  }

  Widget _campoDatetime(Map<String, dynamic> campo) {
    final controller = TextEditingController(text: campo["valor"] ?? "");
    return GestureDetector(
      onTap: () async {
        DateTime initialDate = DateTime.now();
        if (campo["valor"] != null && campo["valor"].toString().isNotEmpty) {
          try {
            List<String> parts = campo["valor"].toString().split('/');
            if (parts.length == 3) {
              initialDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } catch (_) {}
        }
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          String formatted =
              "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          setState(() {
            campo["valor"] = formatted;
          });
          controller.text = formatted;
        }
      },
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: campo["etiqueta"],
            hintText: campo["placeholder"],
            border: const OutlineInputBorder(),
          ),
        ),
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
              onPressed: _irSeccionAnterior,
              child: const Text("Atrás"),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (!_validarSeccion(_indiceSeccionActual)) return;
              if (esUltimaSeccion) {
                _guardarEncuesta();
              } else {
                _irSiguienteSeccion();
              }
            },
            child: Text(esUltimaSeccion ? "Guardar" : "Siguiente"),
          ),
        ],
      ),
    );
  }

  bool _validarSeccion(int indice) {
    final List secciones = _jsonConValores!["secciones"];
    final Map<String, dynamic> seccion = secciones[indice];
    final List campos = seccion["campos"];
    for (var campo in campos) {
      if (campo["required"] == true) {
        final String valor = (campo["valor"] ?? "").trim();
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

  // Al guardar, mostramos el resultado y reiniciamos la encuesta al cerrar el diálogo.
  void _guardarEncuesta() {
    final String resultado = jsonEncode(_jsonConValores);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Encuesta Guardada"),
        content: SingleChildScrollView(
          child: null,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reiniciarEncuesta();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // Reinicia la encuesta volviendo a la primera sección y limpiando los campos.
  void _reiniciarEncuesta() {
    setState(() {
      _indiceSeccionActual = 0;
      for (var seccion in _jsonConValores!["secciones"]) {
        for (var campo in seccion["campos"]) {
          campo["valor"] = "";
        }
      }
    });
  }
}
