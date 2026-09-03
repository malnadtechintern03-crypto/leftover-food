<?php
/**
 * Admin Panel - Global Header Component
 */

declare(strict_types=1);

require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/functions.php';

// Page Title fallback
$pageTitle = $pageTitle ?? 'Dashboard';
$currentAdmin = get_logged_in_admin();
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><?= e($pageTitle) ?> — Home Pantry Admin</title>
  
  <!-- Modern Typography & Icons -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
  
  <!-- Bootstrap 5.3 Framework -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <!-- Custom Admin Stylesheet -->
  <link rel="stylesheet" href="<?= base_url('assets/css/admin.css') ?>">
</head>
<body>
  <div class="sidebar-backdrop" id="sidebarBackdrop"></div>

  <div class="admin-wrapper">
    <!-- Include Sidebar Navigation -->
    <?php require_once __DIR__ . '/sidebar.php'; ?>

    <!-- Main Content Panel -->
    <main class="admin-main">
      <!-- Top Navigation Header -->
      <header class="admin-topbar">
        <div class="topbar-left">
          <button class="btn-sidebar-toggle" id="btnSidebarToggle" aria-label="Toggle navigation">
            <span class="material-symbols-rounded">menu</span>
          </button>
          <h1 class="page-title"><?= e($pageTitle) ?></h1>
        </div>

        <div class="topbar-right">
          <!-- Quick link to API documentation or view app -->
          <a href="<?= base_url('api/recipes.php') ?>" target="_blank" class="btn btn-sm btn-outline-secondary d-none d-md-inline-flex align-items-center gap-1 rounded-pill px-3">
            <span class="material-symbols-rounded" style="font-size: 16px;">api</span>
            <span>REST API</span>
          </a>

          <div class="dropdown">
            <button class="btn btn-sm btn-light dropdown-toggle d-flex align-items-center gap-2 rounded-pill px-3 py-1 border" type="button" data-bs-toggle="dropdown" aria-expanded="false">
              <span class="admin-avatar" style="width: 26px; height: 26px; font-size: 11px;">
                <?= strtoupper(substr($currentAdmin['name'] ?? 'A', 0, 1)) ?>
              </span>
              <span class="d-none d-sm-inline fw-bold"><?= e($currentAdmin['name'] ?? 'Admin') ?></span>
            </button>
            <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 rounded-4 mt-2">
              <li>
                <div class="px-3 py-2 border-bottom">
                  <div class="fw-bold small"><?= e($currentAdmin['name'] ?? 'Administrator') ?></div>
                  <div class="text-muted" style="font-size: 12px;"><?= e($currentAdmin['email'] ?? '') ?></div>
                </div>
              </li>
              <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="<?= base_url('settings/index.php') ?>"><span class="material-symbols-rounded fs-6">settings</span>Settings</a></li>
              <li><hr class="dropdown-divider"></li>
              <li><a class="dropdown-item py-2 text-danger d-flex align-items-center gap-2" href="<?= base_url('logout.php') ?>"><span class="material-symbols-rounded fs-6">logout</span>Logout</a></li>
            </ul>
          </div>
        </div>
      </header>

      <!-- Content Area -->
      <div class="admin-content">
        <!-- Render Flash Messages -->
        <?= render_flash() ?>
