# ScanSmart Admin Panel — Localhost Setup Guide (XAMPP)

**Application**: ScanSmart – Universal Product Scanner & Smart Inventory  
**Tagline**: “Scan Anything. Know Everything. Never Miss an Expiry.”  
**Environment**: Apache 2.4+, PHP 8.0+, MySQL 5.7+ / MariaDB 10.4+  

---

## 1. Prerequisites
* **XAMPP** installed from [apachefriends.org](https://www.apachefriends.org/) (with Apache and MySQL components).
* Web Browser (Chrome, Edge, Firefox, Safari).
* Code editor or terminal (optional).

---

## 2. Directory Placement
Ensure the project is placed inside your XAMPP `htdocs` directory:
```
C:\xampp\htdocs\leftover\admin\
```
Or if renamed to `scansmart`:
```
C:\xampp\htdocs\scansmart\admin\
```

---

## 3. Start Apache and MySQL Services
1. Open the **XAMPP Control Panel**.
2. Click **Start** next to **Apache**. (Port 80 / 443 should turn green).
3. Click **Start** next to **MySQL**. (Port 3306 should turn green).

---

## 4. Import the Database Schema
1. Open your browser and navigate to phpMyAdmin:
   ```
   http://localhost/phpmyadmin/
   ```
2. Click **New** in the left sidebar.
3. Database name: **`grocery_admin_db`** (Collation: `utf8mb4_unicode_ci`). Click **Create**.
4. With `grocery_admin_db` selected, go to the **Import** tab.
5. Click **Choose File** and select:
   ```
   C:\xampp\htdocs\leftover\admin\database\admin_panel.sql
   ```
6. Click **Import** at the bottom of the page.
7. *(Alternative)* You can also run the automated migration runner anytime via browser:
   ```
   http://localhost/leftover/admin/database/migrate.php
   ```
   Or via command line:
   ```powershell
   & "C:\xampp\php\php.exe" C:\xampp\htdocs\leftover\admin\database\migrate.php
   ```

---

## 5. Verify Database Configuration
Open `admin/config/database.php` and verify default localhost credentials:
```php
private const DB_HOST = 'localhost';
private const DB_PORT = '3306';
private const DB_NAME = 'grocery_admin_db';
private const DB_USER = 'root';
private const DB_PASS = '';
```

---

## 6. Access the Admin Panel
Open your browser and navigate to:
```
http://localhost/leftover/admin/
```
(If running directly on port 8000 via `php -S localhost:8000 -t admin`, navigate to `http://localhost:8000`).

---

## 7. Default Super Admin Credentials
Sign in using the pre-seeded Super Administrator credentials:

* **Email**: `admin@scansmart.com` *(or `admin@homepantry.com`)*
* **Username**: `ScanSmart Administrator`
* **Password**: `admin123`
* **Role**: `super_admin` (Full permissions: admins, products, categories, inventory, reports, settings, activity logs)

---

## 8. Test Dashboard & APIs
1. **Dashboard**: Navigate to `http://localhost/leftover/admin/dashboard.php`. Verify all 12 metric cards and 3 Chart.js graphs render.
2. **Products Catalog**: Go to **Products** (`products.php`), test adding an item with an image, and test CSV export.
3. **API Ping**: Check that the REST API responds with status code 200:
   ```
   http://localhost/leftover/admin/api/status.php
   ```
   Expected response:
   ```json
   {
     "status": "online",
     "app": "ScanSmart",
     "version": "1.0.0",
     "database": "connected"
   }
   ```

---

## 9. Connect Flutter Mobile App to Localhost Admin
In the Flutter mobile application:
* If running on **Android Emulator**: The API base URL is automatically resolved to:
  ```
  http://10.0.2.2/leftover/admin/api
  ```
* If running on a **Physical Android Device (via Wi-Fi)**:
  1. Find your computer's local IP address (`ipconfig` in PowerShell, e.g. `192.168.1.15`).
  2. Open the Flutter app, go to **Settings** > **Admin Server Sync**, and enter:
     ```
     http://192.168.1.15/leftover/admin
     ```
  3. Tap **Test Connection** or **Sync Products**.
