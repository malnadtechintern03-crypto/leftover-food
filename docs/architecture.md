# Architecture Documentation: FoodSave (Leftover Food Manager)

## Overview
**FoodSave** is built using **Feature-First Clean Architecture** with the **Repository Pattern**, **Riverpod** for reactive state management, **GoRouter** for type-safe routing, and **SQLite** for offline-first local persistence.

---

## 1. Architectural Layers & Dependency Rule

```
Presentation (UI, Riverpod Notifiers, Screens, Widgets)
       ↓
Domain (Entities, Use Cases, Repository Contracts)
       ↓
Data (Data Sources, Models, Repository Implementations)
```

- **Domain Layer**: Contains pure business entities (`FoodItem`, `FoodCategory`, `FoodUnit`, `FoodStatus`, `FoodStats`, `AppSettings`), use cases (`AddFoodItemUseCase`, `ConsumeFoodItemUseCase`, `GetFoodItemsUseCase`, etc.), and repository interfaces. The domain layer has zero dependency on UI frameworks or storage drivers.
- **Data Layer**: Contains database access logic (`DatabaseHelper`, `FoodLocalDataSource`, `SettingsLocalDataSource`), serialization models (`FoodItemModel`, `AppSettingsModel`), and repository implementations (`FoodRepositoryImpl`, `SettingsRepositoryImpl`).
- **Presentation Layer**: Contains UI screens (`HomeScreen`, `AddEditFoodScreen`, `FoodDetailScreen`, `SettingsScreen`, `NotificationsCenterScreen`), reusable UI widgets (`FoodCard`, `StatsSummaryCard`, `CategoryFilterList`, `ConsumeQuantityDialog`, `ExpiryCountdownBadge`), and Riverpod `StateNotifier` controllers (`FoodListController`, `FoodFormController`, `FoodDetailController`, `FoodStatsController`, `SettingsController`).

---

## 2. Directory Structure

```
lib/
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_names.dart
│   │   └── route_paths.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── color_palette.dart
│       └── app_typography.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── database/
│   │   └── database_helper.dart
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── failure.dart
│   ├── services/
│   │   └── notification_service.dart
│   ├── utils/
│   │   ├── date_formatter.dart
│   │   └── expiry_calculator.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── confirmation_dialog.dart
│       ├── empty_state_view.dart
│       └── error_state_view.dart
├── features/
│   ├── food_inventory/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── main.dart
```

---

## 3. State Management (Riverpod)
- **Dependency Injection**: Repositories, UseCases, DataSources, and Services are injected cleanly using Riverpod `Provider`.
- **StateNotifiers**:
  - `foodListControllerProvider`: Handles search queries, category filters, status filters, sorting, item deletions, and consumption.
  - `foodFormControllerProvider`: Handles form validation, image picking, date presets, and creation/editing.
  - `foodDetailControllerProvider`: Family notifier providing individual item operations (consumption, expiry extension, deletion).
  - `foodStatsControllerProvider`: Aggregates active, expiring soon, fresh, expired, and waste saved stats.
  - `settingsControllerProvider`: Manages theme mode (System/Light/Dark), notification switches, and warning day threshold.

---

## 4. Local Persistence & Offline-First Strategy
- **SQLite Database**: Stored on-device via `sqflite` (with `sqflite_common_ffi` support for desktop).
- **Indexing**: Indexed on `expiry_date`, `is_consumed`, and `category` for instant querying.
- **Seed Data**: Automatically populates realistic example leftovers on initial launch for immediate utility.
