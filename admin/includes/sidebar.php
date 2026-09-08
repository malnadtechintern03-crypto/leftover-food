<?php
/**
 * ScanSmart Admin Panel - Sidebar Navigation Component
 */

declare(strict_types=1);

$currentScript = basename($_SERVER['SCRIPT_NAME'] ?? '');
$admin = get_logged_in_admin();
?>
<aside class="admin-sidebar">
  <div class="admin-sidebar-header">
    <div class="brand-icon-box" style="background: linear-gradient(135deg, #10B981, #059669); color: white; width: 42px; height: 42px; border-radius: 12px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(16, 185, 129, 0.35);">
      <span class="material-symbols-rounded" style="font-size: 26px;">barcode_scanner</span>
    </div>
    <div>
      <div class="brand-title" style="font-weight: 800; font-size: 17px; letter-spacing: -0.5px; color: #FFFFFF;">ScanSmart</div>
      <div class="brand-sub" style="font-size: 11px; color: #94A3B8;">Universal Inventory</div>
    </div>
  </div>

  <nav class="admin-nav">
    <div class="nav-section-label">Overview</div>
    
    <a href="<?= base_url('dashboard.php') ?>" class="admin-nav-item <?= $currentScript === 'dashboard.php' || $currentScript === 'index.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">dashboard</span>
      <span>Dashboard</span>
    </a>

    <div class="nav-section-label">Catalog & Inventory</div>

    <a href="<?= base_url('products.php') ?>" class="admin-nav-item <?= in_array($currentScript, ['products.php', 'product-add.php', 'product-edit.php', 'product-view.php', 'product-delete.php']) ? 'active' : '' ?>">
      <span class="material-symbols-rounded">inventory_2</span>
      <span>Products</span>
    </a>

    <a href="<?= base_url('categories.php') ?>" class="admin-nav-item <?= in_array($currentScript, ['categories.php', 'category-add.php', 'category-edit.php', 'category-delete.php']) ? 'active' : '' ?>">
      <span class="material-symbols-rounded">category</span>
      <span>Categories</span>
    </a>

    <a href="<?= base_url('inventory.php') ?>" class="admin-nav-item <?= $currentScript === 'inventory.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">shelves</span>
      <span>Inventory</span>
    </a>

    <div class="nav-section-label">Scanning & Expirations</div>

    <a href="<?= base_url('expiration-alerts.php') ?>" class="admin-nav-item <?= $currentScript === 'expiration-alerts.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">notifications_active</span>
      <span>Expiration Alerts</span>
    </a>

    <a href="<?= base_url('reminders.php') ?>" class="admin-nav-item <?= $currentScript === 'reminders.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">alarm</span>
      <span>Reminders</span>
    </a>

    <a href="<?= base_url('scan-history.php') ?>" class="admin-nav-item <?= $currentScript === 'scan-history.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">history</span>
      <span>Scan History</span>
    </a>

    <a href="<?= base_url('unknown-products.php') ?>" class="admin-nav-item <?= $currentScript === 'unknown-products.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">help_center</span>
      <span>Unknown Products</span>
      <?php
      try {
          $db = Database::getConnection();
          $uStmt = $db->query("SELECT COUNT(*) FROM unknown_products WHERE review_status = 'Pending Review'");
          $pendingUnknown = (int)$uStmt->fetchColumn();
          if ($pendingUnknown > 0): ?>
            <span class="badge bg-warning text-dark rounded-pill ms-auto" style="font-size: 10px;"><?= $pendingUnknown ?></span>
          <?php endif;
      } catch (Throwable) {} ?>
    </a>

    <div class="nav-section-label">Management & Reports</div>

    <a href="<?= base_url('users.php') ?>" class="admin-nav-item <?= in_array($currentScript, ['users.php', 'user-view.php', 'user-edit.php']) ? 'active' : '' ?>">
      <span class="material-symbols-rounded">people</span>
      <span>Users</span>
    </a>

    <a href="<?= base_url('reports.php') ?>" class="admin-nav-item <?= $currentScript === 'reports.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">analytics</span>
      <span>Reports</span>
    </a>

    <a href="<?= base_url('settings.php') ?>" class="admin-nav-item <?= $currentScript === 'settings.php' ? 'active' : '' ?>">
      <span class="material-symbols-rounded">settings</span>
      <span>Settings</span>
    </a>

    <?php if (can_manage_admins()): ?>
      <a href="<?= base_url('activity-logs.php') ?>" class="admin-nav-item <?= $currentScript === 'activity-logs.php' ? 'active' : '' ?>">
        <span class="material-symbols-rounded">shield</span>
        <span>Activity Logs</span>
      </a>
    <?php endif; ?>
  </nav>

  <div class="admin-sidebar-footer">
    <div class="admin-user-info">
      <div class="admin-avatar" style="width: 32px; height: 32px; font-size: 13px; background: linear-gradient(135deg, #10B981, #059669); color: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 700;">
        <?= strtoupper(substr($admin['name'] ?? 'A', 0, 1)) ?>
      </div>
      <div class="admin-user-details">
        <div class="admin-user-name" style="font-weight: 600; font-size: 13px; color: #F1F5F9;"><?= e($admin['name'] ?? 'Admin') ?></div>
        <div class="admin-user-role" style="font-size: 11px; color: #94A3B8;"><?= e(ucwords(str_replace('_', ' ', $admin['role'] ?? 'admin'))) ?></div>
      </div>
    </div>

    <a href="<?= base_url('logout.php') ?>" class="btn-action-icon danger" title="Sign Out">
      <span class="material-symbols-rounded" style="font-size: 18px;">logout</span>
    </a>
  </div>
</aside>
