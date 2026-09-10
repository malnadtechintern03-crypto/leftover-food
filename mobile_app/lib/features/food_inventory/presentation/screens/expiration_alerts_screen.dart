import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/color_palette.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/expiry_calculator.dart';
import '../../../food_inventory/domain/entities/food_item.dart';
import '../../../food_inventory/presentation/providers/food_list_controller.dart';
import '../../../food_inventory/presentation/widgets/consume_quantity_dialog.dart';

enum AlertSection {
  all('All Alerts', Icons.notifications_active_rounded),
  expired('Expired', Icons.error_outline_rounded),
  expiringToday('Expiring Today', Icons.today_rounded),
  within7Days('Within 7 Days', Icons.warning_amber_rounded),
  within30Days('Within 30 Days', Icons.schedule_rounded),
  noExpiry('No Expiry Date', Icons.all_inclusive_rounded);

  final String label;
  final IconData icon;
  const AlertSection(this.label, this.icon);
}

class ExpirationAlertsScreen extends ConsumerStatefulWidget {
  const ExpirationAlertsScreen({super.key});

  @override
  ConsumerState<ExpirationAlertsScreen> createState() =>
      _ExpirationAlertsScreenState();
}

class _ExpirationAlertsScreenState
    extends ConsumerState<ExpirationAlertsScreen> {
  AlertSection _selectedSection = AlertSection.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listState = ref.watch(foodListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expiration Alerts',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Product',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push(RoutePaths.addFood),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(foodListControllerProvider.notifier).loadItems(),
          ),
        ],
      ),
      body: listState.items.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ColorPalette.primaryGreen),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: ColorPalette.sunsetCoral),
                const SizedBox(height: 12),
                Text('Failed to load alerts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(foodListControllerProvider.notifier).loadItems(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allItems) {
          // Filter out consumed items
          final activeItems = allItems.where((item) => !item.isConsumed).toList();

          // Categorize into 5 sections
          final expiredItems = activeItems.where((item) {
            if (item.expiryDate == null) return false;
            return item.daysRemaining() < 0;
          }).toList();

          final todayItems = activeItems.where((item) {
            if (item.expiryDate == null) return false;
            return item.daysRemaining() == 0;
          }).toList();

          final within7Items = activeItems.where((item) {
            if (item.expiryDate == null) return false;
            final days = item.daysRemaining();
            return days > 0 && days <= 7;
          }).toList();

          final within30Items = activeItems.where((item) {
            if (item.expiryDate == null) return false;
            final days = item.daysRemaining();
            return days > 7 && days <= 30;
          }).toList();

          final noExpiryItems = activeItems.where((item) {
            return item.expiryDate == null;
          }).toList();

          return Column(
            children: [
              // Search & Quick Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products by name, brand, or category...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? ColorPalette.darkBorder
                            : ColorPalette.lightBorder,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? ColorPalette.darkCard
                        : ColorPalette.lightCard,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

              // Horizontal Section Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildSectionChip(
                      AlertSection.all,
                      activeItems.length,
                      ColorPalette.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      AlertSection.expired,
                      expiredItems.length,
                      ColorPalette.statusExpired,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      AlertSection.expiringToday,
                      todayItems.length,
                      ColorPalette.sunsetCoral,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      AlertSection.within7Days,
                      within7Items.length,
                      ColorPalette.statusWarning,
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      AlertSection.within30Days,
                      within30Items.length,
                      const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 8),
                    _buildSectionChip(
                      AlertSection.noExpiry,
                      noExpiryItems.length,
                      ColorPalette.freshEmerald,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Content List (Sections)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    if (_selectedSection == AlertSection.all ||
                        _selectedSection == AlertSection.expired)
                      _buildSectionGroup(
                        title: '1. Expired Products',
                        subtitle: 'Immediate attention required: discard or consume safely',
                        icon: Icons.error_outline_rounded,
                        accentColor: ColorPalette.statusExpired,
                        items: _applySearch(expiredItems),
                        emptyMessage: 'No expired products found! Great job maintaining freshness.',
                        isDark: isDark,
                      ),
                    if (_selectedSection == AlertSection.all ||
                        _selectedSection == AlertSection.expiringToday)
                      _buildSectionGroup(
                        title: '2. Expiring Today',
                        subtitle: 'Must be consumed or used today',
                        icon: Icons.today_rounded,
                        accentColor: ColorPalette.sunsetCoral,
                        items: _applySearch(todayItems),
                        emptyMessage: 'No products expiring today.',
                        isDark: isDark,
                      ),
                    if (_selectedSection == AlertSection.all ||
                        _selectedSection == AlertSection.within7Days)
                      _buildSectionGroup(
                        title: '3. Expiring Within 7 Days',
                        subtitle: 'Products nearing their expiration date this week',
                        icon: Icons.warning_amber_rounded,
                        accentColor: ColorPalette.statusWarning,
                        items: _applySearch(within7Items),
                        emptyMessage: 'No items expiring within the next 7 days.',
                        isDark: isDark,
                      ),
                    if (_selectedSection == AlertSection.all ||
                        _selectedSection == AlertSection.within30Days)
                      _buildSectionGroup(
                        title: '4. Expiring Within 30 Days',
                        subtitle: 'Products expiring within the upcoming month',
                        icon: Icons.schedule_rounded,
                        accentColor: const Color(0xFF0284C7),
                        items: _applySearch(within30Items),
                        emptyMessage: 'No products expiring within the next 30 days.',
                        isDark: isDark,
                      ),
                    if (_selectedSection == AlertSection.all ||
                        _selectedSection == AlertSection.noExpiry)
                      _buildSectionGroup(
                        title: '5. Products Without Expiration Date',
                        subtitle: 'Electronics, clothing, furniture, tools & non-perishable inventory',
                        icon: Icons.all_inclusive_rounded,
                        accentColor: ColorPalette.freshEmerald,
                        items: _applySearch(noExpiryItems),
                        emptyMessage: 'No products without expiration date tracked.',
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<FoodItem> _applySearch(List<FoodItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      final name = item.name.toLowerCase();
      final brand = (item.brand ?? '').toLowerCase();
      final cat = item.category.label.toLowerCase();
      final sub = (item.subcategory ?? '').toLowerCase();
      return name.contains(q) || brand.contains(q) || cat.contains(q) || sub.contains(q);
    }).toList();
  }

  Widget _buildSectionChip(AlertSection section, int count, Color color) {
    final isSelected = _selectedSection == section;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSection = section);
        }
      },
      avatar: Icon(
        section.icon,
        size: 16,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(
        '${section.label} ($count)',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selectedColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildSectionGroup({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<FoodItem> items,
    required String emptyMessage,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${items.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Items or Empty State
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? ColorPalette.darkBorder : ColorPalette.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 20, color: ColorPalette.freshEmerald.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emptyMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildAlertCard(context, items[index], accentColor, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    FoodItem item,
    Color accentColor,
    bool isDark,
  ) {
    final remainingText = ExpiryCalculator.formatRemainingTime(item.expiryDate);
    final daysRemaining = item.daysRemaining();
    final isExpired = daysRemaining < 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.darkCard : ColorPalette.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? ColorPalette.statusExpired.withValues(alpha: 0.4)
              : isDark
                  ? ColorPalette.darkBorder
                  : ColorPalette.lightBorder,
          width: isExpired ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category, Brand, Expiry Status Pill
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.category.icon, size: 12, color: item.category.color),
                        const SizedBox(width: 4),
                        Text(
                          item.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.category.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.brand != null && item.brand!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.brand!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.expiryDate != null ? remainingText : 'No Expiry',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Main Info: Product Name & Quantity
          InkWell(
            onTap: () => context.push(RoutePaths.foodDetailPath(item.id)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Quantity: ${item.remainingQuantity.toStringAsFixed(item.remainingQuantity.truncateToDouble() == item.remainingQuantity ? 0 : 1)} ${item.unit.abbreviation} • Storage: ${item.storageLocation.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Date & Reminder Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorPalette.darkSurface
                  : ColorPalette.lightSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.expiryDate != null
                          ? Icons.event_rounded
                          : Icons.all_inclusive_rounded,
                      size: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.expiryDate != null
                          ? 'Expiry: ${DateFormatter.formatDate(item.expiryDate)}'
                          : 'No expiry date required',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.reminderEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      size: 14,
                      color: item.reminderEnabled
                          ? const Color(0xFF8B5CF6)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.reminderEnabled
                          ? (item.reminderDaysBefore.isNotEmpty
                              ? '${item.reminderDaysBefore.map((d) => '${d}d').join(',')} before'
                              : 'Custom reminder')
                          : 'Reminder Off',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.reminderEnabled
                            ? const Color(0xFF8B5CF6)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 20),

          // Action Buttons: Edit, Change Expiration Date, Mark as Used, Dismiss Reminder, Delete
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.end,
            children: [
              // 1. Edit
              OutlinedButton.icon(
                onPressed: () => context.push(RoutePaths.editFoodPath(item.id)),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // 2. Change Expiration Date
              OutlinedButton.icon(
                onPressed: () => _handleChangeExpiryDate(context, item),
                icon: const Icon(Icons.calendar_month_outlined, size: 14),
                label: const Text('Change Expiry', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // 3. Mark as Used
              ElevatedButton.icon(
                onPressed: () => _handleMarkAsUsed(context, item),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text('Mark Used', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.freshEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // 4. Dismiss Reminder
              if (item.reminderEnabled)
                OutlinedButton.icon(
                  onPressed: () => _handleDismissReminder(context, item),
                  icon: const Icon(Icons.notifications_off_outlined,
                      size: 14, color: Color(0xFF8B5CF6)),
                  label: const Text('Dismiss Alert',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8B5CF6))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),

              // 5. Delete
              IconButton(
                tooltip: 'Delete Product',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: ColorPalette.sunsetCoral),
                onPressed: () => _handleDelete(context, item),
                style: IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  padding: const EdgeInsets.all(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangeExpiryDate(
      BuildContext context, FoodItem item) async {
    final now = DateTime.now();
    final initialDate =
        item.expiryDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (picked != null) {
      await ref
          .read(foodListControllerProvider.notifier)
          .extendExpiry(item.id, picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated ${item.name} expiration date to ${DateFormatter.formatDate(picked)}!',
            ),
            backgroundColor: ColorPalette.primaryGreenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleMarkAsUsed(BuildContext context, FoodItem item) async {
    final qty = await ConsumeQuantityDialog.show(context, item);
    if (qty != null) {
      await ref
          .read(foodListControllerProvider.notifier)
          .consumeFood(item.id, qty);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked $qty ${item.unit.abbreviation} of ${item.name} as used!'),
            backgroundColor: ColorPalette.freshEmeraldDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDismissReminder(
      BuildContext context, FoodItem item) async {
    await ref
        .read(foodListControllerProvider.notifier)
        .dismissProductReminder(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders dismissed for ${item.name}.'),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.statusExpired),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(foodListControllerProvider.notifier)
          .deleteFood(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted.'),
            backgroundColor: ColorPalette.statusExpired,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
