<?php
/**
 * Admin Panel - Sidebar Navigation Component
 */

declare(strict_types=1);

$currentUri = $_SERVER['REQUEST_URI'] ?? '';
$admin = get_logged_in_admin();
?>
<aside class="admin-sidebar">
  <div class="admin-sidebar-header">
    <div class="brand-icon-box">
      <span class="material-symbols-rounded">kitchen</span>
    </div>
    <div>
      <div class="brand-title">Home Pantry</div>
      <div class="brand-sub">Admin Console</div>
    </div>
  </div>

  <nav class="admin-nav">
    <div class="nav-section-label">Overview</div>
    
    <a href="<?= base_url('dashboard.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'dashboard.php') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">dashboard</span>
      <span>Dashboard</span>
    </a>

    <div class="nav-section-label">Inventory & Content</div>

    <a href="<?= base_url('products/index.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'products') && !str_contains($currentUri, 'status=expiring_soon') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">inventory_2</span>
      <span>Products</span>
    </a>

    <a href="<?= base_url('products/index.php?status=expiring_soon') ?>" class="admin-nav-item <?= str_contains($currentUri, 'status=expiring_soon') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">notifications_active</span>
      <span>Expiration Alerts</span>
    </a>

    <a href="<?= base_url('categories/index.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'categories') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">category</span>
      <span>Categories</span>
    </a>

    <a href="<?= base_url('announcements/index.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'announcements') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">campaign</span>
      <span>Announcements</span>
    </a>

    <div class="nav-section-label">System & Reports</div>

    <a href="<?= base_url('analytics/index.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'analytics') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">insights</span>
      <span>Analytics</span>
    </a>

    <a href="<?= base_url('settings/index.php') ?>" class="admin-nav-item <?= str_contains($currentUri, 'settings') ? 'active' : '' ?>">
      <span class="material-symbols-rounded">settings</span>
      <span>Settings</span>
    </a>
  </nav>

  <div class="admin-sidebar-footer">
    <div class="admin-user-info">
      <div class="admin-avatar">
        <?= strtoupper(substr($admin['name'] ?? 'A', 0, 1)) ?>
      </div>
      <div class="admin-user-details">
        <div class="admin-user-name"><?= e($admin['name'] ?? 'Admin') ?></div>
        <div class="admin-user-role"><?= e(ucfirst($admin['role'] ?? 'Admin')) ?></div>
      </div>
    </div>

    <a href="<?= base_url('logout.php') ?>" class="btn-action-icon danger" title="Sign Out">
      <span class="material-symbols-rounded" style="font-size: 18px;">logout</span>
    </a>
  </div>
</aside>
