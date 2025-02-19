import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String apiUrl = "https://1.conteosa.com/api/encuestas/";

  Future<List<dynamic>> obtenerEncuestas() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Devuelve la lista de encuestas
    } else {
      throw Exception("Error al obtener encuestas");
    }
  }
}
