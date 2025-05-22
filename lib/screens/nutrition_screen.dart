import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Constants for app settings
  static const int _defaultGoalCalories = 2000;
  static const String _prefsKeySelectedMeals = 'selectedMeals';
  static const String _prefsKeyGoalCalories = 'goalCalories';

  late int _goalCalories = _defaultGoalCalories;
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  List<Map<String, dynamic>> _selectedMeals = [];
  bool _isLoading = true;

  // Food categories with corresponding icons
  final Map<String, IconData> _categoryIcons = {
    "Breakfast": Icons.breakfast_dining,
    "Lunch": Icons.lunch_dining,
    "Dinner": Icons.dinner_dining,
    "Snacks": Icons.cookie,
  };

  final Map<String, List<Map<String, dynamic>>> _mealsByCategory = {
    "Breakfast": [
      {"name": "Oatmeal", "cal": 250, "protein": 8, "carbs": 40, "fat": 5, "icon": Icons.breakfast_dining.codePoint, "iconFont": Icons.breakfast_dining.fontFamily},
      {"name": "Yogurt with Berries", "cal": 180, "protein": 15, "carbs": 20, "fat": 3, "icon": Icons.local_dining.codePoint, "iconFont": Icons.local_dining.fontFamily},
      {"name": "Eggs and Toast", "cal": 300, "protein": 18, "carbs": 25, "fat": 12, "icon": Icons.egg_alt.codePoint, "iconFont": Icons.egg_alt.fontFamily},
    ],
    "Lunch": [
      {"name": "Chicken Salad", "cal": 320, "protein": 25, "carbs": 15, "fat": 18, "icon": Icons.lunch_dining.codePoint, "iconFont": Icons.lunch_dining.fontFamily},
      {"name": "Tuna Sandwich", "cal": 350, "protein": 22, "carbs": 30, "fat": 15, "icon": Icons.lunch_dining.codePoint, "iconFont": Icons.lunch_dining.fontFamily},
      {"name": "Vegetable Soup", "cal": 220, "protein": 10, "carbs": 25, "fat": 8, "icon": Icons.soup_kitchen.codePoint, "iconFont": Icons.soup_kitchen.fontFamily},
    ],
    "Dinner": [
      {"name": "Grilled Salmon", "cal": 380, "protein": 30, "carbs": 10, "fat": 22, "icon": Icons.dinner_dining.codePoint, "iconFont": Icons.dinner_dining.fontFamily},
      {"name": "Veggie Stir-fry", "cal": 260, "protein": 12, "carbs": 30, "fat": 10, "icon": Icons.dinner_dining.codePoint, "iconFont": Icons.dinner_dining.fontFamily},
      {"name": "Pasta with Sauce", "cal": 420, "protein": 15, "carbs": 65, "fat": 8, "icon": Icons.dinner_dining.codePoint, "iconFont": Icons.dinner_dining.fontFamily},
    ],
    "Snacks": [
      {"name": "Apple", "cal": 95, "protein": 0, "carbs": 25, "fat": 0, "icon": Icons.apple_rounded.codePoint, "iconFont": Icons.apple_rounded.fontFamily},
      {"name": "Smoothie", "cal": 210, "protein": 20, "carbs": 25, "fat": 3, "icon": Icons.local_drink.codePoint, "iconFont": Icons.local_drink.fontFamily},
      {"name": "Nut Mix", "cal": 180, "protein": 6, "carbs": 8, "fat": 14, "icon": Icons.food_bank.codePoint, "iconFont": Icons.food_bank.fontFamily},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mealsByCategory.length, vsync: this);
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load target calorie goal
      final savedCalories = prefs.getInt(_prefsKeyGoalCalories);
      if (savedCalories != null) {
        _goalCalories = savedCalories;
      }

      // Load selected meals
      final saved = prefs.getStringList(_prefsKeySelectedMeals);
      if (saved != null) {
        _selectedMeals = saved.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      }

      _updateTotalNutrition();
    } catch (e) {
      debugPrint('Error loading saved data: $e');
      // Show notification to user in case of error
      _showErrorSnackBar('Failed to load saved data');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save meals
      final data = _selectedMeals.map((meal) => jsonEncode(meal)).toList();
      await prefs.setStringList(_prefsKeySelectedMeals, data);

      // Save target calories
      await prefs.setInt(_prefsKeyGoalCalories, _goalCalories);
    } catch (e) {
      debugPrint('Error saving data: $e');
      _showErrorSnackBar('Failed to save data');
    }
  }

  void _updateTotalNutrition() {
    _totalCalories = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;

    for (final meal in _selectedMeals) {
      _totalCalories += meal['cal'] as int;
      _totalProtein += meal['protein'] as int;
      _totalCarbs += meal['carbs'] as int;
      _totalFat += meal['fat'] as int;
    }
  }

  void _addMeal(Map<String, dynamic> meal) {
    final newMeal = {
      ...meal,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'isSynced': false, // NEW
    };

    setState(() {
      _selectedMeals.add(newMeal);
      _updateTotalNutrition();
    });

    _saveData();
    _showSnackBar("${meal['name']} added");
  }

  void _removeMeal(int index, {BuildContext? modalContext}) {
    final removedMeal = _selectedMeals[index];
    setState(() {
      _selectedMeals.removeAt(index);
      _updateTotalNutrition();
    });
    _saveData();

    // Provide option to undo deletion
    _showSnackBar(
      "${removedMeal['name']} removed",
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            _selectedMeals.insert(index, removedMeal);
            _updateTotalNutrition();
          });
          _saveData();
        },
      ),
    );
  }

  void _showSnackBar(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: action,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCalorieGoalDialog() {
    final TextEditingController controller = TextEditingController(text: _goalCalories.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target calories',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null && newValue > 0) {
                setState(() {
                  _goalCalories = newValue;
                });
                _saveData();
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Please enter a valid value');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _mealsByCategory.keys.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showCalorieGoalDialog,
            tooltip: 'Calorie settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: categories.map((c) => Tab(
            text: c,
            icon: Icon(_categoryIcons[c] ?? Icons.restaurant),
          )).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildNutritionSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: categories.map((category) => _buildMealGrid(category)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _selectedMeals.isEmpty ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: _showSelectedMeals,
          icon: Stack(
            children: [
              const Icon(Icons.menu_book),
              if (_selectedMeals.isNotEmpty)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _selectedMeals.length.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          label: const Text("Meal Plan"),
        ),
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final theme = Theme.of(context);
    final percent = _totalCalories / _goalCalories;
    final isOver = percent > 1;
    final calorieColor = isOver
        ? theme.colorScheme.error
        : percent > 0.9
        ? Colors.orange
        : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Daily Calorie Goal",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: _showCalorieGoalDialog,
                  child: Row(
                    children: [
                      Text(
                        "$_totalCalories / $_goalCalories kcal",
                        style: TextStyle(
                          color: calorieColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit_outlined, size: 14, color: theme.colorScheme.secondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isOver ? 1.0 : percent,
                color: calorieColor,
                backgroundColor: theme.colorScheme.surfaceVariant,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientStat("Protein", _totalProtein, Colors.red),
                _buildNutrientStat("Carbs", _totalCarbs, Colors.blue),
                _buildNutrientStat("Fat", _totalFat, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientStat(String label, int value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            "$value",
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMealGrid(String category) {
    final meals = _mealsByCategory[category]!;

    return meals.isEmpty
        ? const Center(child: Text("No meals available in this category"))
        : GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: meals.length,
      itemBuilder: (_, i) => _buildMealCard(meals[i]),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMealDetail(meal),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'meal-${meal['name']}',
                child: Icon(
                  IconData(meal['icon'], fontFamily: meal['iconFont']),
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meal['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                "${meal['cal']} kcal",
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addMeal(meal),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealDetail(Map<String, dynamic> meal) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'meal-${meal['name']}',
                  child: Icon(
                    IconData(meal['icon'], fontFamily: meal['iconFont']),
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          meal['name'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                      ),
                      Text(
                        "${meal['cal']} kcal",
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroTile("Kcal", meal['cal'], Colors.orange),
                _buildMacroTile("Protein", meal['protein'], Colors.red),
                _buildMacroTile("Carbs", meal['carbs'], Colors.blue),
                _buildMacroTile("Fat", meal['fat'], Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _addMeal(meal);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add to plan"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTile(String label, int value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Text(
            "$value",
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showSelectedMeals() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Meal Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      "Total: $_totalCalories kcal",
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: _selectedMeals.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_food,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "No meals selected yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.add),
                        label: const Text("Add meals"),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: _selectedMeals.length,
                  itemBuilder: (_, i) {
                    final meal = _selectedMeals[i];
                    return Dismissible(
                      key: Key(meal['id']?.toString() ?? '${meal['name']}-$i'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: theme.colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(Icons.delete, color: theme.colorScheme.onError),
                      ),
                      onDismissed: (_) {
                        _removeMeal(i);
                        setModalState(() {});  // Update the modal UI
                      },
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            leading: Icon(
                              IconData(meal['icon'], fontFamily: meal['iconFont']),
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            title: Text(
                              meal['name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Row(
                              children: [
                                Text("${meal['cal']} kcal"),
                                const SizedBox(width: 8),
                                Text("P: ${meal['protein']}"),
                                const SizedBox(width: 4),
                                Text("C: ${meal['carbs']}"),
                                const SizedBox(width: 4),
                                Text("F: ${meal['fat']}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _removeMeal(i);
                                setModalState(() {});  // Update the modal UI
                              },
                            ),
                          ),
                          if (i < _selectedMeals.length - 1)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_selectedMeals.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedMeals = [];
                          _updateTotalNutrition();
                        });
                        setModalState(() {});  // Update the modal UI immediately
                        _saveData();
                        Navigator.pop(context);
                        _showSnackBar("Meal plan cleared");
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text("Clear all"),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

}