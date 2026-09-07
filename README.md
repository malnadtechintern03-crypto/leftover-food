# 🥗 Leftover Food & Expiry Manager (FoodSave)

> A production-grade, full-stack food waste prevention system consisting of an offline-first **Flutter Mobile App** and a connected **PHP/MySQL Web Admin Panel & REST API**.

---

## 📁 Project Architecture & Clean Separation

The project is cleanly separated into two distinct primary modules for easy discovery and management, while remaining seamlessly connected via REST APIs:

```
leftover-food/
│
├── admin/                         # 🖥️ PHP & MySQL Web Admin Dashboard & REST API
│   ├── analytics/                 # Food waste analytics & reporting
│   ├── announcements/             # Public announcements & banners
│   ├── api/                       # REST API endpoints for mobile sync
│   │   ├── categories.php         # GET active grocery/food categories
│   │   ├── recipes.php            # GET leftover recipes & video links
│   │   ├── announcements.php      # GET banner alerts
│   │   ├── add-product.php        # POST sync item from mobile to admin
│   │   ├── update-product.php     # POST update item status / quantity
│   │   ├── delete-reminder.php    # DELETE remove reminder / food item
│   │   ├── inventory.php          # GET/POST food inventory tracking
│   │   └── expiry-products.php    # GET near-expiry alerts
│   ├── config/                    # database.php (PDO MySQL connection)
│   ├── database/schema.sql        # Database schema & sample seed data
│   ├── includes/                  # Auth, header, sidebar, helpers
│   ├── products/                  # Web product catalog management
│   ├── recipes/                   # Web recipe management & YouTube links
│   ├── settings/                  # System & admin credentials
│   ├── dashboard.php              # Responsive admin dashboard
│   ├── index.php                  # Web portal router
│   └── login.php                  # Admin authentication (admin / admin123)
│
├── mobile_app/                    # 📱 Flutter Mobile Application (iOS / Android / Web)
│   ├── lib/
│   │   ├── app/                   # Theme (Emerald/Sage palette, Dark Mode), GoRouter
│   │   ├── core/
│   │   │   ├── database/          # SQLite local persistence helper & sync queue
│   │   │   └── services/          # AdminSyncService & ProductSyncService
│   │   ├── features/
│   │   │   ├── food_inventory/    # Expiry tracking, consumption logger, scanner
│   │   │   ├── recipes/           # Dynamic recipe cards & YouTube integrations
│   │   │   └── settings/          # Theming, admin ping card, URL config & sync
│   │   └── main.dart              # Application entrypoint
│   ├── test/                      # 54+ Unit, widget, and semantics tests
│   └── pubspec.yaml               # Flutter dependencies & assets
│
├── start_admin.bat                # ⚡ One-click launcher for Admin Backend & REST API
├── start_mobile.bat               # ⚡ One-click launcher for Flutter Mobile App
└── docs/                          # Architecture specs and ADRs
```

---

## 🔗 How Mobile & Admin Are Connected

1. **Offline-First Resilience**:
   - The mobile application operates 100% offline out-of-the-box using local SQLite (`sqflite`).
   - Any inventory additions, updates, or deletions are queued in the local `sync_queue` table.

2. **Auto-Discovery & Custom Endpoints**:
   - `AdminSyncService` dynamically discovers running admin instances across common environments:
     - `http://localhost:8000` (Zero-config PHP built-in server via `start_admin.bat`)
     - `http://10.0.2.2:8000` (Android Studio Emulator)
     - `http://localhost/admin` (Apache / XAMPP default)
     - Custom Wi-Fi IP (e.g. `http://192.168.x.x:8000` for physical smartphones)
   - Users can test connection latency or override the server URL directly inside **Settings → Admin REST API**.

3. **Bidirectional Data Flow**:
   - **Mobile → Admin**: Mobile inventory updates sync to `/api/add-product.php` and `/api/update-product.php`.
   - **Admin → Mobile**: Recipes and announcements published by the admin dashboard are fetched by `AdminSyncService.fetchRecipes()` and cached locally for offline browsing.

---

## 🚀 Quick Start Guide

### 1. Launch Admin Panel & REST API

Double-click `start_admin.bat` from the root folder, or run:
```bat
start_admin.bat
```
This script:
- Auto-detects PHP in system PATH or `C:\xampp\php\php.exe`.
- Starts the PHP built-in server on `http://localhost:8000` with `admin/` as the document root.
- Opens your browser directly to the admin dashboard.

**Admin Credentials**:
- **Username**: `admin`
- **Password**: `admin123`

**Database Setup**:
- Start MySQL in the XAMPP Control Panel (port 3306).
- Import `admin/database/schema.sql` into MySQL (creates `grocery_admin_db`).

---

### 2. Launch Mobile Flutter App

Double-click `start_mobile.bat` from the root folder, or run:
```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 🧪 Testing & Verification

Inside `mobile_app/`:
```bash
# Run static analysis (0 errors guaranteed)
flutter analyze

# Run unit and widget test suite (54+ passing tests)
flutter test
```

---

## ✨ Mobile Features

- 🍲 **Track Leftovers & Groceries**: Log cooked leftovers and perishable items with quantities, units, and custom notes.
- ⏱️ **Real-Time Freshness Engine**: Dynamic status computation (**Fresh**, **Expiring Soon**, **Expired**, and **Consumed**).
- 📅 **Expiry Calendar**: Interactive calendar view with date markers for expiring items.
- 🔍 **Real-Time Search & Category Filters**: Search by item name/notes, filter by category (*Vegetables, Fruits, Dairy, Cooked Food, Drinks, Other*).
- 🍽️ **Smart Consumption Logger**: Log partial or full consumption with remaining quantity updates.
- 📡 **Admin Connectivity Hub**: Test server ping latency, trigger queue sync, and configure server host directly in Settings.
- 🌙 **Modern Material 3 Theming**: Curated Emerald & Sage palette with complete Dark Mode support.
