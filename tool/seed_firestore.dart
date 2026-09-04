// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe/firebase_options.dart';
import 'file_reader.dart';

/// Standalone script to seed Cloud Firestore from recipe_firestore_seed_5x5.json.
///
/// Usage:
///   `flutter run -t tool/seed_firestore.dart -d chrome`
///   or
///   `flutter run -t tool/seed_firestore.dart -d <device_id>`
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseOptions options;
  if (kIsWeb) {
    options = DefaultFirebaseOptions.web;
  } else {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        options = DefaultFirebaseOptions.android;
        break;
      default:
        options = DefaultFirebaseOptions.web;
    }
  }

  await Firebase.initializeApp(options: options);

  runApp(const SeederApp());
}

/// Core idempotent seeding logic for 5x5 dataset.
Future<SeedingResult> seedFirestore() async {
  print('Starting Firestore seed...\n');

  final jsonString = await _loadSeedJson();
  final data = jsonDecode(jsonString) as Map<String, dynamic>;
  final categoriesMap = data['categories'] as Map<String, dynamic>;
  final recipesMap = data['recipes'] as Map<String, dynamic>;

  final firestore = FirebaseFirestore.instance;
  int totalCategories = 0;
  int totalRecipes = 0;
  final logs = <String>['Starting Firestore seed...', ''];

  // Categories in the specified order
  final categoryKeys = [
    'breakfast',
    'dessert',
    'dinner',
    'lunch',
    'vegetables',
  ];

  for (final catId in categoryKeys) {
    final catData = categoriesMap[catId] as Map<String, dynamic>?;
    if (catData == null) continue;

    final categoryName = catData['name'] as String;
    final categoryImage = catData['image'] as String;

    // Filter recipes for this category
    final categoryRecipes = <String, Map<String, dynamic>>{};
    recipesMap.forEach((recId, recValue) {
      final recMap = recValue as Map<String, dynamic>;
      final recCategory = (recMap['category'] as String?)?.trim().toLowerCase() ?? '';
      if (recCategory == catId || recCategory == categoryName.toLowerCase()) {
        categoryRecipes[recId] = recMap;
      }
    });

    final catLog = 'Category: $categoryName';
    final recLog = 'Uploading ${categoryRecipes.length} recipes...\n';
    print(catLog);
    print(recLog);
    logs.add(catLog);
    logs.add(recLog);

    final batch = firestore.batch();

    // 1. Upload Category document: categories/{categoryId}
    final categoryDocRef = firestore.collection('categories').doc(catId);
    batch.set(
      categoryDocRef,
      {
        'name': categoryName,
        'image': categoryImage,
      },
      SetOptions(merge: true),
    );

    // 2. Upload Recipe documents in subcollection: categories/{categoryId}/recipes/{recipeId}
    categoryRecipes.forEach((recipeId, recipeData) {
      final recipeDocRef = categoryDocRef.collection('recipes').doc(recipeId);

      batch.set(
        recipeDocRef,
        {
          'name': recipeData['name'],
          'calorie': recipeData['calorie'],
          'category': recipeData['category'],
          'image': recipeData['image'],
          'ingredientAmount': List<String>.from(recipeData['ingredientAmount'] ?? []),
          'ingredientImage': List<String>.from(recipeData['ingredientImage'] ?? []),
          'ingredientName': List<String>.from(recipeData['ingredientName'] ?? []),
          'isFavorite': recipeData['isFavorite'] ?? false,
          'rating': (recipeData['rating'] as num?)?.toDouble() ?? 0.0,
          'review': (recipeData['review'] as num?)?.toInt() ?? 0,
          'time': (recipeData['time'] as num?)?.toInt() ?? 0,
          'instructions': List<String>.from(recipeData['instructions'] ?? []),
        },
        SetOptions(merge: true),
      );
    });

    await batch.commit();
    totalCategories++;
    totalRecipes += categoryRecipes.length;
  }

  final summary = '''
--------------------------------
Firestore seed completed.
Categories uploaded: $totalCategories
Recipes uploaded: $totalRecipes
--------------------------------''';
  print(summary);
  logs.add(summary);

  // Verification step
  final verification = await _verifyUploadedData(firestore, categoryKeys);
  logs.addAll(verification);

  return SeedingResult(
    categoriesCount: totalCategories,
    recipesCount: totalRecipes,
    logs: logs,
  );
}

/// Verifies Firestore documents match expectations
Future<List<String>> _verifyUploadedData(
    FirebaseFirestore firestore, List<String> categoryKeys) async {
  final results = <String>['\n--- Database Verification ---'];
  try {
    final catSnap = await firestore.collection('categories').get();
    results.add('Total categories in Firestore: ${catSnap.docs.length}');

    int totalVerifiedRecipes = 0;
    for (final catId in categoryKeys) {
      final recipesSnap =
          await firestore.collection('categories').doc(catId).collection('recipes').get();
      totalVerifiedRecipes += recipesSnap.docs.length;
      results.add('  categories/$catId/recipes: ${recipesSnap.docs.length} documents');
    }
    results.add('Total verified recipes: $totalVerifiedRecipes');
  } catch (e) {
    results.add('Verification query notice: $e');
  }
  return results;
}

/// Loads recipe_firestore_seed_5x5.json from filesystem or asset bundle
Future<String> _loadSeedJson() async {
  // 1. Try reading from filesystem (desktop/IO)
  final fromFile = await loadSeedJsonFromFile('recipe_firestore_seed_5x5.json');
  if (fromFile != null && fromFile.trim().isNotEmpty) {
    return fromFile;
  }

  // 2. Try loading from asset bundle (web / mobile)
  try {
    final fromBundle =
        await rootBundle.loadString('recipe_firestore_seed_5x5.json');
    if (fromBundle.trim().isNotEmpty) {
      return fromBundle;
    }
  } catch (_) {}

  throw Exception(
      'Could not load recipe_firestore_seed_5x5.json from filesystem or assets.');
}

class SeedingResult {
  final int categoriesCount;
  final int recipesCount;
  final List<String> logs;

  SeedingResult({
    required this.categoriesCount,
    required this.recipesCount,
    required this.logs,
  });
}

class SeederApp extends StatefulWidget {
  const SeederApp({super.key});

  @override
  State<SeederApp> createState() => _SeederAppState();
}

class _SeederAppState extends State<SeederApp> {
  bool _isLoading = true;
  String? _error;
  SeedingResult? _result;

  @override
  void initState() {
    super.initState();
    _startSeeding();
  }

  Future<void> _startSeeding() async {
    try {
      final res = await seedFirestore();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _result = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
      print('Seeding failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firestore Seeder (5x5)',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firestore 5x5 Seeder'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFF6B35)),
                        SizedBox(height: 16),
                        Text(
                          'Starting Firestore seed...\nUploading 5 categories and 25 recipes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seeding Failed',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _startSeeding();
                  },
                  child: const Text('Retry Seeding'),
                ),
              ] else if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Firestore 5x5 Seed Completed!',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Terminal Logs:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ListView(
                    children: (_result?.logs ?? ['Initializing Firebase...'])
                        .map((l) => Text(
                              l,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: l.contains('completed')
                                    ? Colors.greenAccent
                                    : l.startsWith('Category:')
                                        ? const Color(0xFFFF6B35)
                                        : Colors.white70,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
