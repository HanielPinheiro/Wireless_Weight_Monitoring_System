import 'package:flutter/material.dart';
import 'package:precious_weight/repository/design/colors.dart';
import 'fonts.dart';

class PreciousWeightTheme {
  static TextTheme lightTextTheme = TextTheme(
    bodyLarge: bodyLarge.copyWith(color: white),
    bodyMedium: bodyMedium.copyWith(color: white),
    displayLarge: displayLarge.copyWith(color: white),
    displayMedium: displayMedium.copyWith(color: white),
    displaySmall: displaySmall.copyWith(color: white),
    headlineMedium: headlineMedium.copyWith(color: white),
    headlineSmall: headlineSmall.copyWith(color: white),
    titleLarge: titleLarge.copyWith(color: white),
    titleMedium: titleMedium.copyWith(color: white),
  );

  static TextTheme darkTextTheme = TextTheme(
    bodyLarge: bodyLarge.copyWith(color: black),
    bodyMedium: bodyMedium.copyWith(color: black),
    displayLarge: displayLarge.copyWith(color: black),
    displayMedium: displayMedium.copyWith(color: black),
    displaySmall: displaySmall.copyWith(color: black),
    headlineMedium: headlineMedium.copyWith(color: black),
    headlineSmall: headlineSmall.copyWith(color: black),
    titleLarge: titleLarge.copyWith(color: black),
    titleMedium: titleMedium.copyWith(color: black),
  );

  static ColorScheme lightColorScheme = ColorScheme(
    primary: black,
    secondary: light_gray,
    onSurface: gray,
    surface: white,
    onPrimary: blue,
    onSecondary: strongOrange,
    onTertiary: medium_orange,
    error: red,
    onError: light_orange,
    brightness: Brightness.light
  );

  static ColorScheme darkColorScheme = lightColorScheme.copyWith(
    primary: white,
    surface: black,
    brightness: Brightness.dark
  );

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      textTheme: darkTextTheme,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.secondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.secondary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.secondary,
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      textTheme: lightTextTheme,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.secondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.secondary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.secondary,
      ),
    );
  }
}