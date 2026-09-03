import 'package:intl/intl.dart';
import '../../features/food_inventory/domain/entities/food_category.dart';

/// Smart utility for detecting, parsing, and estimating expiry dates for ANY product
/// (groceries, medicines, personal care, cosmetics, household supplies, pet care, baby care, electronics, etc.)
class ExpiryDateExtractor {
  ExpiryDateExtractor._();

  /// Default shelf life (in days) categorized by product type
  static const Map<FoodCategory, int> categoryShelfLifeDays = {
    FoodCategory.dairy: 7,
    FoodCategory.flourAndBaking: 90,
    FoodCategory.grainsAndPulses: 180,
    FoodCategory.spices: 365,
    FoodCategory.oils: 180,
    FoodCategory.snacksAndPackaged: 120,
    FoodCategory.beverages: 180,
    FoodCategory.medicines: 730, // 2 years default for pharmaceuticals & first aid
    FoodCategory.personalCare: 730, // 2 years default for cosmetics & toiletries
    FoodCategory.householdCleaning: 730, // 2 years default for cleaners & detergents
    FoodCategory.petSupplies: 180, // 6 months for pet nutrition
    FoodCategory.babyCare: 365, // 1 year for baby essentials
    FoodCategory.stationeryAndOffice: 365, // 1 year for adhesives & pens
    FoodCategory.electronicsAndHardware: 1825, // 5 years for dry batteries & hardware
    FoodCategory.other: 365,
  };

  /// Calculates an estimated expiry date based on product category and optional item name
  static DateTime estimateExpiryDate({
    required FoodCategory category,
    String? foodName,
    int? customShelfLifeDays,
  }) {
    final now = DateTime.now();
    if (customShelfLifeDays != null && customShelfLifeDays > 0) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: customShelfLifeDays));
    }

    final cleanName = foodName?.trim().toLowerCase() ?? '';

    // -------------------------------------------------------------
    // 1. Medicines, Pharmaceuticals & First Aid Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('dolo') ||
        cleanName.contains('paracetamol') ||
        cleanName.contains('crocin') ||
        cleanName.contains('aspirin') ||
        cleanName.contains('ibuprofen') ||
        cleanName.contains('tablet') ||
        cleanName.contains('capsule') ||
        cleanName.contains('strip') ||
        cleanName.contains('antibiotic')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('cough syrup') || cleanName.contains('syrup') || cleanName.contains('suspension')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 365)); // 1 year
    } else if (cleanName.contains('eye drop') || cleanName.contains('ear drop') || cleanName.contains('nasal spray')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 90)); // 3 months once opened
    } else if (cleanName.contains('dettol') || cleanName.contains('savlon') || cleanName.contains('antiseptic') || cleanName.contains('betadine') || cleanName.contains('ointment') || cleanName.contains('balm') || cleanName.contains('iodex') || cleanName.contains('volini')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('vitamin') || cleanName.contains('supplement') || cleanName.contains('calcium') || cleanName.contains('zinc') || cleanName.contains('protein powder')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 540)); // 1.5 years
    }

    // -------------------------------------------------------------
    // 2. Cosmetics, Skincare & Personal Care Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('mascara') || cleanName.contains('eyeliner') || cleanName.contains('kajal')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180)); // 6 months
    } else if (cleanName.contains('sunscreen') || cleanName.contains('sunblock') || cleanName.contains('serum') || cleanName.contains('face cream') || cleanName.contains('night cream')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 365)); // 1 year
    } else if (cleanName.contains('shampoo') || cleanName.contains('conditioner') || cleanName.contains('body wash') || cleanName.contains('shower gel') || cleanName.contains('soap') || cleanName.contains('handwash') || cleanName.contains('lotion') || cleanName.contains('moisturizer') || cleanName.contains('nivea') || cleanName.contains('dove')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('toothpaste') || cleanName.contains('colgate') || cleanName.contains('sensodyne') || cleanName.contains('mouthwash') || cleanName.contains('listerine') || cleanName.contains('shaving cream') || cleanName.contains('gillette')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('perfume') || cleanName.contains('deodorant') || cleanName.contains('body spray') || cleanName.contains('cologne') || cleanName.contains('fog')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1095)); // 3 years
    }

    // -------------------------------------------------------------
    // 3. Cleaning & Household Supplies Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('detergent') || cleanName.contains('surf excel') || cleanName.contains('ariel') || cleanName.contains('tide') || cleanName.contains('rin') || cleanName.contains('washing powder') || cleanName.contains('dishwash') || cleanName.contains('vim') || cleanName.contains('pril') || cleanName.contains('fabric conditioner') || cleanName.contains('comfort')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('lizol') || cleanName.contains('harpic') || cleanName.contains('floor cleaner') || cleanName.contains('toilet cleaner') || cleanName.contains('colin') || cleanName.contains('glass cleaner') || cleanName.contains('bleach') || cleanName.contains('disinfectant') || cleanName.contains('sanitizer')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    } else if (cleanName.contains('air freshener') || cleanName.contains('odonil') || cleanName.contains('hit spray') || cleanName.contains('all out') || cleanName.contains('good knight') || cleanName.contains('mosquito')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    }

    // -------------------------------------------------------------
    // 4. Pet Care & Animal Nutrition Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('dog food') || cleanName.contains('cat food') || cleanName.contains('pedigree') || cleanName.contains('whiskas') || cleanName.contains('drools') || cleanName.contains('royal canin') || cleanName.contains('kibble') || cleanName.contains('pet treat')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 365)); // 1 year
    } else if (cleanName.contains('wet pet food') || cleanName.contains('gravy pouch') || cleanName.contains('cat pouch')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180)); // 6 months
    }

    // -------------------------------------------------------------
    // 5. Baby Care Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('cerelac') || cleanName.contains('baby formula') || cleanName.contains('infant milk') || cleanName.contains('nan pro') || cleanName.contains('similac')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180)); // 6 months
    } else if (cleanName.contains('baby lotion') || cleanName.contains('baby oil') || cleanName.contains('baby powder') || cleanName.contains('baby soap') || cleanName.contains('baby shampoo') || cleanName.contains('baby wipes') || cleanName.contains('pampers') || cleanName.contains('huggies') || cleanName.contains('mamy poko') || cleanName.contains('diaper')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730)); // 2 years
    }

    // -------------------------------------------------------------
    // 6. Electronics, Batteries & Stationery Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('battery') || cleanName.contains('duracell') || cleanName.contains('energizer') || cleanName.contains('aa ') || cleanName.contains('aaa ') || cleanName.contains('alkaline cell')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 1825)); // 5 years shelf life
    } else if (cleanName.contains('glue') || cleanName.contains('fevicol') || cleanName.contains('fevikwik') || cleanName.contains('adhesive') || cleanName.contains('tape') || cleanName.contains('ink') || cleanName.contains('pen') || cleanName.contains('marker')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 540)); // 1.5 years
    }

    // -------------------------------------------------------------
    // 7. Food & Grocery Heuristics
    // -------------------------------------------------------------
    if (cleanName.contains('milk') || cleanName.contains('buttermilk') || cleanName.contains('lassi')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
    } else if (cleanName.contains('bread') || cleanName.contains('bun') || cleanName.contains('sourdough') || cleanName.contains('pav') || cleanName.contains('croissant')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 5));
    } else if (cleanName.contains('curd') || cleanName.contains('yogurt') || cleanName.contains('dahi')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 8));
    } else if (cleanName.contains('paneer') || cleanName.contains('tofu') || cleanName.contains('fresh cheese')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 10));
    } else if (cleanName.contains('egg')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 21));
    } else if (cleanName.contains('cheese') || cleanName.contains('butter')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 90));
    } else if (cleanName.contains('ghee') || cleanName.contains('oil') || cleanName.contains('mustard oil') || cleanName.contains('sunflower oil')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
    } else if (cleanName.contains('rice') || cleanName.contains('dal') || cleanName.contains('lentil') || cleanName.contains('pulses') || cleanName.contains('rajma') || cleanName.contains('chana') || cleanName.contains('moong')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
    } else if (cleanName.contains('atta') || cleanName.contains('flour') || cleanName.contains('maida') || cleanName.contains('sooji') || cleanName.contains('rava') || cleanName.contains('besan')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 90));
    } else if (cleanName.contains('salt') || cleanName.contains('sugar')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 730));
    } else if (cleanName.contains('noodle') || cleanName.contains('maggi') || cleanName.contains('pasta') || cleanName.contains('macaroni') || cleanName.contains('ramen')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
    } else if (cleanName.contains('biscuit') || cleanName.contains('cookie') || cleanName.contains('chips') || cleanName.contains('namkeen') || cleanName.contains('snack') || cleanName.contains('chocolate')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 120));
    } else if (cleanName.contains('tea') || cleanName.contains('coffee') || cleanName.contains('green tea')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
    } else if (cleanName.contains('jam') || cleanName.contains('ketchup') || cleanName.contains('sauce') || cleanName.contains('mayo') || cleanName.contains('pickle')) {
      return DateTime(now.year, now.month, now.day).add(const Duration(days: 180));
    }

    final defaultDays = categoryShelfLifeDays[category] ?? 365;
    return DateTime(now.year, now.month, now.day).add(Duration(days: defaultDays));
  }

  /// Parses date text strings commonly found on packaging for any product
  /// (e.g., DD/MM/YYYY, MM/YY, YYYY-MM-DD, EXP: 12/2026, Best Before 24 Months, etc.)
  static DateTime? parseExpiryDateText(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // Check for "Best before X months from MFD"
    final monthsFromMfd = RegExp(r'(\d{1,2})\s*(?:months?|mths?|m)\s*(?:from|of)?\s*(?:mfd|pkd|mfg|manufacture)', caseSensitive: false).firstMatch(text);
    if (monthsFromMfd != null) {
      final months = int.tryParse(monthsFromMfd.group(1)!);
      if (months != null && months > 0) {
        final now = DateTime.now();
        return DateTime(now.year, now.month + months, now.day);
      }
    }

    // Check for Period After Opening (e.g. 12M, 24M, 6M)
    final paoMatch = RegExp(r'\b(\d{1,2})\s*M\b', caseSensitive: true).firstMatch(text);
    if (paoMatch != null) {
      final months = int.tryParse(paoMatch.group(1)!);
      if (months != null && months > 0 && months <= 60) {
        final now = DateTime.now();
        return DateTime(now.year, now.month + months, now.day);
      }
    }

    // Clean common prefixes from date strings
    final sanitized = text
        .replaceAll(
          RegExp(
            r'(exp\.?\s*date\s*:?|expiry\s*date\s*:?|exp\.?|expiry|best before|use by|use before|valid till|bb\.?|b\.?b\.?|mfd\.?|pkd\.?|mfg\.?|batch\s*(?:no\.?)?\s*[^:]*?exp(?:iry)?\s*:?|date\s*:?)',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // 1. Check DD/MM/YYYY or DD-MM-YYYY or DD.MM.YYYY
    final dmyMatch = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})').firstMatch(sanitized);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!);
      final month = int.tryParse(dmyMatch.group(2)!);
      final year = int.tryParse(dmyMatch.group(3)!);
      if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // 2. Check YYYY/MM/DD or YYYY-MM-DD or YYYY.MM.DD
    final ymdMatch = RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})').firstMatch(sanitized);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!);
      final month = int.tryParse(ymdMatch.group(2)!);
      final day = int.tryParse(ymdMatch.group(3)!);
      if (day != null && month != null && year != null && month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // 3. Check MM/YYYY or MM-YYYY or MM.YYYY
    final myMatch = RegExp(r'(\d{1,2})[\/\-\.](\d{4})').firstMatch(sanitized);
    if (myMatch != null) {
      final month = int.tryParse(myMatch.group(1)!);
      final year = int.tryParse(myMatch.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        // Last day of month
        final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      }
    }

    // 4. Check MM/YY or MM-YY (e.g. 10/26 -> Oct 2026, 05/28 -> May 2028)
    final shortMyMatch = RegExp(r'(\d{1,2})[\/\-](\d{2})$').firstMatch(sanitized);
    if (shortMyMatch != null) {
      final month = int.tryParse(shortMyMatch.group(1)!);
      final shortYear = int.tryParse(shortMyMatch.group(2)!);
      if (month != null && shortYear != null && month >= 1 && month <= 12) {
        final year = 2000 + shortYear;
        final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
        return nextMonth.subtract(const Duration(days: 1));
      }
    }

    // 5. Check MMM YYYY or MMMM YYYY (e.g. Nov 2026, December 2027)
    try {
      final DateFormat format = DateFormat('MMM yyyy');
      final date = format.parseLoose(sanitized);
      final nextMonth = date.month == 12 ? DateTime(date.year + 1, 1, 1) : DateTime(date.year, date.month + 1, 1);
      return nextMonth.subtract(const Duration(days: 1));
    } catch (_) {}

    return null;
  }
}
