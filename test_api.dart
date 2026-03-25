import 'package:http/http.dart' as http;

void main() async {
  try {
    var r = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/attendance/all-attendances'),
      headers: {'Accept': 'application/json'},
    );
    print(r.body);
  } catch (e) {
    print(e);
  }
}
