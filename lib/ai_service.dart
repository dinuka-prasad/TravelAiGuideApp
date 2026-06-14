import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 🔑  GEMINI API KEY SETUP
/// ─────────────────────────────────────────────────────────────────────────────
///  1. Go to https://aistudio.google.com/app/apikey
///  2. Sign in with your Google account
///  3. Click "Create API key" → copy the key
///  4. Paste your new key below, replacing the placeholder.
/// ─────────────────────────────────────────────────────────────────────────────
const String _geminiApiKey =
    'YOUR_GEMINI_API_KEY_HERE'; 


// ─── DO NOT EDIT BELOW THIS LINE ─────────────────────────────────────────────

const _keyPlaceholder = 'YOUR_GEMINI_API_KEY_HERE';

/// Calls the Gemini API and returns the AI response text.
Future<String> callAiApi({
  required String systemPrompt,
  required String userMessage,
  int maxTokens = 2000,
}) async {
  // Guard: key not set
  if (_geminiApiKey.trim().isEmpty || _geminiApiKey == _keyPlaceholder) {
    throw Exception(
      '🔑 Gemini API key is missing!\n\n'
      'Steps to fix:\n'
      '1. Visit https://aistudio.google.com/app/apikey\n'
      '2. Sign in & click "Create API key"\n'
      '3. Copy the key (starts with AIza…)\n'
      '4. Open  lib/ai_service.dart\n'
      '5. Replace YOUR_GEMINI_API_KEY_HERE with your key\n'
      '6. Hot-restart the app\n\n'
      'The Gemini API is FREE for personal use.',
    );
  }

  final List<String> modelsToTry = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash-lite',
    'gemini-3.5-flash',
  ];

  dynamic lastException;

  for (final modelName in modelsToTry) {
    try {
      debugPrint('Attempting Gemini API call with model: $modelName');
      final model = GenerativeModel(
        model: modelName,
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(
          maxOutputTokens: maxTokens,
          temperature: 0.7,
        ),
        requestOptions: const RequestOptions(apiVersion: 'v1beta'),
        systemInstruction: Content.system(systemPrompt),
      );

      final content = [Content.text(userMessage)];
      final response = await model.generateContent(content).timeout(const Duration(seconds: 15));
      final text = response.text;

      if (text != null && text.trim().isNotEmpty) {
        return text;
      }
    } catch (e) {
      debugPrint('Error with model $modelName: $e');
      lastException = e;
      
      // If it's an invalid API key, no point trying other models
      if (e is GenerativeAIException) {
        final msg = e.message.toLowerCase();
        if (msg.contains('api_key_invalid') || msg.contains('api key not valid')) {
          throw Exception(
            '❌ Invalid API key.\n\n'
            'Your key in ai_service.dart is not recognised by Google.\n'
            'Please generate a fresh key at:\n'
            'https://aistudio.google.com/app/apikey',
          );
        }
      }
    }
  }

  if (lastException != null) {
    if (lastException is GenerativeAIException) {
      final msg = lastException.message.toLowerCase();
      if (msg.contains('quota') || msg.contains('resource_exhausted')) {
        throw Exception(
          '⏳ API quota exceeded.\n\n'
          'You have hit the free-tier limit. '
          'Please wait a minute and try again.',
        );
      } else if (msg.contains('permission_denied')) {
        throw Exception(
          '🚫 Permission denied.\n\n'
          'Make sure the Generative Language API is enabled in your '
          'Google Cloud project:\n'
          'https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com',
        );
      }
      throw Exception('Gemini Server Error: ${lastException.message}');
    }
    throw Exception('Failed to connect to AI: $lastException');
  }

  throw Exception('Failed to get response from Gemini.');
}
