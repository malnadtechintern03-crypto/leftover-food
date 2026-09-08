<?php
/**
 * ScanSmart Admin Settings & System Configuration
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin');

$db = Database::getConnection();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired. Please try again.');
    } else {
        $appName = trim($_POST['app_name'] ?? 'ScanSmart – Universal Product Scanner & Smart Inventory');
        $appTagline = trim($_POST['app_tagline'] ?? 'Scan Anything. Know Everything. Never Miss an Expiry.');
        $adminEmail = trim($_POST['admin_email'] ?? 'admin@scansmart.com');
        $defaultCurrency = trim($_POST['default_currency'] ?? '₹');
        $defaultReminderDays = (int)($_POST['default_reminder_days'] ?? 7);
        $enableReminders = isset($_POST['enable_reminders']) ? '1' : '0';
        $defaultStatus = trim($_POST['default_product_status'] ?? 'Active');
        $paginationLimit = max(5, min(100, (int)($_POST['pagination_limit'] ?? 20)));
        $maxUploadMb = max(1, min(50, (int)($_POST['max_upload_mb'] ?? 5)));
        $maintenanceMode = isset($_POST['maintenance_mode']) ? '1' : '0';
        $serverIp = trim($_POST['server_ip'] ?? '192.168.31.187');

        set_app_setting('app_name', $appName, 'Display name of application');
        set_app_setting('app_tagline', $appTagline, 'Application brand tagline');
        set_app_setting('admin_email', $adminEmail, 'Primary administrator email');
        set_app_setting('default_currency', $defaultCurrency, 'Primary currency symbol');
        set_app_setting('default_reminder_days', (string)$defaultReminderDays, 'Default days before expiry to alert');
        set_app_setting('enable_reminders', $enableReminders, 'Master switch for product expiry reminders');
        set_app_setting('default_product_status', $defaultStatus, 'Default status for newly scanned products');
        set_app_setting('pagination_limit', (string)$paginationLimit, 'Items displayed per page in admin tables');
        set_app_setting('max_upload_mb', (string)$maxUploadMb, 'Maximum image upload size in MB');
        set_app_setting('maintenance_mode', $maintenanceMode, 'System maintenance mode toggle');
        set_app_setting('server_ip', $serverIp, 'Local Wi-Fi network IP address for mobile app sync');

        log_admin_activity('Update Settings', 'Updated global application settings & system configuration');
        set_flash('success', 'Application settings have been updated successfully.');
        header('Location: ' . base_url('settings.php'));
        exit;
    }
}

// Load current settings
$appName = get_app_setting('app_name', 'ScanSmart – Universal Product Scanner & Smart Inventory');
$appTagline = get_app_setting('app_tagline', 'Scan Anything. Know Everything. Never Miss an Expiry.');
$adminEmail = get_app_setting('admin_email', 'admin@scansmart.com');
$defaultCurrency = get_app_setting('default_currency', '₹');
$defaultReminderDays = (int)get_app_setting('default_reminder_days', '7');
$enableReminders = get_app_setting('enable_reminders', '1') === '1';
$defaultStatus = get_app_setting('default_product_status', 'Active');
$paginationLimit = (int)get_app_setting('pagination_limit', '20');
$maxUploadMb = (int)get_app_setting('max_upload_mb', '5');
$maintenanceMode = get_app_setting('maintenance_mode', '0') === '1';
$serverIp = get_app_setting('server_ip', '192.168.31.187');

$pageTitle = 'Application Settings';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-4xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h2 class="h4 fw-bold mb-1">Application Settings & Configuration</h2>
      <p class="text-muted small mb-0">Control brand naming, default notifications, catalog defaults, and storage limits.</p>
    </div>
  </div>

  <form method="POST" action="">
    <?= csrf_field() ?>

    <div class="row g-4">
      <div class="col-lg-8">
        <!-- 1. Brand Identity -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-primary">storefront</span>
            <span>Brand Identity</span>
          </h5>

          <div class="mb-3">
            <label for="app_name" class="form-label small fw-bold">Application Name</label>
            <input type="text" name="app_name" id="app_name" class="form-control" value="<?= e($appName) ?>" required>
          </div>

          <div class="mb-3">
            <label for="app_tagline" class="form-label small fw-bold">Brand Tagline</label>
            <input type="text" name="app_tagline" id="app_tagline" class="form-control" value="<?= e($appTagline) ?>" required>
          </div>

          <div class="row g-3">
            <div class="col-md-6">
              <label for="admin_email" class="form-label small fw-bold">Support / System Email</label>
              <input type="email" name="admin_email" id="admin_email" class="form-control" value="<?= e($adminEmail) ?>" required>
            </div>

            <div class="col-md-6">
              <label for="default_currency" class="form-label small fw-bold">Default Currency Symbol</label>
              <select name="default_currency" id="default_currency" class="form-select">
                <option value="₹" <?= $defaultCurrency === '₹' ? 'selected' : '' ?>>₹ (Indian Rupee)</option>
                <option value="$" <?= $defaultCurrency === '$' ? 'selected' : '' ?>>$ (US Dollar)</option>
                <option value="€" <?= $defaultCurrency === '€' ? 'selected' : '' ?>>€ (Euro)</option>
                <option value="£" <?= $defaultCurrency === '£' ? 'selected' : '' ?>>£ (British Pound)</option>
              </select>
            </div>
          </div>
        </div>

        <!-- 2. Expiry & Notification Rules -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-warning">notifications_active</span>
            <span>Expiration & Notification Rules</span>
          </h5>

          <div class="form-check form-switch mb-3">
            <input class="form-check-input" type="checkbox" role="switch" name="enable_reminders" id="enable_reminders" <?= $enableReminders ? 'checked' : '' ?>>
            <label class="form-check-label small fw-bold" for="enable_reminders">Enable Product Expiry Notifications (Master Switch)</label>
          </div>

          <div class="row g-3">
            <div class="col-md-6">
              <label for="default_reminder_days" class="form-label small fw-bold">Default Advance Warning Days</label>
              <select name="default_reminder_days" id="default_reminder_days" class="form-select">
                <option value="1" <?= $defaultReminderDays === 1 ? 'selected' : '' ?>>1 Day Prior</option>
                <option value="3" <?= $defaultReminderDays === 3 ? 'selected' : '' ?>>3 Days Prior</option>
                <option value="7" <?= $defaultReminderDays === 7 ? 'selected' : '' ?>>7 Days Prior</option>
                <option value="14" <?= $defaultReminderDays === 14 ? 'selected' : '' ?>>14 Days Prior</option>
                <option value="30" <?= $defaultReminderDays === 30 ? 'selected' : '' ?>>30 Days Prior</option>
              </select>
            </div>

            <div class="col-md-6">
              <label for="default_product_status" class="form-label small fw-bold">Default Catalog Status on Add</label>
              <select name="default_product_status" id="default_product_status" class="form-select">
                <option value="Active" <?= $defaultStatus === 'Active' ? 'selected' : '' ?>>Active (Immediately Published)</option>
                <option value="Pending Review" <?= $defaultStatus === 'Pending Review' ? 'selected' : '' ?>>Pending Review (Needs Admin Approval)</option>
              </select>
            </div>
          </div>
        </div>

        <!-- 3. System & Table Limits -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-secondary">tune</span>
            <span>System & Upload Limits</span>
          </h5>

          <div class="row g-3">
            <div class="col-md-6">
              <label for="pagination_limit" class="form-label small fw-bold">Table Pagination Limit</label>
              <input type="number" min="5" max="100" name="pagination_limit" id="pagination_limit" class="form-control" value="<?= $paginationLimit ?>">
              <div class="form-text" style="font-size: 11px;">Rows displayed per page across admin tables.</div>
            </div>

            <div class="col-md-6">
              <label for="max_upload_mb" class="form-label small fw-bold">Max Image Upload Size (MB)</label>
              <input type="number" min="1" max="50" name="max_upload_mb" id="max_upload_mb" class="form-control" value="<?= $maxUploadMb ?>">
            </div>

            <div class="col-12">
              <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" role="switch" name="maintenance_mode" id="maintenance_mode" <?= $maintenanceMode ? 'checked' : '' ?>>
                <label class="form-check-label small fw-bold text-danger" for="maintenance_mode">Maintenance Mode (Suspends public API sync)</label>
              </div>
            </div>
          </div>
        </div>

        <!-- 4. Network & Mobile App IP -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-success">wifi</span>
            <span>Local Network & Mobile App Connectivity</span>
          </h5>

          <div class="mb-3">
            <label for="server_ip" class="form-label small fw-bold">Server IPv4 Address (Wi-Fi / LAN)</label>
            <div class="input-group">
              <span class="input-group-text bg-light text-muted"><span class="material-symbols-rounded fs-6">lan</span></span>
              <input type="text" name="server_ip" id="server_ip" class="form-control font-monospace" value="<?= e($serverIp) ?>" placeholder="192.168.31.187" required>
            </div>
            <div class="form-text" style="font-size: 11px;">
              Used by mobile phones on your local Wi-Fi to sync with this Admin Panel.
            </div>
          </div>

          <div class="p-3 bg-light rounded-3 border">
            <div class="small fw-bold text-dark mb-1">Active Mobile Endpoints:</div>
            <div class="small text-muted mb-1">• XAMPP Apache: <code class="text-primary font-monospace">http://<?= e($serverIp) ?>/leftover/admin/api</code></div>
            <div class="small text-muted">• PHP Server: <code class="text-primary font-monospace">http://<?= e($serverIp) ?>:8000/api</code></div>
          </div>
        </div>

        <button type="submit" class="btn btn-primary rounded-pill px-5 py-2.5 fw-bold d-inline-flex align-items-center gap-2" style="background-color: #10B981; border-color: #10B981;">
          <span class="material-symbols-rounded">save</span>
          <span>Save Configuration</span>
        </button>
      </div>

      <!-- Right Column: API & Server Telemetry -->
      <div class="col-lg-4">
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-info">api</span>
            <span>API Sync Telemetry</span>
          </h5>

          <div class="small">
            <div class="py-2 border-bottom">
              <div class="text-muted">Network Server IP:</div>
              <code class="d-block text-break mt-1 bg-light p-1.5 rounded fw-bold text-success"><?= e($serverIp) ?></code>
            </div>

            <div class="py-2 border-bottom">
              <div class="text-muted">Mobile REST API (Wi-Fi):</div>
              <code class="d-block text-break mt-1 bg-light p-1.5 rounded">http://<?= e($serverIp) ?>/leftover/admin/api</code>
            </div>

            <div class="py-2 border-bottom">
              <div class="text-muted">Health Ping Endpoint:</div>
              <code class="d-block text-break mt-1 bg-light p-1.5 rounded">http://<?= e($serverIp) ?>/leftover/admin/api/status.php</code>
            </div>

            <div class="py-2 border-bottom">
              <div class="text-muted">Localhost Base URL:</div>
              <code class="d-block text-break mt-1 bg-light p-1.5 rounded"><?= base_url('api') ?></code>
            </div>

            <div class="py-2 border-bottom">
              <div class="text-muted">PHP Engine:</div>
              <strong>PHP <?= phpversion() ?></strong>
            </div>

            <div class="py-2">
              <div class="text-muted">Database Engine:</div>
              <strong>MySQL / PDO Active</strong>
            </div>
          </div>
        </div>

        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
          <h5 class="fw-bold mb-2 text-dark">Cloud Hosting Ready</h5>
          <p class="text-muted small mb-0">
            This admin panel is built with portable paths and standard PDO queries, fully prepared for deployment to <strong>InfinityFree</strong> or any standard cPanel web host.
          </p>
        </div>
      </div>
    </div>
  </form>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
