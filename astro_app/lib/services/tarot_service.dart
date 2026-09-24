import 'dart:convert';
import 'package:http/http.dart' as http;
import 'astro_api_service.dart';

class TarotService {
  final String _baseUrl = '${AstroApiService.baseUrl}/tarot';

  Future<Map<String, dynamic>> getDailyReading(double timezoneOffset) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/daily'),
      headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
      body: jsonEncode({'timezone': timezoneOffset}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get daily reading: ${response.body}');
  }

  Future<Map<String, dynamic>> drawSpread(String spreadEndpoint, {String? question, String? seed}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$spreadEndpoint'),
        headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
        body: jsonEncode({
          if (question != null) 'question': question,
          if (seed != null) 'seed': seed,
        }),
      ).timeout(const Duration(seconds: 4)); // Reduced timeout for faster fallback
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to draw spread: ${response.body}');
    } catch (e) {
      // Return a beautiful mocked reading for physical devices without a backend
      int requiredCards = 1;
      if (spreadEndpoint == 'three-card') requiredCards = 3;
      else if (spreadEndpoint == 'love' || spreadEndpoint == 'career') requiredCards = 5;
      else if (spreadEndpoint == 'celtic-cross') requiredCards = 10;
      else if (spreadEndpoint == 'year-ahead') requiredCards = 12;

      final bool isSingle = requiredCards == 1;
      
      // A small pool of mock cards to draw from so the reading is always random!
      final List<Map<String, dynamic>> mockCardPool = [
        {'name': 'The Star', 'name_short': 'ar17', 'value': '17', 'value_int': 17, 'type': 'major', 'meaning_up': 'Hope, faith, purpose, renewal, spirituality', 'desc': 'The Star brings hope, renewed power, and strength to carry on with life. Following the sudden upheaval of The Tower, The Star reminds you that the universe is abundant and you are blessed. It indicates a period of profound spiritual healing, where you strip away limiting beliefs and open yourself up to the cosmos. Trust that your path is guided by divine light.'},
        {'name': 'The Magician', 'name_short': 'ar01', 'value': '1', 'value_int': 1, 'type': 'major', 'meaning_up': 'Manifestation, resourcefulness, power, inspired action', 'desc': 'The Magician represents your ability to manifest your desires into reality. He stands with one arm pointing to the heavens and the other to the earth, acting as a bridge between the spiritual and material worlds. You possess all the tools, resources, and energy you need to succeed. This is a powerful time for focused action, willpower, and transforming your visions into tangible results.'},
        {'name': 'The Sun', 'name_short': 'ar19', 'value': '19', 'value_int': 19, 'type': 'major', 'meaning_up': 'Positivity, fun, warmth, success, vitality', 'desc': 'The Sun represents supreme success, radiance, and abundance. It gives you strength and tells you that no matter where you go or what you do, your positive and radiant energy will follow you. This card signifies a time of joy, optimism, and material success. Like the sun breaking through the clouds, you will experience clarity, warmth, and a deep sense of gratitude for the beauty in your life.'},
        {'name': 'The Fool', 'name_short': 'ar00', 'value': '0', 'value_int': 0, 'type': 'major', 'meaning_up': 'New beginnings, innocence, spontaneity', 'desc': 'The Fool represents the ultimate leap of faith. It marks the very beginning of a journey, full of infinite potential, unbridled curiosity, and a complete lack of fear. You are being called to embrace the unknown, to trust in the universe, and to let go of preconceived expectations. While others may see your choices as naive, your pure spirit and willingness to take a risk will lead to unexpected growth and adventure.'},
        {'name': 'The Moon', 'name_short': 'ar18', 'value': '18', 'value_int': 18, 'type': 'major', 'meaning_up': 'Illusion, fear, anxiety, subconscious, intuition', 'desc': 'The Moon acts as a mirror to your subconscious, revealing hidden truths, deeply buried fears, and illusions. Things may not be as they seem right now; shadows obscure the path forward. You are being asked to rely not on logic, but on your deepest intuition and gut feelings. It is a time to explore your dreams, confront your anxieties, and allow your inner voice to guide you through the darkness and uncertainty.'},
        {'name': 'The Empress', 'name_short': 'ar03', 'value': '3', 'value_int': 3, 'type': 'major', 'meaning_up': 'Femininity, beauty, nature, nurturing, abundance', 'desc': 'The Empress signifies a profound connection with the divine feminine. She embodies fertility, unconditional love, deep nurturing, and material abundance. This card suggests that you are surrounded by the beauty of nature and the comforts of the physical world. It is a time to indulge your senses, nurture your creative projects, and embrace the compassionate, motherly energy within you to bring new life and ideas into being.'},
        {'name': 'The Emperor', 'name_short': 'ar04', 'value': '4', 'value_int': 4, 'type': 'major', 'meaning_up': 'Authority, establishment, structure, a father figure', 'desc': 'The Emperor represents the ultimate patriarchal archetype—structure, rules, law, and steadfast authority. He builds foundations that withstand the test of time. When this card appears, it calls for discipline, strategic planning, and rational thought over emotional responses. You are being encouraged to take charge, assert your leadership, and establish boundaries that protect your goals and bring stability to your environment.'},
        {'name': 'The High Priestess', 'name_short': 'ar02', 'value': '2', 'value_int': 2, 'type': 'major', 'meaning_up': 'Intuition, sacred knowledge, divine feminine', 'desc': 'The High Priestess sits at the gate before the great Mystery. She is the guardian of the subconscious mind and the keeper of ancient, sacred knowledge. She tells you to retreat from the noise of the external world and listen closely to your inner wisdom. There is a deep, quiet power within you that holds the answers you seek. Trust your instincts, pay attention to your dreams, and allow the unseen to guide you.'},
        {'name': 'The Lovers', 'name_short': 'ar06', 'value': '6', 'value_int': 6, 'type': 'major', 'meaning_up': 'Love, harmony, relationships, values alignment', 'desc': 'The Lovers represent the pinnacle of deep, authentic connection and harmony. While often indicating a powerful romantic union, this card also speaks to fundamental choices and the alignment of your personal values. It calls for complete honesty, vulnerability, and integration of opposing forces within yourself. You are at a crossroads where a significant choice must be made, one that requires you to stay completely true to your heart and moral compass.'},
        {'name': 'The Chariot', 'name_short': 'ar07', 'value': '7', 'value_int': 7, 'type': 'major', 'meaning_up': 'Control, willpower, success, action, determination', 'desc': 'The Chariot is a profound symbol of overcoming adversity through sheer willpower, control, and unbreakable determination. It signifies a decisive victory that is achieved not by luck, but by maintaining intense focus and harnessing conflicting forces in your life. You are the driver of your destiny; by staying disciplined and refusing to be derailed by distractions or obstacles, you will triumph and propel yourself rapidly toward your goals.'},
        {'name': 'Strength', 'name_short': 'ar08', 'value': '8', 'value_int': 8, 'type': 'major', 'meaning_up': 'Strength, courage, persuasion, influence, compassion', 'desc': 'Unlike the brute force of The Chariot, Strength represents quiet, inner resilience, boundless compassion, and emotional maturity. It shows the taming of the beast within through gentleness and persuasion rather than dominance. You are being called to face challenges with grace, patience, and a calm heart. Your true power lies in your ability to endure, to forgive, and to handle difficult situations with unwavering love and quiet courage.'},
        {'name': 'Wheel Of Fortune', 'name_short': 'ar10', 'value': '10', 'value_int': 10, 'type': 'major', 'meaning_up': 'Good luck, karma, life cycles, destiny, a turning point', 'desc': 'The Wheel of Fortune reminds you that the wheel is constantly turning—what goes up must come down, and what is down will rise again. It speaks to the inevitability of change, the cycles of karma, and the unpredictable forces of destiny. You are entering a turning point where external events, beyond your control, will shift the landscape of your life. Embrace the change, trust in the divine timing of the universe, and know that luck is on your side.'}
      ];
      
      mockCardPool.shuffle(); // Shuffle the mock pool!

      return {
        'spread_type': spreadEndpoint.replaceAll('-', ' ').toUpperCase(),
        'positions': List.generate(requiredCards, (index) {
          final card = mockCardPool[index % mockCardPool.length];
          return {
            'position_name': isSingle ? 'Your Answer' : (index == 0 ? 'Past' : (index == 1 ? 'Present' : (index == 2 ? 'Future' : 'Position ${index + 1}'))),
            'meaning': isSingle ? 'The core of your situation.' : (index == 0 ? 'The foundation of the situation.' : (index == 1 ? 'Where you are right now.' : (index == 2 ? 'The most likely outcome.' : 'Further guidance and clarity.'))),
            'card': card
          };
        })
      };
    }
  }

  Future<Map<String, dynamic>> getAstroTarotReading(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/astro'),
      headers: {'Content-Type': 'application/json', 'X-User-Id': 'test_user'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get astro tarot reading: ${response.body}');
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
        headers: {'X-User-Id': 'test_user'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['history'];
      }
      return [];
    } catch (e) {
      return []; // Return empty list gracefully instead of crashing the UI
    }
  }

  Future<List<dynamic>> getLibrary() async {
    final response = await http.get(Uri.parse('$_baseUrl/cards'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['cards'];
    }
    throw Exception('Failed to load library');
  }
}
