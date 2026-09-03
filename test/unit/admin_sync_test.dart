import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodsave/core/services/admin_sync_service.dart';
import 'package:foodsave/features/recipes/presentation/screens/recipes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdminSyncService Offline & Fallback Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Falls back to sample recipes when API is unreachable without throwing', () async {
      final sample = [
        const RecipeModel(
          id: 'test-1',
          title: 'Test Dal Tadka',
          category: 'Grains & Pulses',
          description: 'A test recipe',
          imageUrl: 'https://example.com/image.jpg',
          youtubeId: 'abc12345',
          youtubeUrl: 'https://youtube.com/watch?v=abc12345',
          prepTime: '15 mins',
          difficulty: 'Easy',
          calories: 250,
          requiredIngredients: ['Lentils', 'Ghee'],
          instructions: ['Step 1', 'Step 2'],
        ),
      ];

      final result = await AdminSyncService.fetchRecipes(fallbackRecipes: sample);
      expect(result, isNotEmpty);
      expect(result.first.title, equals('Test Dal Tadka'));
    });

    test('Correctly parses and loads recipes from SharedPreferences cache', () async {
      final mockApiResponse = {
        'status': 'success',
        'count': 1,
        'data': [
          {
            'id': 99,
            'title': 'Pantry Bread Upma',
            'category_name': 'Flour & Baking',
            'description': 'Delicious savory bread bites',
            'image_url': 'https://example.com/bread.jpg',
            'youtube_id': 'xyz987',
            'youtube_url': 'https://youtube.com/watch?v=xyz987',
            'prep_time': '10 mins',
            'difficulty': 'Easy',
            'calories': 180,
            'ingredient_names': ['Bread', 'Mustard Seeds', 'Curry Leaves'],
            'instruction_steps': ['Tear bread', 'Sauté spices', 'Mix together'],
          }
        ]
      };

      SharedPreferences.setMockInitialValues({
        'cached_admin_recipes_json': jsonEncode(mockApiResponse),
      });

      final result = await AdminSyncService.fetchRecipes(fallbackRecipes: []);
      expect(result.length, equals(1));
      expect(result.first.title, equals('Pantry Bread Upma'));
      expect(result.first.requiredIngredients, contains('Bread'));
      expect(result.first.instructions.length, equals(3));
    });

    test('fetchAnnouncements handles offline mode safely without throwing', () async {
      final announcements = await AdminSyncService.fetchAnnouncements();
      expect(announcements, isA<List>());
    });
  });
}
