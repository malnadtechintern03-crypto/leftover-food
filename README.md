# 🥗 FoodSave — Leftover Food & Expiry Manager

> A production-grade, offline-first Flutter application designed to track leftover meals, monitor expiration dates, manage remaining portions, and prevent food waste.

---

## ✨ Features

- 🍲 **Track Leftovers & Groceries**: Log cooked leftovers and opened perishable items with quantities, units, and custom notes.
- 📸 **Photo Attachment**: Snap or choose photos of leftovers for instant visual recognition.
- ⏱️ **Real-Time Expiry Status**: Automatic categorization into **Fresh**, **Expiring Soon** (custom threshold), **Expired**, and **Consumed**.
- 📊 **Dashboard & Metrics**: Overview cards for total active leftovers, urgent expiring items, expired items, and waste saved.
- 🍽️ **Smart Consumption Logger**: Easily log partial or full consumption with remaining quantity updates.
- 🔍 **Real-Time Search & Filters**: Search by item name/notes, filter by category (*Vegetables, Fruits, Dairy, Cooked Food, Drinks, Other*), and sort by urgency or date.
- 🔔 **Local Expiry Reminders**: Local scheduled notifications alerting you before items expire.
- 🌙 **Modern Design & Theming**: Material 3 UI with Emerald & Sage palette, full Dark Mode support, and food waste prevention tips.
- 🔒 **100% Offline & Private**: All data stored locally in SQLite on your device with no backend or cloud tracking required.

---

## 🏛️ Architecture

Built strictly following the **Flutter Production Architecture Standard**:
- **Clean Architecture**: Strict Separation of Concerns (Presentation → Domain → Data).
- **Feature-First Structure**: Features self-contained under `lib/features/` (`food_inventory`, `settings`).
- **State Management**: Reactive Riverpod 2.x `StateNotifier` and `Provider`.
- **Navigation**: Declarative routing with `GoRouter`.
- **Persistence**: Relational SQLite database via `sqflite` (with FFI desktop support).

```
lib/
├── app/                  # Application configuration, Theme, GoRouter
├── core/                 # Constants, Database Helper, Errors, Services, Widgets
├── features/
│   ├── food_inventory/   # Core CRUD, Expiry Engine, Consumption Logger
│   └── settings/         # Theming, Expiry Thresholds, Notifications
└── main.dart
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.24.0 or higher)
- Dart SDK (v3.5.0 or higher)

### Run Locally
```bash
# 1. Clone the repository
git clone <repo-url>
cd leftover-food

# 2. Install dependencies
flutter pub get

# 3. Run the application
flutter run
```

### Run Tests & Verification
```bash
# Run unit & widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📚 Documentation
- [Architecture Details](docs/architecture.md)
- [Requirements Specification](docs/requirements.md)
- [Architecture Decision Records (ADRs)](docs/decisions.md)
