import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GeminiResult {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String? rawResponse;
  final bool isLabelScan;

  GeminiResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.rawResponse,
    this.isLabelScan = false,
  });
}

class GeminiService {
  static final GeminiService instance = GeminiService._init();
  GeminiService._init();

  final _picker = ImagePicker();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/'
      'gemini-1.5-flash:generateContent';

  // ── Pick image from camera ────────────────────────────────
  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ── Pick image from gallery ───────────────────────────────
  Future<File?> pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // ── Analyse food photo ────────────────────────────────────
  Future<GeminiResult?> analyseFood(File imageFile) async {
    final prompt = '''
You are a nutrition expert. Analyse this photo of food and provide calorie and macro estimates.

Respond ONLY with a JSON object in this exact format, no other text:
{
  "food_name": "name of the food or meal",
  "calories": estimated total calories as integer,
  "protein_g": estimated protein in grams as integer,
  "carbs_g": estimated carbohydrates in grams as integer,
  "fat_g": estimated fat in grams as integer
}

Base your estimates on a typical serving size of what is visible in the image.
If you cannot identify food in the image, return calories as 0.
''';

    return await _callGemini(imageFile, prompt, isLabel: false);
  }

  // ── Scan nutrition label ──────────────────────────────────
  Future<GeminiResult?> scanLabel(File imageFile) async {
    final prompt = '''
You are a nutrition label reader. Extract the nutritional information from this nutrition label image.

Respond ONLY with a JSON object in this exact format, no other text:
{
  "food_name": "product name if visible, otherwise 'Scanned product'",
  "calories": calories per serving as integer,
  "protein_g": protein per serving in grams as integer,
  "carbs_g": carbohydrates per serving in grams as integer,
  "fat_g": fat per serving in grams as integer
}

Use the "per serving" values, not per 100g.
If you cannot read the label clearly, return calories as 0.
''';

    return await _callGemini(imageFile, prompt, isLabel: true);
  }

  // ── Core Gemini API call ──────────────────────────────────
  Future<GeminiResult?> _callGemini(
    File imageFile,
    String prompt, {
    required bool isLabel,
  }) async {
    try {
      final imageBytes  = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final mimeType    = 'image/jpeg';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 256,
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return null;
      }

      final responseData = jsonDecode(response.body);
      final text = responseData['candidates']?[0]?['content']?['parts']?[0]
          ?['text'] as String?;

      if (text == null) return null;

      // Clean the response — remove markdown code blocks if present
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(cleaned);

      return GeminiResult(
        foodName: parsed['food_name'] as String? ?? 'Unknown food',
        calories: (parsed['calories'] as num?)?.toInt() ?? 0,
        protein:  (parsed['protein_g'] as num?)?.toInt() ?? 0,
        carbs:    (parsed['carbs_g'] as num?)?.toInt() ?? 0,
        fat:      (parsed['fat_g'] as num?)?.toInt() ?? 0,
        rawResponse: text,
        isLabelScan: isLabel,
      );
    } catch (e) {
      return null;
    }
  }
}
