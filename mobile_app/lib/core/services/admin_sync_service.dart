import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/recipes/presentation/screens/recipes_screen.dart';

/// Service responsible for syncing recipes, categories, and announcements 
/// from the local PHP/MySQL Admin Panel REST API to the mobile app.
/// Completely offline-safe: seamlessly falls back to local cache or presets if offline.
class AdminSyncService {
  static const String _cachedRecipesKey = 'cached_admin_recipes_json';
  static const String _cachedAnnouncementsKey = 'cached_admin_announcements_json';

  // Candidate base URLs to auto-detect localhost depending on execution environment:
  // - 10.0.2.2 for Android emulator
  // - localhost:8080 for ADB reverse over USB cable
  // - 192.168.31.187 for local Wi-Fi development
  // - localhost/127.0.0.1 for desktop/web
  // Candidate base URLs to auto-detect localhost depending on execution environment:
  // - 192.168.31.187 for local Wi-Fi development & physical devices
  // - localhost / 127.0.0.1 for desktop/web
  // - 10.0.2.2 for Android emulator
  static final List<String> _candidateBaseUrls = [
    'http://192.168.31.187/leftover/admin',
    'http://192.168.31.187:8000',
    'http://192.168.31.187/admin',
    'http://192.168.31.187/leftover-food/admin',
    'http://localhost/leftover/admin',
    'http://127.0.0.1/leftover/admin',
    'http://10.0.2.2/leftover/admin',
    'http://localhost:8000',
    'http://127.0.0.1:8000',
    'http://10.0.2.2:8000',
    'http://localhost/admin',
    'http://127.0.0.1/admin',
    'http://10.0.2.2/admin',
    'http://localhost/leftover-food/admin',
    'http://127.0.0.1/leftover-food/admin',
    'http://10.0.2.2/leftover-food/admin',
    'http://127.0.0.1:8080/admin',
    'http://localhost:8080/admin',
  ];

  static String? _resolvedBaseUrl;
  static String? _customBaseUrl;

  /// Sets a manual custom base URL override
  static void setCustomBaseUrl(String? url) {
    _customBaseUrl = url?.trim().replaceAll(RegExp(r'/+$'), '');
    _resolvedBaseUrl = _customBaseUrl;
  }

  /// Clears the resolved base URL cache
  static void clearResolvedBaseUrl() {
    _resolvedBaseUrl = null;
  }

  /// Discovers the active working REST API endpoint
  static Future<String?> getWorkingBaseUrl() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl;
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl;
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);

    for (final candidate in _candidateBaseUrls) {
      try {
        final statusUri = Uri.parse('$candidate/api/status.php');
        final request = await client.getUrl(statusUri).timeout(const Duration(seconds: 1));
        final response = await request.close().timeout(const Duration(seconds: 1));
        if (response.statusCode == 200) {
          _resolvedBaseUrl = candidate;
          client.close();
          debugPrint('AdminSyncService: Connected to active endpoint $_resolvedBaseUrl');
          return candidate;
        }
      } catch (_) {
        try {
          final uri = Uri.parse('$candidate/api/categories.php');
          final request = await client.getUrl(uri).timeout(const Duration(seconds: 1));
          final response = await request.close().timeout(const Duration(seconds: 1));
          if (response.statusCode == 200) {
            _resolvedBaseUrl = candidate;
            client.close();
            debugPrint('AdminSyncService: Connected to active endpoint $_resolvedBaseUrl');
            return candidate;
          }
        } catch (_) {}
      }
    }
    client.close();
    return null;
  }

  /// Pings the Admin server to check connectivity and response time
  static Future<Map<String, dynamic>> pingServer([String? customUrl]) async {
    final targetUrl = customUrl ?? await getWorkingBaseUrl();
    if (targetUrl == null) {
      return {
        'connected': false,
        'url': null,
        'latencyMs': 0,
        'message': 'No active Admin server found on localhost or network',
      };
    }

    final stopwatch = Stopwatch()..start();
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      
      // Try status.php first, fallback to categories.php
      Uri uri = Uri.parse('$targetUrl/api/status.php');
      var request = await client.getUrl(uri).timeout(const Duration(seconds: 2));
      var response = await request.close().timeout(const Duration(seconds: 2));
      
      if (response.statusCode != 200) {
        uri = Uri.parse('$targetUrl/api/categories.php');
        request = await client.getUrl(uri).timeout(const Duration(seconds: 2));
        response = await request.close().timeout(const Duration(seconds: 2));
      }
      
      stopwatch.stop();
      client.close();

      if (response.statusCode == 200) {
        return {
          'connected': true,
          'url': targetUrl,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': 'Admin Server connected (${stopwatch.elapsedMilliseconds}ms)',
        };
      } else {
        return {
          'connected': false,
          'url': targetUrl,
          'latencyMs': stopwatch.elapsedMilliseconds,
          'message': 'Admin Server returned HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      stopwatch.stop();
      return {
        'connected': false,
        'url': targetUrl,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'message': 'Connection failed: $e',
      };
    }
  }

  /// Fetches recipes from the Admin API.
  /// If online, updates the local cache and returns fresh recipes.
  /// If offline or on error, returns locally cached recipes or default built-in recipes.
  static Future<List<RecipeModel>> fetchRecipes({
    required List<RecipeModel> fallbackRecipes,
  }) async {
    try {
      final baseUrl = await getWorkingBaseUrl();
      if (baseUrl != null) {
        final client = HttpClient();
        final uri = Uri.parse('$baseUrl/api/recipes.php');
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
        final response = await request.close().timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;

          if (data['status'] == 'success' && data['data'] is List) {
            final list = data['data'] as List<dynamic>;
            final parsedRecipes = <RecipeModel>[];

            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final id = 'rec-${item['id']}';
                final title = item['title']?.toString() ?? 'Recipe';
                final category = item['category_name']?.toString() ?? 'General';
                final description = item['description']?.toString() ?? '';
                final imageUrl = item['image_url']?.toString() ?? '';
                final youtubeId = item['youtube_id']?.toString() ?? '';
                final youtubeUrl = item['youtube_url']?.toString() ?? '';
                final prepTime = item['prep_time']?.toString() ?? '15 mins';
                final difficulty = item['difficulty']?.toString() ?? 'Easy';
                final calories = int.tryParse(item['calories']?.toString() ?? '0') ?? 0;

                // Ingredients
                final requiredIngredients = <String>[];
                if (item['ingredients'] is List) {
                  for (final ing in item['ingredients']) {
                    if (ing is Map<String, dynamic>) {
                      final name = ing['ingredient_name']?.toString();
                      if (name != null && name.isNotEmpty) {
                        requiredIngredients.add(name);
                      }
                    }
                  }
                } else if (item['ingredient_names'] is List) {
                  for (final name in item['ingredient_names']) {
                    if (name != null && name.toString().isNotEmpty) {
                      requiredIngredients.add(name.toString());
                    }
                  }
                }

                // Instructions
                final instructions = <String>[];
                if (item['instruction_steps'] is List && (item['instruction_steps'] as List).isNotEmpty) {
                  for (final step in item['instruction_steps']) {
                    if (step != null && step.toString().isNotEmpty) {
                      instructions.add(step.toString());
                    }
                  }
                } else if (item['instructions'] != null) {
                  final raw = item['instructions'].toString();
                  instructions.addAll(raw.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty));
                }

                parsedRecipes.add(RecipeModel(
                  id: id,
                  title: title,
                  category: category,
                  description: description,
                  imageUrl: imageUrl,
                  youtubeId: youtubeId,
                  youtubeUrl: youtubeUrl,
                  prepTime: prepTime,
                  difficulty: difficulty,
                  calories: calories,
                  requiredIngredients: requiredIngredients,
                  instructions: instructions,
                ));
              }
            }

            if (parsedRecipes.isNotEmpty) {
              // Cache to SharedPreferences for instant offline access
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_cachedRecipesKey, body);
              return parsedRecipes;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AdminSyncService: Error fetching recipes from API ($e), using cache.');
    }

    // Attempt to load from offline cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString(_cachedRecipesKey);
      if (cachedBody != null && cachedBody.isNotEmpty) {
        final data = jsonDecode(cachedBody) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['data'] is List) {
          final list = data['data'] as List<dynamic>;
          final cachedRecipes = <RecipeModel>[];

          for (final item in list) {
            if (item is Map<String, dynamic>) {
              cachedRecipes.add(RecipeModel(
                id: 'rec-${item['id']}',
                title: item['title']?.toString() ?? 'Recipe',
                category: item['category_name']?.toString() ?? 'General',
                description: item['description']?.toString() ?? '',
                imageUrl: item['image_url']?.toString() ?? '',
                youtubeId: item['youtube_id']?.toString() ?? '',
                youtubeUrl: item['youtube_url']?.toString() ?? '',
                prepTime: item['prep_time']?.toString() ?? '15 mins',
                difficulty: item['difficulty']?.toString() ?? 'Easy',
                calories: int.tryParse(item['calories']?.toString() ?? '0') ?? 0,
                requiredIngredients: (item['ingredient_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
                instructions: (item['instruction_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              ));
            }
          }

          if (cachedRecipes.isNotEmpty) {
            return cachedRecipes;
          }
        }
      }
    } catch (_) {}

    // Complete offline fallback to built-in recipes
    return fallbackRecipes;
  }

  /// Fetches active announcements from the Admin API.
  static Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    try {
      final baseUrl = await getWorkingBaseUrl();
      if (baseUrl != null) {
        final client = HttpClient();
        final uri = Uri.parse('$baseUrl/api/announcements.php');
        final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
        final response = await request.close().timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['status'] == 'success' && data['data'] is List) {
            final list = (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cachedAnnouncementsKey, body);
            return list;
          }
        }
      }
    } catch (_) {}

    // Fallback to cached announcements
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBody = prefs.getString(_cachedAnnouncementsKey);
      if (cachedBody != null && cachedBody.isNotEmpty) {
        final data = jsonDecode(cachedBody) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['data'] is List) {
          return (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}

    return [];
  }
}
