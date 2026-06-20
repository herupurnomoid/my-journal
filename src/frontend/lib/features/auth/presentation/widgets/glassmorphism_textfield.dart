import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class GlassmorphismTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final int? maxLength;
  final TextAlign textAlign;
  final bool readOnly;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const GlassmorphismTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.glassBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        textAlign: textAlign,
        readOnly: readOnly,
        onChanged: onChanged,
        inputFormatters: keyboardType == TextInputType.number 
            ? [FilteringTextInputFormatter.digitsOnly] 
            : null,
        style: GoogleFonts.inter(
          color: themeProvider.primaryTextColor,
          fontSize: 16,
          letterSpacing: obscureText ? 4 : 0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          counterText: '',
          hintStyle: GoogleFonts.inter(
            color: themeProvider.secondaryTextColor.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
