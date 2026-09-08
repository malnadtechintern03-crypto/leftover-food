# ScanSmart Admin Panel — InfinityFree Cloud Hosting Guide

This guide details how to deploy the **ScanSmart Admin Panel & REST API** to **InfinityFree** free cloud web hosting, and how the **ScanSmart Flutter mobile application** connects to it.

---

## 1. InfinityFree Architecture & Folder Structure

On InfinityFree, all web files for your domain (e.g. `yourname.epizy.com` or custom domain) must be uploaded directly into the domain's **`htdocs/`** directory.

### Recommended InfinityFree Upload Hierarchy:
```
yourdomain.com/htdocs/
│
├── index.php                      (Redirects to admin/dashboard.php)
│
├── admin/                         (Admin Panel Root)
│   ├── dashboard.php
│   ├── products.php
│   ├── product-add.php
│   ├── product-edit.php
│   ├── product-view.php
│   ├── product-delete.php
│   ├── categories.php
│   ├── category-add.php
│   ├── category-edit.php
│   ├── category-delete.php
│   ├── inventory.php
│   ├── expiration-alerts.php
│   ├── reminders.php
│   ├── scan-history.php
│   ├── unknown-products.php
│   ├── users.php
│   ├── user-view.php
│   ├── user-edit.php
│   ├── reports.php
│   ├── settings.php
│   ├── activity-logs.php
│   ├── login.php
│   ├── logout.php
│   │
│   ├── api/                       (REST APIs called by Flutter & Admin)
│   │   ├── products.php
│   │   ├── categories.php
│   │   ├── inventory.php
│   │   ├── reminders.php
│   │   ├── users.php
│   │   ├── reports.php
│   │   ├── scan-history.php
│   │   ├── unknown-products.php
│   │   └── status.php
│   │
│   ├── config/
│   │   ├── database.php
│   │   ├── app.php
│   │   └── env.php                (Created on server with InfinityFree MySQL credentials)
│   │
│   ├── includes/
│   │   ├── auth.php
│   │   ├── functions.php
│   │   ├── header.php
│   │   ├── navbar.php
│   │   ├── sidebar.php
│   │   └── footer.php
│   │
│   ├── assets/
│   │   ├── css/admin.css
│   │   └── js/charts.js
│   │
│   ├── uploads/
│   │   └── products/              (Set folder permissions to 0755 or 0777 for image uploads)
│   │
│   └── database/
│       └── admin_panel.sql
```

---

## 2. Step-by-Step Deployment Instructions

### Step 1: Create Your Account & Free Domain
1. Log into your [InfinityFree Client Area](https://app.infinityfree.com/).
2. Click **Create Account** and select a free subdomain (e.g. `scansmart.rf.gd` or `scansmart.epizy.com`).
3. Note your **Control Panel (vPanel)** username and password.

### Step 2: Create the MySQL Database
1. Inside your InfinityFree account, open the **Control Panel (vPanel)**.
2. Go to **MySQL Databases**.
3. Under *Create a New Database*, enter `inventory` or `admin_db` and click **Create Database**.
4. InfinityFree will create the database and display:
   * **MySQL Hostname**: e.g., `sql302.infinityfree.com` *(Never use 'localhost' on InfinityFree!)*
   * **MySQL Database Name**: e.g., `epiz_12345678_inventory`
   * **MySQL Username**: e.g., `epiz_12345678`
   * **MySQL Password**: *(Your InfinityFree account vPanel password)*
   * **MySQL Port**: `3306`

### Step 3: Import Database Schema via phpMyAdmin
1. In the vPanel, click **phpMyAdmin** next to your newly created database.
2. Select your database from the left panel.
3. Go to the **Import** tab at the top.
4. Click **Choose File** and select `admin/database/admin_panel.sql`.
5. Click **Import**. All 14 tables and initial seed categories will be created.

### Step 4: Configure Database Credentials via `admin/config/env.php`
To keep your production credentials secure without modifying core code, create a file named `admin/config/env.php` on InfinityFree:

```php
<?php
// admin/config/env.php - InfinityFree Environment Credentials
return [
    'DB_HOST' => 'sql302.infinityfree.com', // Your actual InfinityFree MySQL Hostname
    'DB_PORT' => '3306',
    'DB_NAME' => 'epiz_12345678_inventory', // Your actual InfinityFree DB Name
    'DB_USER' => 'epiz_12345678',           // Your actual InfinityFree DB User
    'DB_PASS' => 'YOUR_VPANEL_PASSWORD',    // Your InfinityFree Account Password
];
```
`admin/config/database.php` automatically detects this file and connects seamlessly.

### Step 5: Upload Files via FTP
1. Download [FileZilla](https://filezilla-project.org/) or use InfinityFree's built-in **Online File Manager**.
2. Connect using your FTP credentials:
   * **Host**: `ftpupload.net`
   * **Username**: `epiz_12345678`
   * **Password**: `YOUR_VPANEL_PASSWORD`
   * **Port**: `21`
3. Navigate into the **`htdocs/`** directory.
4. Upload the **`admin/`** folder into `htdocs/`.
5. Ensure the directory `admin/uploads/products/` exists and has write permissions.

---

## 3. How Flutter and the Admin Panel Share the Same MySQL Database

Flutter applications cannot (and should not) connect directly to MySQL over public TCP port 3306 due to device network constraints and critical security risks. 

Instead, **the Flutter mobile application and the Admin Panel share data through the PHP REST API**:

```
+------------------------------------+          +------------------------------------+
|                                    |          |                                    |
|   ScanSmart Flutter Mobile App     |          |      ScanSmart Web Admin Panel     |
|   (Android / iOS / Play Store)     |          |    (Desktop, Tablet, & Mobile Web) |
|                                    |          |                                    |
+-----------------+------------------+          +-----------------+------------------+
                  |                                               |
                  |  HTTPS / JSON                                 |  Server-side PDO
                  |                                               |
                  v                                               v
+------------------------------------------------------------------------------------+
|                         PHP REST API & Business Logic Layer                        |
|                                                                                    |
|   - api/products.php      (CRUD, Barcode Lookup, Sync)                             |
|   - api/categories.php    (Categories, Icons, Colors)                              |
|   - api/inventory.php     (User stock sync)                                        |
|   - api/reminders.php     (Push notifications schedule)                            |
|   - api/scan-history.php  (Mobile scan telemetry)                                  |
|   - api/status.php        (Live host discovery & health ping)                      |
+-----------------------------------------+------------------------------------------+
                                          |
                                          |  PDO Prepared Statements
                                          v
+------------------------------------------------------------------------------------+
|                                 MySQL Database                                     |
|             (Localhost XAMPP or InfinityFree Cloud MySQL Cluster)                  |
+------------------------------------------------------------------------------------+
```

### Pointing the Flutter App to Your Live InfinityFree URL:
1. In the Flutter mobile app, go to **Settings** > **Admin Server Sync**.
2. Enter your live hosted URL:
   ```
   https://scansmart.epizy.com/admin
   ```
3. Tap **Test Connection**.
4. Once verified, tap **Sync Products**. All cataloged products, barcode mappings, and categories will download to the local SQLite database for instantaneous offline access. Any newly scanned items will sync back to the cloud admin queue automatically.
