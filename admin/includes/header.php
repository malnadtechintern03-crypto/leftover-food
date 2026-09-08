<?php
/**
 * ScanSmart Admin Panel - Global Header Component
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
  <title><?= e($pageTitle) ?> — ScanSmart Admin</title>
  
  <!-- Modern Typography & Material Symbols -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
  
  <!-- Bootstrap 5.3 Framework -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <!-- Custom ScanSmart Admin Stylesheet -->
  <link rel="stylesheet" href="<?= base_url('assets/css/admin.css') ?>">
  <?php if (!empty($extraCss)): ?>
    <?= $extraCss ?>
  <?php endif; ?>
</head>
<body>
  <div class="sidebar-backdrop" id="sidebarBackdrop"></div>

  <div class="admin-wrapper">
    <!-- Include Sidebar Navigation -->
    <?php require_once __DIR__ . '/sidebar.php'; ?>

    <!-- Main Content Panel -->
    <main class="admin-main">
      <!-- Top Navigation Header -->
      <?php require_once __DIR__ . '/navbar.php'; ?>

      <!-- Content Area -->
      <div class="admin-content">
        <!-- Render Flash Messages -->
        <?= render_flash() ?>
