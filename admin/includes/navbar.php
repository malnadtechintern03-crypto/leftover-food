<?php
/**
 * ScanSmart Admin Top Navigation Bar Component
 */

declare(strict_types=1);

$admin = get_logged_in_admin();
?>
<header class="admin-topbar">
  <div class="topbar-left">
    <button class="btn-sidebar-toggle" id="btnSidebarToggle" aria-label="Toggle navigation">
      <span class="material-symbols-rounded">menu</span>
    </button>
    <div>
      <h1 class="page-title"><?= e($pageTitle ?? 'Dashboard') ?></h1>
      <span class="d-none d-lg-inline text-muted" style="font-size: 12px;">Scan Anything. Know Everything. Never Miss an Expiry.</span>
    </div>
  </div>

  <div class="topbar-right">
    <!-- Mobile App Sync Status -->
    <span class="badge bg-success-subtle text-success border border-success-subtle d-inline-flex align-items-center gap-1 rounded-pill px-3 py-1 fw-semibold" title="ScanSmart Flutter REST API Active">
      <span class="spinner-grow spinner-grow-sm text-success" style="width: 7px; height: 7px;" role="status"></span>
      <span>📱 Mobile Sync Active</span>
    </span>

    <!-- Notification Bell (Expiration Alerts) -->
    <a href="<?= base_url('expiration-alerts.php') ?>" class="btn-action-icon position-relative" title="View Expiration Alerts">
      <span class="material-symbols-rounded">notifications</span>
      <?php
      try {
          $db = Database::getConnection();
          $urgentStmt = $db->query("SELECT COUNT(*) FROM products WHERE expiry_date IS NOT NULL AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND is_consumed = 0");
          $urgentCount = (int)$urgentStmt->fetchColumn();
          if ($urgentCount > 0): ?>
            <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 10px; padding: 3px 6px;">
              <?= $urgentCount > 99 ? '99+' : $urgentCount ?>
            </span>
          <?php endif;
      } catch (Throwable) {} ?>
    </a>

    <!-- Quick REST API Link -->
    <a href="<?= base_url('api/status.php') ?>" target="_blank" class="btn btn-sm btn-outline-secondary d-none d-md-inline-flex align-items-center gap-1 rounded-pill px-3">
      <span class="material-symbols-rounded" style="font-size: 16px;">api</span>
      <span>REST API</span>
    </a>

    <!-- Admin Profile Dropdown -->
    <div class="dropdown">
      <button class="btn btn-sm btn-light dropdown-toggle d-flex align-items-center gap-2 rounded-pill px-3 py-1 border shadow-sm" type="button" data-bs-toggle="dropdown" aria-expanded="false">
        <span class="admin-avatar" style="width: 28px; height: 28px; font-size: 12px; background: linear-gradient(135deg, #10B981, #059669); color: white; border-radius: 50%; display: inline-flex; align-items: center; justify-content: center; font-weight: 700;">
          <?= strtoupper(substr($admin['name'] ?? 'A', 0, 1)) ?>
        </span>
        <div class="d-none d-sm-block text-start">
          <div class="fw-bold lh-1" style="font-size: 13px;"><?= e($admin['name'] ?? 'Admin') ?></div>
          <div class="text-muted" style="font-size: 10px;"><?= e(ucwords(str_replace('_', ' ', $admin['role'] ?? 'admin'))) ?></div>
        </div>
      </button>
      <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 rounded-4 mt-2" style="min-width: 220px;">
        <li>
          <div class="px-3 py-2 border-bottom">
            <div class="fw-bold small"><?= e($admin['name'] ?? 'Administrator') ?></div>
            <div class="text-muted" style="font-size: 11px;"><?= e($admin['email'] ?? '') ?></div>
            <span class="badge bg-primary-subtle text-primary rounded-pill mt-1" style="font-size: 10px;"><?= e(ucwords(str_replace('_', ' ', $admin['role'] ?? 'admin'))) ?></span>
          </div>
        </li>
        <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="<?= base_url('settings.php') ?>"><span class="material-symbols-rounded fs-6">settings</span>Settings</a></li>
        <?php if (can_manage_admins()): ?>
          <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="<?= base_url('activity-logs.php') ?>"><span class="material-symbols-rounded fs-6">security</span>Activity Logs</a></li>
        <?php endif; ?>
        <li><hr class="dropdown-divider"></li>
        <li><a class="dropdown-item py-2 text-danger d-flex align-items-center gap-2" href="<?= base_url('logout.php') ?>"><span class="material-symbols-rounded fs-6">logout</span>Sign Out</a></li>
      </ul>
    </div>
  </div>
</header>
