import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  const apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  print('Testing Gemini API...');
  
  try {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
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
