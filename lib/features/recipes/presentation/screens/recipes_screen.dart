import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../../../core/services/admin_sync_service.dart';

class RecipeModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final String youtubeId;
  final String youtubeUrl;
  final String prepTime;
  final String difficulty;
  final int calories;
  final List<String> requiredIngredients;
  final List<String> instructions;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.youtubeId,
    required this.youtubeUrl,
    required this.prepTime,
    required this.difficulty,
    required this.calories,
    required this.requiredIngredients,
    required this.instructions,
  });
}

final _sampleRecipes = [
  const RecipeModel(
    id: 'rec-1',
    title: 'Aromatic Tadka Dal & Basmati Rice',
    category: 'Main Courses',
    description: 'Comforting yellow lentils tempered with cumin, turmeric, and pure ghee served alongside fluffy basmati rice.',
    imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'DAP33YtKmgw',
    youtubeUrl: 'https://www.youtube.com/watch?v=DAP33YtKmgw',
    prepTime: '20 mins',
    difficulty: 'Easy',
    calories: 340,
    requiredIngredients: ['Basmati Rice', 'Red Lentils', 'Turmeric Powder', 'Cumin', 'Pure Ghee', 'Salt'],
    instructions: [
      'Rinse basmati rice and red lentils under cold water until clear.',
      'Simmer red lentils with turmeric powder and salt until tender and creamy.',
      'In a small pan, heat pure ghee and sizzle cumin until aromatic.',
      'Pour the hot spiced ghee tadka over the dal and serve hot with steamed basmati rice.',
    ],
  ),
  const RecipeModel(
    id: 'rec-2',
    title: 'Artisan Toasted Sourdough with Olive Oil',
    category: 'Breakfast',
    description: 'Crispy golden toasted sourdough slices drizzled with cold-pressed olive oil, cracked black pepper, and sea salt.',
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'fFq2sL_Ea_Y',
    youtubeUrl: 'https://www.youtube.com/watch?v=fFq2sL_Ea_Y',
    prepTime: '8 mins',
    difficulty: 'Easy',
    calories: 210,
    requiredIngredients: ['Sourdough Bread', 'Olive Oil', 'Salt', 'Black Pepper'],
    instructions: [
      'Thickly slice the sourdough bread into hearty pieces.',
      'Toast in a pan or toaster until golden and crunchy on the crust.',
      'Generously drizzle with cold-pressed olive oil while still warm.',
      'Finish with freshly cracked black pepper and a pinch of salt.',
    ],
  ),
  const RecipeModel(
    id: 'rec-3',
    title: 'Classic Aglio e Olio Penne Pasta',
    category: 'Quick Meals',
    description: 'Simple Italian pantry pasta tossed with fragrant olive oil, black pepper, and sea salt.',
    imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'bJUiWdM__Qw',
    youtubeUrl: 'https://www.youtube.com/watch?v=bJUiWdM__Qw',
    prepTime: '15 mins',
    difficulty: 'Easy',
    calories: 380,
    requiredIngredients: ['Pasta', 'Olive Oil', 'Black Pepper', 'Salt', 'Garlic'],
    instructions: [
      'Bring a pot of well-salted water to a boil and cook penne until al dente.',
      'Reserve 1/4 cup of starchy pasta water before draining.',
      'Gently warm olive oil and black pepper in a large pan.',
      'Toss pasta into the oil with reserved water until glossy and emulsified.',
    ],
  ),
  const RecipeModel(
    id: 'rec-4',
    title: 'Spiced Warm Chai & Digestive Biscuits',
    category: 'Snacks & Drinks',
    description: 'Rich freshly brewed tea with creamy whole milk and cane sugar, served with crisp digestive biscuits.',
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'd1lM047vR-Y',
    youtubeUrl: 'https://www.youtube.com/watch?v=d1lM047vR-Y',
    prepTime: '6 mins',
    difficulty: 'Easy',
    calories: 190,
    requiredIngredients: ['Whole Milk', 'Tea Leaves', 'Cane Sugar', 'Digestive Biscuits'],
    instructions: [
      'Bring water to a simmer and steep tea leaves for 3-4 minutes.',
      'Pour in whole milk and cane sugar, bringing to a gentle rolling boil.',
      'Strain into a cup and serve warm alongside crisp digestive biscuits.',
    ],
  ),
  const RecipeModel(
    id: 'rec-5',
    title: 'Golden Turmeric Milk & Honey Oats',
    category: 'Breakfast',
    description: 'Warm wholesome rolled oats simmered in creamy milk infused with antioxidant turmeric powder and honey.',
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'k4s6Z0m_m4s',
    youtubeUrl: 'https://www.youtube.com/watch?v=k4s6Z0m_m4s',
    prepTime: '10 mins',
    difficulty: 'Easy',
    calories: 280,
    requiredIngredients: ['Rolled Oats', 'Whole Milk', 'Turmeric Powder', 'Sugar'],
    instructions: [
      'Combine rolled oats and whole milk in a small saucepan over medium heat.',
      'Stir in turmeric powder and sugar until creamy and fragrant.',
      'Pour into a bowl and serve immediately warm.',
    ],
  ),
  const RecipeModel(
    id: 'rec-6',
    title: 'Savory Chickpea & Spice Bowl',
    category: 'Main Courses',
    description: 'Tender simmered chickpeas tossed in cumin, turmeric, and mustard oil for a protein-rich pantry meal.',
    imageUrl: 'https://images.unsplash.com/photo-1515543237350-b3eea1ec8082?auto=format&fit=crop&w=600&q=80',
    youtubeId: 's40jR0Q9Z4c',
    youtubeUrl: 'https://www.youtube.com/watch?v=s40jR0Q9Z4c',
    prepTime: '18 mins',
    difficulty: 'Medium',
    calories: 360,
    requiredIngredients: ['Chickpeas', 'Mustard Oil', 'Cumin', 'Turmeric Powder', 'Salt'],
    instructions: [
      'Warm mustard oil in a heavy skillet over medium flame.',
      'Sauté cumin and turmeric powder until aromatic.',
      'Add boiled chickpeas and toss with salt until thoroughly coated.',
      'Garnish and serve warm.',
    ],
  ),
  const RecipeModel(
    id: 'rec-7',
    title: 'Crispy Golden Garlic Fried Rice',
    category: 'Quick Meals',
    description: 'Flavor-packed leftover rice tossed in golden crispy garlic chips, oil, and ground black pepper.',
    imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'y3nE_aT8q8k',
    youtubeUrl: 'https://www.youtube.com/watch?v=y3nE_aT8q8k',
    prepTime: '12 mins',
    difficulty: 'Easy',
    calories: 310,
    requiredIngredients: ['Basmati Rice', 'Olive Oil', 'Salt', 'Black Pepper', 'Garlic'],
    instructions: [
      'Thinly slice garlic cloves into chips.',
      'Gently fry garlic in oil over low-medium flame until golden and crispy.',
      'Add cooked rice, tossing on high flame with salt and pepper until fragrant.',
      'Serve hot topped with crispy garlic chips.',
    ],
  ),
  const RecipeModel(
    id: 'rec-8',
    title: 'Fluffy Banana Oat Pancakes',
    category: 'Breakfast',
    description: 'Wholesome naturally sweetened pancakes made with rolled oats, ripe banana, and creamy milk.',
    imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?auto=format&fit=crop&w=600&q=80',
    youtubeId: 'sIu9gK83F9k',
    youtubeUrl: 'https://www.youtube.com/watch?v=sIu9gK83F9k',
    prepTime: '12 mins',
    difficulty: 'Easy',
    calories: 250,
    requiredIngredients: ['Rolled Oats', 'Whole Milk', 'Baking Powder', 'Sugar'],
    instructions: [
      'Blend rolled oats, milk, baking powder, and sugar into a smooth batter.',
      'Ladle batter onto a lightly greased hot pan over medium heat.',
      'Flip when bubbles form on the surface and cook until golden brown on both sides.',
      'Serve warm with fruit or honey.',
    ],
  ),
];

/// Smart Recipe Finder Screen matching ingredients in pantry with direct YouTube video watching
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _favouriteRecipeIds = {'rec-1', 'rec-3'};
  List<RecipeModel> _recipes = _sampleRecipes;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _syncRecipes();
  }

  Future<void> _syncRecipes() async {
    if (!mounted) return;
    setState(() => _isSyncing = true);
    final fresh = await AdminSyncService.fetchRecipes(fallbackRecipes: _sampleRecipes);
    if (mounted) {
      setState(() {
        _recipes = fresh;
        _isSyncing = false;
      });
    }
  }

  final _categories = const [
    'All',
    'Favourites',
    'Quick Meals',
    'Breakfast',
    'Main Courses',
    'Snacks & Drinks',
  ];

  void _toggleFavourite(String recipeId) {
    setState(() {
      if (_favouriteRecipeIds.contains(recipeId)) {
        _favouriteRecipeIds.remove(recipeId);
      } else {
        _favouriteRecipeIds.add(recipeId);
      }
    });
  }

  /// Opens the YouTube video tutorial with multiple robust fallback strategies
  Future<void> _openYouTubeVideo(RecipeModel recipe) async {
    final youtubeId = recipe.youtubeId;
    final webUrl = 'https://www.youtube.com/watch?v=$youtubeId';
    final appUrl = 'vnd.youtube:$youtubeId';

    bool launched = false;

    // 1. Try launching native YouTube app via custom scheme
    try {
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Native YouTube app scheme attempt: $e');
    }

    // 2. Try launching standard YouTube web URL in external browser/app
    if (!launched) {
      try {
        final webUri = Uri.parse(webUrl);
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('External browser YouTube attempt: $e');
      }
    }

    // 3. Fallback to platform default / in-app browser view
    if (!launched) {
      try {
        final webUri = Uri.parse(webUrl);
        launched = await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Platform default YouTube attempt: $e');
      }
    }

    // 4. If all fail (e.g. strict sandbox or desktop without default browser), show interactive fallback modal
    if (!launched && mounted) {
      _showVideoFallbackDialog(recipe);
    }
  }

  void _showVideoFallbackDialog(RecipeModel recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videoUrl = 'https://www.youtube.com/watch?v=${recipe.youtubeId}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFDC2626), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Watch Recipe Video',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Video link:\n$videoUrl',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: videoUrl));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('YouTube video link copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                launchUrl(Uri.parse(videoUrl), mode: LaunchMode.platformDefault);
              },
              child: const Text('Open Video'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final listState = ref.watch(foodListControllerProvider);
    final pantryNames = listState.items.maybeWhen(
      data: (items) => items
          .where((i) => !i.isConsumed)
          .map((i) => i.name.toLowerCase().trim())
          .toSet(),
      orElse: () => <String>{},
    );

    // Filter recipes by category, favorites, and search query
    final filteredRecipes = _recipes.where((recipe) {
      if (_selectedCategory == 'Favourites') {
        if (!_favouriteRecipeIds.contains(recipe.id)) return false;
      } else if (_selectedCategory != 'All') {
        if (recipe.category != _selectedCategory) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchesTitle = recipe.title.toLowerCase().contains(query);
        final matchesIng = recipe.requiredIngredients.any((i) => i.toLowerCase().contains(query));
        if (!matchesTitle && !matchesIng) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? ColorPalette.darkBg : ColorPalette.lightBg,
      appBar: AppBar(
        title: Text(
          'Smart Recipes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync with Admin Console',
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            onPressed: _syncRecipes,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _syncRecipes,
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Search Recipes Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search recipes or ingredients...',
                    hintStyle: TextStyle(
                      color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: ColorPalette.freshEmerald,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // 2. Recipe Category Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  final isFav = cat == 'Favourites';

                  return Material(
                    color: isSelected
                        ? ColorPalette.freshEmerald
                        : (isDark ? ColorPalette.darkCard : ColorPalette.lightCard),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? ColorPalette.freshEmerald
                                : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFav) ...[
                              Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: isSelected ? Colors.white : ColorPalette.expiredRed,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? ColorPalette.darkTextSecondary
                                        : ColorPalette.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 3. Banner: Leftover Recipe Matchmaker with YouTube note
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF0F2E23)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ColorPalette.freshEmerald.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorPalette.freshEmerald.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Color(0xFFE11D48),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zero-Waste Recipe Match',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? ColorPalette.darkTextPrimary
                                : const Color(0xFF064E3B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap any recipe or Watch button to play its tutorial video directly on YouTube!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? ColorPalette.darkTextSecondary
                                : const Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 4. Recipes List
          if (filteredRecipes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matching recipes found',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different category or search keyword.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? ColorPalette.darkTextTertiary : ColorPalette.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final recipe = filteredRecipes[index];
                    final isFav = _favouriteRecipeIds.contains(recipe.id);

                    // Compute ingredient matches
                    final availableList = <String>[];
                    final missingList = <String>[];

                    for (final req in recipe.requiredIngredients) {
                      final reqLower = req.toLowerCase();
                      final hasInPantry = pantryNames.any((pantry) =>
                          pantry.contains(reqLower) || reqLower.contains(pantry));
                      if (hasInPantry) {
                        availableList.add(req);
                      } else {
                        missingList.add(req);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRecipeCard(
                        context,
                        recipe,
                        availableList,
                        missingList,
                        isFav,
                        isDark,
                      ),
                    );
                  },
                  childCount: filteredRecipes.length,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    RecipeModel recipe,
    List<String> availableIngredients,
    List<String> missingIngredients,
    bool isFav,
    bool isDark,
  ) {
    final totalReq = recipe.requiredIngredients.length;
    final matchCount = availableIngredients.length;
    final matchPercent = totalReq > 0 ? (matchCount / totalReq * 100).round() : 0;

    return Material(
      color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openYouTubeVideo(recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Photo Banner with Play Button Overlay, Favorite Button & Match Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  recipe.imageUrl,
                  height: 165,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  cacheHeight: 350,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 165,
                    color: ColorPalette.freshEmerald.withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(Icons.restaurant_rounded, size: 40, color: ColorPalette.freshEmerald),
                    ),
                  ),
                ),

                // Dark subtle gradient overlay on image for contrast
                Container(
                  height: 165,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),

                // Match Percentage Pill (Top-Left)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: matchCount > 0
                          ? ColorPalette.freshEmeraldDark.withValues(alpha: 0.92)
                          : const Color(0xFF334155).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          matchCount > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$matchCount/$totalReq In Pantry ($matchPercent%)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center YouTube Play Action Button Overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.9), // YouTube Red
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                // Bottom-Left YouTube Badge Pill
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626), // YouTube Red
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_collection_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'YouTube Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite Heart Button (Top-Right)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _toggleFavourite(recipe.id),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? ColorPalette.expiredRed : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: ColorPalette.freshEmerald.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe.category,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: ColorPalette.freshEmerald,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 3),
                          Text(
                            recipe.prepTime,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.local_fire_department_outlined, size: 14, color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.calories} kcal',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),
                  const SizedBox(height: 8),

                  // Ingredients preview with In Pantry / Need to Buy tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recipe.requiredIngredients.map((ing) {
                      final hasIt = availableIngredients.contains(ing);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: hasIt
                              ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                              : (isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasIt
                                ? ColorPalette.freshEmerald.withValues(alpha: 0.4)
                                : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasIt ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 11,
                              color: hasIt ? ColorPalette.freshEmerald : (isDark ? Colors.white38 : Colors.black38),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ing,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: hasIt ? FontWeight.w700 : FontWeight.w500,
                                color: hasIt
                                    ? (isDark ? ColorPalette.freshEmerald : ColorPalette.freshEmeraldDark)
                                    : (isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons Row: [ ▶ Watch on YouTube ] and [ 📖 Recipe Details ]
                  Row(
                    children: [
                      // Primary: Watch on YouTube Button
                      Expanded(
                        child: Material(
                          color: const Color(0xFFDC2626), // YouTube Red
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _openYouTubeVideo(recipe),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Watch on YouTube',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Secondary: View Instructions / Details Sheet
                      Material(
                        color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _showRecipeDetails(
                            context,
                            recipe,
                            availableIngredients,
                            missingIngredients,
                            isFav,
                            isDark,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(
    BuildContext context,
    RecipeModel recipe,
    List<String> availableIngredients,
    List<String> missingIngredients,
    bool isFav,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentlyFav = _favouriteRecipeIds.contains(recipe.id);

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Top Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header with Close & Favorite
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recipe Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                currentlyFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: currentlyFav ? ColorPalette.expiredRed : (isDark ? Colors.white70 : Colors.black54),
                              ),
                              onPressed: () {
                                _toggleFavourite(recipe.id);
                                setModalState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                  ),

                  // Modal Body
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(18),
                      children: [
                        // Prominent Watch on YouTube Action Card at Top of Modal
                        Material(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              _openYouTubeVideo(recipe);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Watch Video Tutorial on YouTube',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          recipe.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.description,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? ColorPalette.darkTextSecondary : ColorPalette.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Required Ingredients Checklist
                        Text(
                          'Required Ingredients',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...recipe.requiredIngredients.map((ing) {
                          final hasIt = availableIngredients.contains(ing);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? ColorPalette.darkSurface : ColorPalette.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasIt
                                    ? ColorPalette.freshEmerald.withValues(alpha: 0.3)
                                    : (isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasIt ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: hasIt ? ColorPalette.freshEmerald : (isDark ? Colors.white38 : Colors.black38),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ing,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasIt
                                        ? ColorPalette.freshEmerald.withValues(alpha: 0.15)
                                        : (isDark ? ColorPalette.darkCard : Colors.white),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hasIt ? 'In Pantry' : 'Need to Buy',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: hasIt ? ColorPalette.freshEmerald : (isDark ? Colors.white54 : Colors.black45),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 18),

                        // Instructions
                        Text(
                          'Step-by-Step Instructions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        ...recipe.instructions.asMap().entries.map((entry) {
                          final stepNum = entry.key + 1;
                          final stepText = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: ColorPalette.freshEmerald.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ColorPalette.freshEmerald.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$stepNum',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: ColorPalette.freshEmerald,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    stepText,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                      color: isDark ? ColorPalette.darkTextPrimary : ColorPalette.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
