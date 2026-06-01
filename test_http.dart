import 'dart:convert';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyBK0DGHdeV2x9b0Xag8_TgGK8_EubFYys0';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=' + apiKey);
  
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('Status Code: ' + response.statusCode.toString());
    print('Response: ' + responseBody);
    exit(0);
  } catch (e) {
    print('Error: ' + e.toString());
    exit(1);
  }
}
