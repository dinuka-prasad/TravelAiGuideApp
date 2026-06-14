import 'dart:convert';
import 'dart:io';

void main() async {
  const apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    final map = jsonDecode(responseBody) as Map<String, dynamic>;
    final models = map['models'] as List<dynamic>;
    for (var m in models) {
      print(m['name']);
    }
    exit(0);
  } catch (e) {
    print('Error: ' + e.toString());
    exit(1);
  }
}
