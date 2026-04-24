// lib/presentation/widgets/common/app_avatar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Initials circle avatar. Falls back from imageUrl → initials.
class AppAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = scheme.onPrimaryContainer;
    final initials = _initials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: imageUrl != null ? Colors.transparent : bg,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            )
          : null,
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
