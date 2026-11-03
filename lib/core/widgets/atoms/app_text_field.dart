import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.textInputAction,
    this.semanticsLabel,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final bool readOnly;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final String? semanticsLabel;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? hintText,
      textField: true,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onChanged: onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: readOnly ? AppColors.background : AppColors.surface,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
