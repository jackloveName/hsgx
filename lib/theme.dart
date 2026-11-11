import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models.dart';

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.softPrimary,
    required this.heroAccent,
    required this.heroStart,
    required this.heroEnd,
  });

  final Color softPrimary;
  final Color heroAccent;
  final Color heroStart;
  final Color heroEnd;

  static AppThemeTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppThemeTokens>() ??
        AppThemeTokens(
          softPrimary: Color.lerp(
            theme.colorScheme.primary,
            theme.colorScheme.surfaceContainerLowest,
            0.88,
          )!,
          heroAccent: theme.colorScheme.secondary,
          heroStart: theme.colorScheme.primary,
          heroEnd: theme.colorScheme.secondary,
        );
  }

  @override
  AppThemeTokens copyWith({
    Color? softPrimary,
    Color? heroAccent,
    Color? heroStart,
    Color? heroEnd,
  }) {
    return AppThemeTokens(
      softPrimary: softPrimary ?? this.softPrimary,
      heroAccent: heroAccent ?? this.heroAccent,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
    );
  }

  @override
  AppThemeTokens lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      softPrimary: Color.lerp(softPrimary, other.softPrimary, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
    );
  }
}

ThemeData buildAppTheme([int skinIndex = 0]) {
  final skin = appSkinAt(skinIndex);
  final primary = skin.primary;
  final baseScheme = skin.brightness == Brightness.dark
      ? ColorScheme.dark()
      : ColorScheme.light();
  final scheme = baseScheme.copyWith(
    brightness: skin.brightness,
    primary: primary,
    onPrimary: skin.onPrimary,
    secondary: skin.accent,
    onSecondary: skin.brightness == Brightness.dark
        ? const Color(0xFF152019)
        : Colors.white,
    surface: skin.background,
    onSurface: skin.text,
    surfaceContainerLowest: skin.surface,
    surfaceContainerLow: skin.surfaceMuted,
    surfaceContainer: skin.surfaceMuted,
    surfaceContainerHigh: skin.border,
    surfaceContainerHighest: skin.border,
    secondaryContainer: skin.accentSoft,
    onSecondaryContainer: skin.text,
    primaryContainer: skin.primarySoft,
    onPrimaryContainer: skin.text,
    outline: skin.muted,
    outlineVariant: skin.border,
    onSurfaceVariant: skin.muted,
    error: Color(0xFFA65F5F),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: skin.brightness,
    colorScheme: scheme,
    extensions: [
      AppThemeTokens(
        softPrimary: skin.primarySoft,
        heroAccent: skin.heroAccent,
        heroStart: skin.heroStart,
        heroEnd: skin.heroEnd,
      ),
    ],
    scaffoldBackgroundColor: skin.background,
    fontFamily: 'PingFang SC',
    textTheme: TextTheme(
      displaySmall: TextStyle(
        color: skin.text,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      headlineSmall: TextStyle(
        color: skin.text,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        color: skin.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: skin.text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: skin.text, fontSize: 14, height: 1.55),
      bodySmall: TextStyle(color: skin.muted, fontSize: 12, height: 1.45),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: skin.surface,
      hintStyle: TextStyle(
        color: skin.placeholder,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: skin.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: skin.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: skin.surfaceMuted,
      selectedColor: skin.primarySoft,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelStyle: TextStyle(
        color: skin.muted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        color: primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? primary.withValues(alpha: 0.38)
              : primary,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? skin.muted
              : skin.onPrimary,
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(primary),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: skin.border, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: skin.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        color: skin.text,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: skin.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: skin.brightness == Brightness.dark
          ? const Color(0xFFE4DAC5)
          : const Color(0xFF383B37),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: TextStyle(
        color: skin.brightness == Brightness.dark
            ? const Color(0xFF20231F)
            : Colors.white,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
