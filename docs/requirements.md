# Requirements: FoodSave (Leftover Food Manager)

## Problem Statement
Billions of tons of edible food are wasted globally every year. Families, students, and businesses often forget leftovers stored in refrigerators until they spoil, resulting in preventable financial loss and environmental harm.

## Key Stakeholders
- **Families**: Keeping track of weekly meal preps and fridge contents.
- **Students & Singles**: Avoiding forgotten groceries and spoiled leftovers.
- **Working Professionals**: Planning lunches and weekly meals efficiently.
- **Small Food Businesses / Cafes**: Tracking batch expiry dates accurately.

## Functional Requirements
1. **Leftover Food Tracking**:
   - Add new food items with name, category, purchase/cooked date, expiry date, quantity, unit, optional notes, and optional photo.
   - Edit existing food items.
   - Delete food items with confirmation.
2. **Dynamic Expiry Status & Urgency Engine**:
   - `Fresh`: Expiry date is beyond warning threshold.
   - `Expiring Soon`: Expiry date is within warning threshold (default 2 days).
   - `Expired`: Expiry date has passed.
   - `Consumed`: Leftover has been logged as fully eaten/used.
3. **Consumption Logging**:
   - Fast partial or full consumption logger to decrement remaining quantity.
   - Shelf-life extension action (e.g. freezing or re-cooking).
4. **Search, Categorization & Filtering**:
   - Search by name or notes.
   - Filter by categories: Vegetables, Fruits, Dairy, Cooked Food, Drinks, Other.
   - Filter by status tabs: All Active, Expiring Soon, Fresh, Expired.
   - Sort by: Expiring Soonest, Expiring Latest, Name (A-Z), Recently Added, Quantity.
5. **Local Notifications & Alerts**:
   - Daily scheduled reminders before items expire.
   - Dedicated in-app Expiry Alerts screen.
6. **Customizable Settings**:
   - Light / Dark / System Theme.
   - Expiry alert warning window (1, 2, 3, 5 days).
   - Reminder time configuration.

## Non-Functional Requirements
- **100% Offline-First**: No internet required. All data stored securely in SQLite locally on user's device.
- **High Performance**: Sub-millisecond database queries with indexed fields.
- **Clean Architecture Standard**: Feature-First, Riverpod, GoRouter, zero UI-to-DB leaks.
