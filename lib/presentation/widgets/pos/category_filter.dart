// lib/presentation/widgets/pos/category_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

class CategoryFilter extends HookWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
    required bool isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        border: Border(
          bottom: BorderSide(color: ViberantColors.grey.withOpacity(0.1)),
        ),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selectedCategory;

            return _CategoryChip(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => onCategorySelected(category),
                )
                .animate()
                .fadeIn(delay: (index * 80).ms)
                .slideX(begin: 0.1, end: 0);
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? ViberantColors.primary : ViberantColors.background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Icon based on name
                _getCategoryIcon(category),

                const SizedBox(width: 8),

                Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : ViberantColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'all':
        icon = Icons.all_inclusive_rounded;
        break;
      case 'electronics':
        icon = Icons.electrical_services_rounded;
        break;
      case 'computers':
        icon = Icons.computer_rounded;
        break;
      case 'accessories':
        icon = Icons.headphones_rounded;
        break;
      case 'clothing':
        icon = Icons.checkroom_rounded;
        break;
      case 'food':
        icon = Icons.restaurant_rounded;
        break;
      case 'beverages':
        icon = Icons.local_drink_rounded;
        break;
      default:
        icon = Icons.category_rounded;
    }

    return Icon(
      icon,
      size: 16,
      color: isSelected ? Colors.white : ViberantColors.primary,
    );
  }
}
