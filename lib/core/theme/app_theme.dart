import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// PREMIUM COLOR SYSTEM
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Brand Navy ──────────────────────────────
  static const Color navyDeep  = Color(0xFF0A1628); // Hero headers, primary text
  static const Color navyMid   = Color(0xFF1A3A6B); // Secondary navy accents
  static const Color navyLight = Color(0xFF2D5299); // Softer navy for pills

  // ── Brand Blue ──────────────────────────────
  static const Color accent     = Color(0xFF2563EB); // Primary CTAs
  static const Color accentMid  = Color(0xFF3B82F6); // Hover / lighter blue
  static const Color accentLight= Color(0xFFEFF6FF); // Blue tint surface

  // ── Neutral / Background ────────────────────
  static const Color background       = Color(0xFFF0F4F8);
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceElevated  = Color(0xFFF8FAFC);
  static const Color surfaceVariant   = Color(0xFFF1F5F9);

  // ── Text ────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted     = Color(0xFF94A3B8);

  // ── Border / Shadow ─────────────────────────
  static const Color border      = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF2563EB);
  static const Color shadowColor = Color(0x0A000000);

  // ── Success / Attendance Present ────────────
  static const Color success   = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);

  // ── Warning / Low Attendance ─────────────────
  static const Color warning   = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);

  // ── Error / Absent ──────────────────────────
  static const Color error   = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);

  // ── Backward-compatibility aliases ──────────
  // (Keep old names so existing files using them still compile)
  static const Color primary              = navyDeep;
  static const Color primaryContainer     = accent;
  static const Color onPrimary            = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer   = Color(0xFFBFDBFE);
  static const Color secondary            = textSecondary;
  static const Color secondaryContainer   = surfaceVariant;
  static const Color onSecondaryContainer = textSecondary;
  static const Color onSurface           = textPrimary;
  static const Color onSurfaceVariant    = textSecondary;
  static const Color outline             = textMuted;
  static const Color outlineVariant      = border;
  static const Color presentGreen        = success;
  static const Color presentBg           = successBg;
  static const Color absentRed           = error;
  static const Color absentBg            = errorBg;
  static const Color warningOrange       = warning;
  static const Color cardBorder          = border;
  static const Color slateBg             = surfaceElevated;
  static const Color slateBorder         = border;
  static const Color slateHeader         = navyDeep;
  static const Color slateSubtext        = textSecondary;
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
}

// ─────────────────────────────────────────────
// PREMIUM TYPOGRAPHY SYSTEM
// ─────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // ── Display ─────────────────────────────────
  /// Featured numbers — attendance %, hero stats
  static const TextStyle statXL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );

  /// Large stats
  static const TextStyle statLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
    color: AppColors.accent,
  );

  static const TextStyle statMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  // ── Headings ─────────────────────────────────
  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.8,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textSecondary,
  );

  // ── Labels / Captions ──────────────────────────
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.textMuted,
  );
}

// ─────────────────────────────────────────────
// PREMIUM THEME DATA
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,

      colorScheme: const ColorScheme.light(
        primary:            AppColors.accent,
        onPrimary:          AppColors.onPrimary,
        primaryContainer:   AppColors.accentLight,
        onPrimaryContainer: AppColors.navyDeep,
        secondary:          AppColors.textSecondary,
        secondaryContainer: AppColors.surfaceVariant,
        onSecondaryContainer: AppColors.textPrimary,
        surface:            AppColors.background,
        onSurface:          AppColors.textPrimary,
        onSurfaceVariant:   AppColors.textSecondary,
        outline:            AppColors.textMuted,
        outlineVariant:     AppColors.border,
        error:              AppColors.error,
        onError:            Colors.white,
        surfaceContainerHighest: Color(0xFFE2E8F0),
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ──────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      // ── Card ────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Inputs ──────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.labelMd.copyWith(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textMuted,
      ),

      // ── Elevated Button ──────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined Button ──────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ──────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Chip ─────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.accent,
        labelStyle: AppTypography.labelMd,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // ── Navigation Bar (Material 3) ──────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            );
          }
          return const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          );
        }),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Divider ──────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ─────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
      ),

      // ── Bottom Sheet ─────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Snack Bar ────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.navyDeep,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: Colors.white),
      ),

      // ── FAB ──────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
