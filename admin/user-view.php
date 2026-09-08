<?php
/**
 * ScanSmart User Management - View User Profile & Activity
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin');

$db = Database::getConnection();

$id = trim((string)($_GET['id'] ?? ''));
if ($id === '') {
    set_flash('error', 'User ID is missing.');
    header('Location: ' . base_url('users.php'));
    exit;
}

$stmt = $db->prepare('SELECT * FROM users WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$user = $stmt->fetch();

if (!$user) {
    set_flash('error', 'User not found.');
    header('Location: ' . base_url('users.php'));
    exit;
}

// Fetch user inventory
$invStmt = $db->prepare('SELECT * FROM products WHERE user_id = ? ORDER BY created_at DESC LIMIT 20');
$invStmt->execute([$id]);
$userProducts = $invStmt->fetchAll();

// Fetch user scans
$scanStmt = $db->prepare('SELECT * FROM scan_history WHERE user_id = ? ORDER BY scan_date DESC, scan_time DESC LIMIT 20');
$scanStmt->execute([$id]);
$userScans = $scanStmt->fetchAll();

$pageTitle = $user['name'] . ' — User Profile';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-4xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <div class="d-flex align-items-center gap-2 mb-1">
        <h2 class="h4 fw-bold mb-0"><?= e($user['name']) ?></h2>
        <span class="badge-status <?= $user['status'] === 'active' ? 'active' : 'inactive' ?>"><?= e(ucfirst($user['status'])) ?></span>
      </div>
      <div class="text-muted small">User ID: <code><?= e($user['id']) ?></code> &bull; Email: <strong><?= e($user['email']) ?></strong></div>
    </div>
    <div class="d-flex gap-2">
      <a href="<?= base_url('user-edit.php?id=' . urlencode($user['id'])) ?>" class="btn btn-primary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
        <span class="material-symbols-rounded fs-6">edit</span>
        <span>Edit Account</span>
      </a>
      <a href="<?= base_url('users.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">arrow_back</span>
        <span>Back to Users</span>
      </a>
    </div>
  </div>

  <div class="row g-4 mb-4">
    <div class="col-md-4">
      <div class="card-stat-modern">
        <div class="card-stat-icon" style="background: #ECFDF5; color: #10B981;"><span class="material-symbols-rounded">inventory_2</span></div>
        <div>
          <div class="card-stat-val"><?= count($userProducts) ?></div>
          <div class="card-stat-lbl">Active Products</div>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card-stat-modern">
        <div class="card-stat-icon" style="background: #EFF6FF; color: #3B82F6;"><span class="material-symbols-rounded">qr_code_scanner</span></div>
        <div>
          <div class="card-stat-val"><?= count($userScans) ?></div>
          <div class="card-stat-lbl">Scans Recorded</div>
        </div>
      </div>
    </div>
    <div class="col-md-4">
      <div class="card-stat-modern">
        <div class="card-stat-icon" style="background: #F5F3FF; color: #8B5CF6;"><span class="material-symbols-rounded">calendar_month</span></div>
        <div>
          <div class="card-stat-val" style="font-size: 16px;"><?= format_date($user['created_at']) ?></div>
          <div class="card-stat-lbl">Member Since</div>
        </div>
      </div>
    </div>
  </div>

  <!-- User's Products -->
  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
    <div class="p-3 px-4 border-bottom">
      <h5 class="fw-bold mb-0">Saved Pantry Inventory</h5>
    </div>
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
        <thead class="table-light">
          <tr>
            <th>Product</th>
            <th>Category</th>
            <th>Quantity</th>
            <th>Expiry Date</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($userProducts)): ?>
            <tr><td colspan="5" class="text-center py-4 text-muted">This user has not cataloged any products yet.</td></tr>
          <?php else: ?>
            <?php foreach ($userProducts as $p): ?>
              <tr>
                <td class="fw-bold"><?= e($p['name']) ?></td>
                <td><span class="badge bg-light text-dark rounded-pill border"><?= e($p['category']) ?></span></td>
                <td><?= (float)$p['quantity'] ?> <?= e($p['unit']) ?></td>
                <td><?= format_date($p['expiry_date']) ?></td>
                <td><span class="badge-status <?= strtolower(str_replace(' ', '-', $p['expiry_status'])) ?>"><?= e($p['expiry_status']) ?></span></td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>

  <!-- User's Scan History -->
  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
    <div class="p-3 px-4 border-bottom">
      <h5 class="fw-bold mb-0">Recent Mobile Scans</h5>
    </div>
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
        <thead class="table-light">
          <tr>
            <th>Barcode</th>
            <th>Product Name</th>
            <th>Scan Type</th>
            <th>Result</th>
            <th>Date & Time</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($userScans)): ?>
            <tr><td colspan="5" class="text-center py-4 text-muted">No barcode scans recorded for this user.</td></tr>
          <?php else: ?>
            <?php foreach ($userScans as $s): ?>
              <tr>
                <td><span class="barcode-pill"><?= e($s['barcode']) ?></span></td>
                <td class="fw-bold"><?= e($s['product_name'] ?: 'Unknown Item') ?></td>
                <td><span class="badge bg-light text-dark rounded-pill"><?= e($s['scan_type']) ?></span></td>
                <td>
                  <?php if ((int)$s['product_found'] === 1): ?>
                    <span class="badge bg-success-subtle text-success rounded-pill">Found</span>
                  <?php else: ?>
                    <span class="badge bg-warning-subtle text-warning rounded-pill">Uncataloged</span>
                  <?php endif; ?>
                </td>
                <td class="text-muted"><?= format_date($s['scan_date']) ?> <?= substr($s['scan_time'], 0, 5) ?></td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
