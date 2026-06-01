import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyBK0DGHdeV2x9b0Xag8_TgGK8_EubFYys0';
  print('Testing Gemini API...');
  
  try {
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    
    final content = [Content.text('Hello!')];
    final response = await model.generateContent(content);
    print('Response: ${response.text}');
    exit(0);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
