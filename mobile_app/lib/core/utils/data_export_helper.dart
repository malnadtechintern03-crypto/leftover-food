import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/food_inventory/domain/entities/food_item.dart';
import '../../features/shopping_list/domain/entities/shopping_item.dart';
import 'date_formatter.dart';

/// Helper to generate and export CSV formats for groceries and shopping lists
class DataExportHelper {
  static String exportGroceriesToCsv(List<FoodItem> items) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'ID,Name,Category,Quantity,Unit,Storage Location,Purchase Date,Expiry Date,Price (INR),Min Stock,Is Favorite,Is Consumed,Notes',
    );

    for (final item in items) {
      final line = [
        _escapeCsv(item.id),
        _escapeCsv(item.name),
        _escapeCsv(item.category.label),
        item.remainingQuantity.toString(),
        _escapeCsv(item.unit.label),
        _escapeCsv(item.storageLocation.label),
        _escapeCsv(DateFormatter.formatDate(item.purchaseDate)),
        _escapeCsv(DateFormatter.formatDate(item.expiryDate)),
        item.price?.toString() ?? '',
        item.minimumStock?.toString() ?? '',
        item.isFavorite ? 'Yes' : 'No',
        item.isConsumed ? 'Yes' : 'No',
        _escapeCsv(item.notes ?? ''),
      ].join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String exportShoppingListToCsv(List<ShoppingItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Name,Category,Quantity,Unit,Priority,Is Purchased');

    for (final item in items) {
      final line = [
        _escapeCsv(item.id),
        _escapeCsv(item.name),
        _escapeCsv(item.category.label),
        item.quantity.toString(),
        _escapeCsv(item.unit.label),
        _escapeCsv(item.priority.label),
        item.isPurchased ? 'Yes' : 'No',
      ].join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Copies CSV data to clipboard and shows SnackBar
  static void copyCsvToClipboard(BuildContext context, String csv, String title) {
    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title CSV exported & copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
