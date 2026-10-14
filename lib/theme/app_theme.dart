import 'package:flutter/material.dart';
import 'package:hospital_dashboard/theme/app_colors.dart';

const appFontFamily = 'PlusJakartaSans';

class AppType {
  const AppType._();

  static const title = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.12,
    color: AppColors.ink,
  );

  static const section = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.muted,
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      onPrimary: Colors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: appFontFamily,
      splashFactory: InkSparkle.splashFactory,
    );

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: appFontFamily,
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      dividerColor: AppColors.line,
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.line.withValues(alpha: 0.9)),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: appFontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        contentTextStyle: AppType.body,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w500,
          fontFamily: appFontFamily,
        ),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
          fontFamily: appFontFamily,
        ),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.teal, width: 1.5),
        errorBorder: border(AppColors.critical),
        focusedErrorBorder: border(AppColors.critical, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: const TextStyle(
            fontFamily: appFontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
