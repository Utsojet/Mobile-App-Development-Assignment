import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/recipe_provider.dart';
import '../../utils/app_colors.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  final _timeController = TextEditingController();
  final _servingsController = TextEditingController(text: '2');
  final _imageController = TextEditingController();

  String _selectedCategory = 'Breakfast';
  String _selectedDifficulty = 'Easy';

  final List<Map<String, TextEditingController>> _ingredientControllers = [];
  final List<TextEditingController> _instructionControllers = [];

  bool _isSubmitting = false;

  final List<String> _defaultCategories = [
    'Breakfast',
    'Dessert',
    'Dinner',
    'Lunch',
    'Vegetables',
  ];

  @override
  void initState() {
    super.initState();
    // Start with 2 empty ingredients
    _addIngredient();
    _addIngredient();

    // Start with 2 empty steps
    _addInstruction();
    _addInstruction();
  }

  void _addIngredient() {
    setState(() {
      final nameCtrl = TextEditingController();
      final amountCtrl = TextEditingController();
      final imageCtrl = TextEditingController();

      nameCtrl.addListener(() {
        if (mounted && imageCtrl.text.isEmpty) setState(() {});
      });
      imageCtrl.addListener(() {
        if (mounted) setState(() {});
      });

      _ingredientControllers.add({
        'name': nameCtrl,
        'amount': amountCtrl,
        'image': imageCtrl,
      });
    });
  }

  void _removeIngredient(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers[index]['name']?.dispose();
        _ingredientControllers[index]['amount']?.dispose();
        _ingredientControllers[index]['image']?.dispose();
        _ingredientControllers.removeAt(index);
      });
    }
  }

  void _addInstruction() {
    setState(() {
      _instructionControllers.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    if (_instructionControllers.length > 1) {
      setState(() {
        _instructionControllers[index].dispose();
        _instructionControllers.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    _timeController.dispose();
    _servingsController.dispose();
    _imageController.dispose();
    for (final map in _ingredientControllers) {
      map['name']?.dispose();
      map['amount']?.dispose();
      map['image']?.dispose();
    }
    for (final ctrl in _instructionControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredientNames = <String>[];
    final ingredientAmounts = <String>[];
    final ingredientImages = <String>[];

    for (final c in _ingredientControllers) {
      final name = c['name']!.text.trim();
      final amount = c['amount']!.text.trim();
      final customImg = c['image']?.text.trim() ?? '';
      if (name.isNotEmpty) {
        ingredientNames.add(name);
        ingredientAmounts.add(amount.isNotEmpty ? amount : '1 serving');
        final resolvedImg = customImg.isNotEmpty
            ? customImg
            : 'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(name)}-Small.png';
        ingredientImages.add(resolvedImg);
      }
    }

    if (ingredientNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one ingredient name.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final instructions = _instructionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one cooking instruction step.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<RecipeProvider>();
      final cleanCalorie = _calorieController.text
          .trim()
          .replaceAll(RegExp(r'\s*(kcal|cal|calories)\s*', caseSensitive: false), '')
          .trim();
      final calorie = cleanCalorie.isNotEmpty ? cleanCalorie : '350';

      await provider.addRecipe(
        categoryId: _selectedCategory.toLowerCase(),
        categoryName: _selectedCategory,
        name: _nameController.text.trim(),
        image: _imageController.text.trim(),
        calorie: calorie,
        time: int.tryParse(_timeController.text.trim()) ?? 25,
        servings: int.tryParse(_servingsController.text.trim()) ?? 2,
        difficulty: _selectedDifficulty,
        ingredientName: ingredientNames,
        ingredientAmount: ingredientAmounts,
        ingredientImage: ingredientImages,
        instructions: instructions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_nameController.text.trim()}" published successfully.'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final categories = provider.categories.isNotEmpty
        ? provider.categories.map((c) => c.name).toSet().toList()
        : _defaultCategories;

    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF14141A) : AppColors.scaffold;
    final cardBg = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final textDark = isDark ? const Color(0xFFF5F5F7) : AppColors.textDark;
    final textGrey = isDark ? const Color(0xFF9E9EAE) : AppColors.textGrey;
    final inputFill = isDark ? const Color(0xFF22222D) : Colors.white;
    final borderColor = isDark ? const Color(0xFF353547) : const Color(0xFFDCDCE5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add New Recipe',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Recipe Name ──────────────────────────────────────────
                _buildLabel('Recipe Title', textDark),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: textDark, fontSize: 14),
                  cursorColor: AppColors.primary,
                  decoration: _inputDecoration(
                    'e.g. Creamy Tuscan Chicken',
                    Iconsax.book_1,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textGrey: textGrey,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter a recipe title' : null,
                ),
                const SizedBox(height: 18),

                // ── Category Dropdown ───────────────────────────────────
                _buildLabel('Category', textDark),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: cardBg,
                      isExpanded: true,
                      icon: Icon(Iconsax.arrow_down_1, size: 18, color: textGrey),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Calorie & Cooking Time ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Calories', textDark),
                          TextFormField(
                            controller: _calorieController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textDark, fontSize: 14),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'e.g. 350',
                              Iconsax.flash,
                              inputFill: inputFill,
                              borderColor: borderColor,
                              textGrey: textGrey,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Enter calories' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Cook Time (min)', textDark),
                          TextFormField(
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textDark, fontSize: 14),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'e.g. 25',
                              Iconsax.clock,
                              inputFill: inputFill,
                              borderColor: borderColor,
                              textGrey: textGrey,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter minutes';
                              if (int.tryParse(v.trim()) == null) return 'Enter number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Servings & Difficulty ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Servings', textDark),
                          TextFormField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: textDark, fontSize: 14),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'e.g. 2',
                              Iconsax.user,
                              inputFill: inputFill,
                              borderColor: borderColor,
                              textGrey: textGrey,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter servings';
                              if (int.tryParse(v.trim()) == null) return 'Enter number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Difficulty', textDark),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: inputFill,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDifficulty,
                                dropdownColor: cardBg,
                                isExpanded: true,
                                icon: Icon(Iconsax.arrow_down_1, size: 18, color: textGrey),
                                items: const [
                                  DropdownMenuItem(value: 'Easy', child: Text('Easy', style: TextStyle(fontWeight: FontWeight.w600))),
                                  DropdownMenuItem(value: 'Medium', child: Text('Medium', style: TextStyle(fontWeight: FontWeight.w600))),
                                  DropdownMenuItem(value: 'Hard', child: Text('Hard', style: TextStyle(fontWeight: FontWeight.w600))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedDifficulty = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Image URL ───────────────────────────────────────────
                _buildLabel('Image URL (optional)', textDark),
                TextFormField(
                  controller: _imageController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: textDark, fontSize: 14),
                  cursorColor: AppColors.primary,
                  decoration: _inputDecoration(
                    'https://example.com/photo.jpg',
                    Iconsax.gallery,
                    inputFill: inputFill,
                    borderColor: borderColor,
                    textGrey: textGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Ingredients Section ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Ingredients (${_ingredientControllers.length})', textDark),
                    TextButton.icon(
                      onPressed: _addIngredient,
                      icon: const Icon(Iconsax.add, size: 16, color: AppColors.primary),
                      label: const Text('Add Row', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(_ingredientControllers.length, (index) {
                  final nameText = _ingredientControllers[index]['name']?.text.trim() ?? '';
                  final imageText = _ingredientControllers[index]['image']?.text.trim() ?? '';
                  final previewUrl = imageText.isNotEmpty
                      ? imageText
                      : (nameText.isNotEmpty
                          ? 'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(nameText)}-Small.png'
                          : '');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Live Ingredient Picture Thumbnail ────────────────
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: previewUrl.isNotEmpty
                                    ? Image.network(
                                        previewUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(Iconsax.image, size: 20, color: AppColors.primary),
                                            ),
                                      )
                                    : const Center(
                                        child: Icon(Iconsax.image, size: 20, color: AppColors.textGrey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // ── Ingredient Name ──────────────────────────────────
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _ingredientControllers[index]['name'],
                                style: TextStyle(color: textDark, fontSize: 14),
                                cursorColor: AppColors.primary,
                                decoration: _inputDecoration(
                                  'Ingredient (e.g. Milk)',
                                  null,
                                  inputFill: inputFill,
                                  borderColor: borderColor,
                                  textGrey: textGrey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ── Ingredient Amount ────────────────────────────────
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _ingredientControllers[index]['amount'],
                                style: TextStyle(color: textDark, fontSize: 14),
                                cursorColor: AppColors.primary,
                                decoration: _inputDecoration(
                                  'Amount (1 cup)',
                                  null,
                                  inputFill: inputFill,
                                  borderColor: borderColor,
                                  textGrey: textGrey,
                                ),
                              ),
                            ),

                            // ── Remove Button ────────────────────────────────────
                            if (_ingredientControllers.length > 1) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                                onPressed: () => _removeIngredient(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),

                        // ── Custom Picture URL ──────────────────────────────────
                        TextFormField(
                          controller: _ingredientControllers[index]['image'],
                          style: TextStyle(color: textDark, fontSize: 13),
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                            'Picture URL (auto-loads from name or paste link)',
                            Iconsax.gallery,
                            inputFill: inputFill,
                            borderColor: borderColor,
                            textGrey: textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // ── Cooking Instructions Section ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Instructions (${_instructionControllers.length} Steps)', textDark),
                    TextButton.icon(
                      onPressed: _addInstruction,
                      icon: const Icon(Iconsax.add, size: 16, color: AppColors.primary),
                      label: const Text('Add Step', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(_instructionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(top: 10, right: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3B2016) : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _instructionControllers[index],
                            maxLines: 2,
                            style: TextStyle(color: textDark, fontSize: 14),
                            cursorColor: AppColors.primary,
                            decoration: _inputDecoration(
                              'Describe step ${index + 1}...',
                              null,
                              inputFill: inputFill,
                              borderColor: borderColor,
                              textGrey: textGrey,
                            ),
                          ),
                        ),
                        if (_instructionControllers.length > 1)
                          IconButton(
                            icon: const Icon(Iconsax.trash, size: 18, color: Colors.redAccent),
                            onPressed: () => _removeInstruction(index),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 30),

                // ── Submit Button ───────────────────────────────────────
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.tick_circle, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Publish Recipe',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildLabel(String text, Color textDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color textDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData? prefixIcon, {
    required Color inputFill,
    required Color borderColor,
    required Color textGrey,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textGrey, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: textGrey, size: 18)
          : null,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
