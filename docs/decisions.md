# Architectural Decisions Record (ADR)

## ADR 1: Local SQLite Persistence via `sqflite` + `sqflite_common_ffi`
- **Context**: The app is strictly offline-first. Cross-platform execution (mobile and desktop) requires a reliable relational storage engine.
- **Decision**: Used `sqflite` with FFI initialization on desktop platforms.
- **Consequences**: Fast queries, transactional integrity, index support, and testability.

## ADR 2: Feature-First Clean Architecture
- **Context**: Maintainability and scalability standard across features.
- **Decision**: Separated domain (`entities`, `repositories`, `usecases`), data (`datasources`, `models`, `repositories`), and presentation (`providers`, `screens`, `widgets`) per feature (`food_inventory`, `settings`).
- **Consequences**: The presentation layer never accesses database infrastructure directly. Use cases encapsulate business logic and validations.

## ADR 3: State Management with Riverpod 2.x
- **Context**: Need compile-safe dependency injection, testability, and reactive UI state updates.
- **Decision**: Employed Riverpod `StateNotifierProvider` and `Provider`.
- **Consequences**: Clean separation of state from UI widgets, straightforward unit and widget testing without mocking Flutter widgets.

## ADR 4: GoRouter Declarative Routing
- **Context**: Deep-link support, type-safe path parameters (`/food/:id`, `/food/edit/:id`), and decoupled navigation logic.
- **Decision**: Configured `GoRouter` with designated `RoutePaths` and `RouteNames`.
- **Consequences**: Easy navigation without context dependency in services.
