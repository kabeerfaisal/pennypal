import 'package:flutter/material.dart';

/// Design tokens shared by every screen.
///
/// Values are pulled from the PennyPal UI mockups: a light app bar with a
/// green wordmark, white surfaces on a soft grey-green canvas, and a single
/// confident green for actions.
class AppColors {
  AppColors._();

  /// Deep green used for the header card and primary actions.
  static const Color brand = Color(0xFF15803D);

  /// Darker green for the wordmark and app bar foreground.
  static const Color brandDark = Color(0xFF14532D);

  /// Pale green used for icon chips and the active nav pill.
  static const Color brandTint = Color(0xFFE8F5EC);

  static const Color canvas = Color(0xFFF6F8F6);
  static const Color surface = Colors.white;

  /// True black dark theme, as requested: pure black page, near-black inputs
  /// and a raised dark grey for cards so they stay separable from the page.
  ///
  /// The earlier navy palette (designer supplied) is kept below in case the
  /// brand direction changes back.
  static const Color black0 = Color(0xFF000000);
  static const Color black1 = Color(0xFF0A0A0A);
  static const Color black2 = Color(0xFF141414);
  static const Color black3 = Color(0xFF1F1F1F);
  static const Color blackBorder = Color(0xFF2A2A2A);

  /// Text on the black palette.
  static const Color blackText = Color(0xFFF5F5F5);
  static const Color blackTextMuted = Color(0xFF9E9E9E);

  /// Designer navy palette, no longer the active dark theme.
  static const Color darkScaffold = Color(0xFF0D1C42);
  static const Color darkSurface = Color(0xFF010736);
  static const Color darkCard = Color(0xFF22396F);

  /// Warm cream used for text and accents on the navy palette.
  static const Color darkCream = Color(0xFFFCF1D0);

  static const Color income = Color(0xFF16A34A);
  static const Color expense = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);

  /// Star rating and other "highlight" accents. Amber keeps stars readable on
  /// both the light and the dark palette.
  static const Color accent = Color(0xFFF5A524);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  /// Tinted background for a small icon chip.
  static Color tint(Color c) => c.withValues(alpha: 0.12);
}

class AppRadius {
  AppRadius._();
  static const double card = 18;
  static const double chip = 12;
  static const double pill = 999;
}

class AppSpace {
  AppSpace._();
  static const double gutter = 16;
  static const double gap = 12;
  static const double section = 22;
}

class AppShadow {
  AppShadow._();

  /// Barely-there lift, matching the mockup cards.
  static List<BoxShadow> soft(ColorScheme cs) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: cs.brightness == Brightness.dark ? 0.30 : 0.05,
      ),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> lifted(ColorScheme cs) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: cs.brightness == Brightness.dark ? 0.40 : 0.09,
      ),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppTheme {
  static const Color green = AppColors.brand;
  static const Color darkScaffold = AppColors.darkScaffold;
  static const Color darkCard = AppColors.darkCard;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkCream = AppColors.darkCream;

  static ThemeData light(Color primary) {
    final cs =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.canvas,
      splashFactory: InkSparkle.splashFactory,

      // The mockup uses a light app bar with dark green text, not a solid fill.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.brandDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.brandDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: primary.withValues(alpha: 0.35)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: cs.error),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandTint,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brandDark
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textMuted,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(fontSize: 12.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
      ),
    );
  }

  /// True black dark theme, rebuilt from scratch: pure black page, near black
  /// inputs, and a raised dark grey for cards.
  static ThemeData get dark {
    const page = AppColors.black0;
    const input = AppColors.black1;
    const card = AppColors.black2;
    const raised = AppColors.black3;
    const fg = AppColors.blackText;
    const muted = AppColors.blackTextMuted;
    const line = AppColors.blackBorder;

    final cs =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.brand,
          surface: card,
          onSurface: fg,
          onSurfaceVariant: muted,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: page,
      canvasColor: page,
      dividerColor: line,
      textTheme: Typography.material2021().white.apply(
        bodyColor: fg,
        displayColor: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: page,
        foregroundColor: fg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: fg),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: card,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: raised,
        selectedColor: AppColors.brand,
        side: const BorderSide(color: line),
        labelStyle: const TextStyle(color: fg, fontSize: 12.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: fg.withValues(alpha: 0.35)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: page,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brand.withValues(alpha: 0.25),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? fg : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? fg : muted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: fg,
          side: const BorderSide(color: line),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brand),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: raised,
        contentTextStyle: const TextStyle(color: fg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: fg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.chip)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
