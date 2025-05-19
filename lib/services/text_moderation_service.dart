import 'package:http/http.dart' as http;

class TextModerationService {
  static Future<bool> isProfane(String word) async {
    try {
      final url = Uri.parse('https://www.purgomalum.com/service/containsprofanity?text=$word');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return response.body == 'true'; // Returns true if profane, false otherwise.
      } else {
        print('API Error: ${response.statusCode}');
        return false; // Fallback if API fails
      }
    } catch (e) {
      print('Error checking profanity: $e');
      return false; // Fallback on network errors
    }
  }

  static Future<String> filterProfanity(String text) async {
    try {
      final url = Uri.parse('https://www.purgomalum.com/service/json?text=$text');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // The API returns a JSON with the filtered text
        final filteredText = response.body;
        return filteredText;
      } else {
        print('API Error: ${response.statusCode}');
        return text; // Return original text if API fails
      }
    } catch (e) {
      print('Error filtering profanity: $e');
      return text; // Return original text on network errors
    }
  }
} 