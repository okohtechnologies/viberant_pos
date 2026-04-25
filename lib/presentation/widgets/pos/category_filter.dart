import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class CategoryFilter extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;
  final bool isMobile;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: isMobile ? 44 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: 4,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isActive = cat == selectedCategory;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: () => onCategorySelected(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ViberantColors.primary
                      : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive
                      ? null
                      : Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withOpacity(0.4),
                        ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
