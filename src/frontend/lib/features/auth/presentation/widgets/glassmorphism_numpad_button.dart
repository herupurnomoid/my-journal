import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class GlassmorphismNumpadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const GlassmorphismNumpadButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Material(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        shape: CircleBorder(
          side: BorderSide(
            color: themeProvider.glassBorderColor,
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          splashColor: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
          highlightColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: icon != null
                ? Icon(
                    icon,
                    color: themeProvider.primaryTextColor,
                    size: 28,
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      color: themeProvider.primaryTextColor,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
