import 'package:flutter/material.dart';

/// Semantic color tokens for FoodSave with "Fresh & Modern" aesthetic
/// (Fresh Emerald Green, Radiant Mint, Soft Pastel Metric Badges, Crisp Modern Slate)
class ColorPalette {
  ColorPalette._();

  // Primary Brand Colors - Fresh Emerald & Modern Green
  static const Color freshEmerald = Color(0xFF10B981); // Vibrant Fresh Emerald Green
  static const Color freshEmeraldDark = Color(0xFF059669); // Deep Forest Emerald
  static const Color freshEmeraldDeep = Color(0xFF047857);
  static const Color freshEmeraldLight = Color(0xFFD1FAE5); // Soft Mint Mist
  static const Color freshEmeraldUltraLight = Color(0xFFECFDF5); // Pale Green Card

  // Backward-compatible Brand Aliases
  static const Color primaryGreen = freshEmerald;
  static const Color primaryGreenDark = freshEmeraldDark;
  static const Color primaryGreenLight = freshEmeraldLight;
  static const Color primaryViolet = freshEmerald;
  static const Color primaryVioletDark = freshEmeraldDark;
  static const Color primaryVioletLight = freshEmeraldLight;
  static const Color primaryTerracotta = freshEmerald;
  static const Color primaryTerracottaDark = freshEmeraldDark;
  static const Color primaryTerracottaLight = freshEmeraldLight;

  static const Color electricMint = Color(0xFF10B981);
  static const Color electricCyan = Color(0xFF0EA5E9);
  static const Color sunsetCoral = Color(0xFFE11D48); // Vivid Red / Coral
  static const Color sunsetCoralDark = Color(0xFFBE123C);
  static const Color radiantAmber = Color(0xFFF59E0B);
  static const Color royalIndigo = Color(0xFF4F46E5);
  static const Color accentTangerine = Color(0xFFF97316);
  static const Color glowHoney = Color(0xFFF59E0B);
  static const Color pistachioGreen = Color(0xFF10B981);
  static const Color pistachioGreenDark = Color(0xFF059669);
  static const Color pistachioGreenLight = Color(0xFFD1FAE5);
  static const Color secondarySage = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentCyan = Color(0xFF0EA5E9);

  // Status Metric Cards Palette (Design 1 exact colors)
  // 1. Expiring Soon (⌛)
  static const Color cardExpiringSoonBg = Color(0xFFFFFBEB); // Warm cream amber
  static const Color cardExpiringSoonDarkBg = Color(0xFF2C2208);
  static const Color cardExpiringSoonText = Color(0xFFB45309); // Dark amber text

  // 2. Expires Today (🔥)
  static const Color cardExpiresTodayBg = Color(0xFFFFF1EE); // Soft peach
  static const Color cardExpiresTodayDarkBg = Color(0xFF33160D);
  static const Color cardExpiresTodayText = Color(0xFFE11D48); // Vivid coral red

  // 3. Expired (🚫)
  static const Color cardExpiredBg = Color(0xFFFFF1F2); // Soft rose
  static const Color cardExpiredDarkBg = Color(0xFF330C14);
  static const Color cardExpiredText = Color(0xFFE11D48); // Red

  // 4. Rescued (🍃)
  static const Color cardRescuedBg = Color(0xFFECFDF5); // Soft mint
  static const Color cardRescuedDarkBg = Color(0xFF082E1E);
  static const Color cardRescuedText = Color(0xFF059669); // Forest green

  // Status Urgency Colors
  static const Color freshGreen = Color(0xFF10B981);
  static const Color freshGreenBg = Color(0xFFECFDF5);
  static const Color freshGreenDarkBg = Color(0xFF064E3B);

  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberGlow = Color(0xFFFBBF24);
  static const Color warningAmberBg = Color(0xFFFEF3C7);
  static const Color warningAmberDarkBg = Color(0xFF451A03);

  static const Color expiredRed = Color(0xFFE11D48);
  static const Color electricCoral = Color(0xFFE11D48);
  static const Color expiredRedBg = Color(0xFFFFF1F2);
  static const Color expiredRedDarkBg = Color(0xFF4C0519);

  static const Color consumedBlue = Color(0xFF10B981);
  static const Color electricBlue = Color(0xFF34D399);
  static const Color consumedBlueBg = Color(0xFFECFDF5);
  static const Color consumedBlueDarkBg = Color(0xFF064E3B);

  // Grocery Category Colors
  static const Color categoryGrains = Color(0xFFF59E0B); // Warm Golden Amber
  static const Color categoryFlour = Color(0xFFD97706); // Warm Wheat / Caramel
  static const Color categoryDairy = Color(0xFF0EA5E9); // Crisp Sky Blue
  static const Color categorySpices = Color(0xFFEF4444); // Radiant Spice Crimson
  static const Color categoryOils = Color(0xFF84CC16); // Olive Lime
  static const Color categorySnacks = Color(0xFF8B5CF6); // Radiant Violet / Purple
  static const Color categoryBeverages = Color(0xFF06B6D4); // Cyan / Teal
  static const Color categoryOther = Color(0xFF64748B); // Cool Slate

  // Legacy Category Color Aliases
  static const Color categoryVegetables = categoryGrains;
  static const Color categoryFruits = categoryFlour;
  static const Color categoryCooked = categorySpices;
  static const Color categoryDrinks = categoryBeverages;

  // Neutrals - Light Theme (Clean Crisp Minimalist)
  static const Color lightBg = Color(0xFFF9FAFB); // Clean soft background
  static const Color lightCard = Color(0xFFFFFFFF); // Pure Crisp White
  static const Color lightSurface = Color(0xFFF3F4F6); // Soft gray surface
  static const Color lightSurfaceHighlight = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827); // Deep modern obsidian
  static const Color lightTextSecondary = Color(0xFF6B7280); // Cool Slate
  static const Color lightTextTertiary = Color(0xFF9CA3AF); // Muted Silver
  static const Color lightBorder = Color(0xFFE5E7EB); // Subtle clean border
  static const Color lightBorderHighlight = Color(0xFFA7F3D0);

  // Neutrals - Dark Theme (Midnight Slate)
  static const Color darkBg = Color(0xFF0B131E); // Deep midnight
  static const Color darkCard = Color(0xFF131F2E); // Elevated midnight card
  static const Color darkSurface = Color(0xFF1B2B3F); // Frosted navy
  static const Color darkSurfaceHighlight = Color(0xFF243B55);
  static const Color darkTextPrimary = Color(0xFFF9FAFB); // Luminescent White
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Cool Slate
  static const Color darkTextTertiary = Color(0xFF6B7280); // Muted Slate
  static const Color darkBorder = Color(0xFF243B55);
  static const Color darkBorderGlow = Color(0xFF10B981);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient freshButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
  );

  static const LinearGradient sunsetTerracottaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient neonMintCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
  );

  static const LinearGradient sunsetCoralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFF59E0B)],
  );

  static const LinearGradient honeyGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const LinearGradient pistachioFreshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient electricEmeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient heroHeaderDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF0B131E)],
  );

  static const LinearGradient coralWarningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE11D48), Color(0xFFF59E0B)],
  );

  static const LinearGradient bentoHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0B131E)],
  );
}
