<?php
/**
 * ScanSmart User Management - Mobile Application Accounts
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin');

$db = Database::getConnection();

// Toggle Status (Activate / Deactivate)
if (isset($_GET['toggle']) && can_manage_users()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $userId = trim($_GET['toggle']);
        $stmt = $db->prepare('SELECT id, status, name FROM users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $u = $stmt->fetch();
        if ($u) {
            $newStatus = $u['status'] === 'active' ? 'inactive' : 'active';
            $db->prepare('UPDATE users SET status = ? WHERE id = ?')->execute([$newStatus, $userId]);
            log_admin_activity('Toggle User Status', "Changed user '{$u['name']}' status to {$newStatus}");
            set_flash('success', "User '{$u['name']}' status set to {$newStatus}.");
        }
    }
    header('Location: ' . base_url('users.php'));
    exit;
}

// Search & Filter
$search = trim((string)($_GET['q'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? ''));

$where = [];
$params = [];

if ($search !== '') {
    $where[] = '(name LIKE ? OR email LIKE ? OR id LIKE ?)';
    $params = array_merge($params, ["%{$search}%", "%{$search}%", "%{$search}%"]);
}

if ($statusFilter !== '') {
    $where[] = 'status = ?';
    $params[] = $statusFilter;
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("
    SELECT u.*,
           (SELECT COUNT(*) FROM products WHERE user_id = u.id AND status != 'Archived') AS real_product_count,
           (SELECT COUNT(*) FROM scan_history WHERE user_id = u.id) AS real_scan_count
    FROM users u
    {$whereSql}
    ORDER BY u.created_at DESC
");
$stmt->execute($params);
$users = $stmt->fetchAll();

$pageTitle = 'Mobile App Users';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Registered App Users</h2>
    <p class="text-muted small mb-0">Manage mobile app user accounts, statuses, product inventory counts, and scan activity.</p>
  </div>
</div>

<!-- Search & Filters -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <div class="col-md-6">
      <label for="q" class="form-label small fw-bold text-muted">Search Users</label>
      <div class="input-group">
        <span class="input-group-text bg-light border-end-0 text-muted"><span class="material-symbols-rounded fs-5">search</span></span>
        <input type="text" name="q" id="q" value="<?= e($search) ?>" class="form-control bg-light border-start-0" placeholder="Name, email address, or user ID...">
      </div>
    </div>

    <div class="col-6 col-md-4">
      <label for="status" class="form-label small fw-bold text-muted">Account Status</label>
      <select name="status" id="status" class="form-select bg-light">
        <option value="">All Statuses</option>
        <option value="active" <?= $statusFilter === 'active' ? 'selected' : '' ?>>Active</option>
        <option value="inactive" <?= $statusFilter === 'inactive' ? 'selected' : '' ?>>Inactive</option>
        <option value="banned" <?= $statusFilter === 'banned' ? 'selected' : '' ?>>Banned</option>
      </select>
    </div>

    <div class="col-6 col-md-2 d-flex gap-2">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter</button>
      <?php if ($search !== '' || $statusFilter !== ''): ?>
        <a href="<?= base_url('users.php') ?>" class="btn btn-light border" title="Reset"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Users Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>User</th>
          <th>User ID</th>
          <th>Role</th>
          <th>Status</th>
          <th>Products Saved</th>
          <th>Total Scans</th>
          <th>Registered</th>
          <th>Last Login</th>
          <th width="120" class="text-end">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($users)): ?>
          <tr><td colspan="9" class="text-center py-5 text-muted">No user accounts found matching query.</td></tr>
        <?php else: ?>
          <?php foreach ($users as $u): ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <div class="rounded-circle d-flex align-items-center justify-content-center fw-bold text-white shadow-xs" style="width: 36px; height: 36px; background: linear-gradient(135deg, #3B82F6, #1D4ED8); font-size: 13px;">
                    <?= strtoupper(substr($u['name'], 0, 1)) ?>
                  </div>
                  <div>
                    <div class="fw-bold text-dark"><?= e($u['name']) ?></div>
                    <div class="text-muted small"><?= e($u['email']) ?></div>
                  </div>
                </div>
              </td>
              <td><code><?= e($u['id']) ?></code></td>
              <td><span class="badge bg-light text-dark rounded-pill border"><?= e(ucfirst($u['role'])) ?></span></td>
              <td>
                <?php if ($u['status'] === 'active'): ?>
                  <span class="badge-status active">Active</span>
                <?php elseif ($u['status'] === 'banned'): ?>
                  <span class="badge-status rejected">Banned</span>
                <?php else: ?>
                  <span class="badge-status inactive">Inactive</span>
                <?php endif; ?>
              </td>
              <td class="fw-semibold"><?= (int)$u['real_product_count'] ?> items</td>
              <td class="fw-semibold"><?= (int)$u['real_scan_count'] ?> scans</td>
              <td class="text-muted"><?= format_date($u['created_at']) ?></td>
              <td class="text-muted"><?= format_date($u['last_login'], 'M d, H:i') ?></td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <a href="<?= base_url('user-view.php?id=' . urlencode($u['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="View Profile & Inventory">
                    <span class="material-symbols-rounded" style="font-size: 16px;">visibility</span>
                  </a>
                  <a href="<?= base_url('user-edit.php?id=' . urlencode($u['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="Edit Account">
                    <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                  </a>
                  <a href="<?= base_url('users.php?toggle=' . urlencode($u['id']) . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2 text-warning" title="<?= $u['status'] === 'active' ? 'Deactivate' : 'Activate' ?>">
                    <span class="material-symbols-rounded" style="font-size: 16px;"><?= $u['status'] === 'active' ? 'block' : 'check_circle' ?></span>
                  </a>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
