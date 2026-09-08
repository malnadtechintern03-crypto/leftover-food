<?php
/**
 * Admin Panel - User & Administrator Management
 * Lists all admin accounts with roles, statuses, last login, and management actions.
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();
$currentAdmin = get_logged_in_admin();

// Handle quick toggle status action
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'toggle_status') {
    if (!verify_csrf()) {
        set_flash('danger', 'Security validation failed.');
    } else {
        $userId = (int)($_POST['user_id'] ?? 0);
        if ($userId === (int)($currentAdmin['id'] ?? 0)) {
            set_flash('warning', 'You cannot deactivate your own currently active administrator account.');
        } else {
            $userStmt = $db->prepare('SELECT id, name, status, role FROM admins WHERE id = ? LIMIT 1');
            $userStmt->execute([$userId]);
            $targetUser = $userStmt->fetch();

            if ($targetUser) {
                // Safeguard: do not allow deactivating the last active super_admin
                if ($targetUser['role'] === 'super_admin' && $targetUser['status'] === 'active') {
                    $activeSuperCount = (int)$db->query("SELECT COUNT(*) FROM admins WHERE role = 'super_admin' AND status = 'active'")->fetchColumn();
                    if ($activeSuperCount <= 1) {
                        set_flash('danger', 'Cannot deactivate the only active Super Administrator.');
                        header('Location: ' . base_url('users/index.php'));
                        exit;
                    }
                }

                $newStatus = $targetUser['status'] === 'active' ? 'inactive' : 'active';
                $updateStmt = $db->prepare('UPDATE admins SET status = ? WHERE id = ?');
                $updateStmt->execute([$newStatus, $userId]);
                set_flash('success', "Status for '{$targetUser['name']}' updated to " . ucfirst($newStatus) . '.');
            } else {
                set_flash('danger', 'User account not found.');
            }
        }
    }
    header('Location: ' . base_url('users/index.php'));
    exit;
}

// Search and filters
$search = trim($_GET['search'] ?? '');
$roleFilter = trim($_GET['role'] ?? '');
$statusFilter = trim($_GET['status'] ?? '');

$where = [];
$params = [];

if ($search !== '') {
    $where[] = '(name LIKE ? OR email LIKE ?)';
    $params[] = "%{$search}%";
    $params[] = "%{$search}%";
}

if ($roleFilter !== '') {
    $where[] = 'role = ?';
    $params[] = $roleFilter;
}

if ($statusFilter !== '') {
    $where[] = 'status = ?';
    $params[] = $statusFilter;
}

$whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$usersStmt = $db->prepare("SELECT id, name, email, role, status, last_login, created_at FROM admins {$whereClause} ORDER BY role = 'super_admin' DESC, id ASC");
$usersStmt->execute($params);
$users = $usersStmt->fetchAll();

// Statistics
$totalAdmins = (int)$db->query('SELECT COUNT(*) FROM admins')->fetchColumn();
$activeAdmins = (int)$db->query("SELECT COUNT(*) FROM admins WHERE status = 'active'")->fetchColumn();
$superAdmins = (int)$db->query("SELECT COUNT(*) FROM admins WHERE role = 'super_admin'")->fetchColumn();

$pageTitle = 'User Management';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">User & Admin Accounts</h2>
    <p class="text-muted small mb-0">Manage system administrators, permissions, and security credentials.</p>
  </div>
  <a href="<?= base_url('users/create.php') ?>" class="btn btn-primary-custom btn-sm">
    <span class="material-symbols-rounded fs-6">person_add</span>
    <span>Add New Admin</span>
  </a>
</div>

<!-- Stat Cards -->
<div class="row g-3 mb-4">
  <div class="col-sm-4">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon emerald"><span class="material-symbols-rounded fs-3">group</span></div>
      <div>
        <div class="stat-label">Total Administrators</div>
        <div class="stat-value"><?= $totalAdmins ?></div>
      </div>
    </div>
  </div>
  <div class="col-sm-4">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon sapphire"><span class="material-symbols-rounded fs-3">check_circle</span></div>
      <div>
        <div class="stat-label">Active Accounts</div>
        <div class="stat-value"><?= $activeAdmins ?></div>
      </div>
    </div>
  </div>
  <div class="col-sm-4">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon amber"><span class="material-symbols-rounded fs-3">shield_person</span></div>
      <div>
        <div class="stat-label">Super Administrators</div>
        <div class="stat-value"><?= $superAdmins ?></div>
      </div>
    </div>
  </div>
</div>

<!-- Search & Filters -->
<div class="card-box mb-4 p-3 bg-light border">
  <form method="GET" action="" class="row g-2 align-items-center">
    <div class="col-md-5">
      <div class="input-group input-group-sm">
        <span class="input-group-text bg-white"><span class="material-symbols-rounded fs-6">search</span></span>
        <input type="text" name="search" class="form-control" placeholder="Search by name or email..." value="<?= e($search) ?>">
      </div>
    </div>
    <div class="col-md-3">
      <select name="role" class="form-select form-select-sm">
        <option value="">All Roles</option>
        <option value="super_admin" <?= $roleFilter === 'super_admin' ? 'selected' : '' ?>>Super Admin</option>
        <option value="admin" <?= $roleFilter === 'admin' ? 'selected' : '' ?>>Admin</option>
      </select>
    </div>
    <div class="col-md-2">
      <select name="status" class="form-select form-select-sm">
        <option value="">All Statuses</option>
        <option value="active" <?= $statusFilter === 'active' ? 'selected' : '' ?>>Active</option>
        <option value="inactive" <?= $statusFilter === 'inactive' ? 'selected' : '' ?>>Inactive</option>
      </select>
    </div>
    <div class="col-md-2 d-flex gap-2">
      <button type="submit" class="btn btn-secondary-custom btn-sm w-100">Filter</button>
      <?php if ($search !== '' || $roleFilter !== '' || $statusFilter !== ''): ?>
        <a href="<?= base_url('users/index.php') ?>" class="btn btn-light btn-sm" title="Reset Filters"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Users Table -->
<div class="card-box p-0">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0">
      <thead class="table-light">
        <tr>
          <th style="width: 50px;">#</th>
          <th>User</th>
          <th>Role</th>
          <th>Status</th>
          <th>Last Login</th>
          <th>Created</th>
          <th class="text-end" style="width: 140px;">Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($users)): ?>
          <tr>
            <td colspan="7" class="text-center py-5 text-muted">
              <span class="material-symbols-rounded fs-1 d-block mb-2 text-muted">person_off</span>
              No administrator accounts found matching criteria.
            </td>
          </tr>
        <?php else: ?>
          <?php foreach ($users as $idx => $user): ?>
            <tr>
              <td class="text-muted small"><?= $idx + 1 ?></td>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <div class="admin-avatar" style="width: 34px; height: 34px; font-size: 13px;">
                    <?= strtoupper(substr($user['name'] ?? 'U', 0, 1)) ?>
                  </div>
                  <div>
                    <div class="fw-bold">
                      <?= e($user['name']) ?>
                      <?php if ((int)$user['id'] === (int)($currentAdmin['id'] ?? 0)): ?>
                        <span class="badge bg-primary-subtle text-primary rounded-pill small ms-1">You</span>
                      <?php endif; ?>
                    </div>
                    <div class="text-muted small"><?= e($user['email']) ?></div>
                  </div>
                </div>
              </td>
              <td>
                <?php if ($user['role'] === 'super_admin'): ?>
                  <span class="badge bg-primary-subtle text-primary border border-primary-subtle rounded-pill">
                    <span class="material-symbols-rounded" style="font-size: 12px; vertical-align: -1px;">shield_person</span>
                    Super Admin
                  </span>
                <?php else: ?>
                  <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle rounded-pill">
                    Admin
                  </span>
                <?php endif; ?>
              </td>
              <td>
                <?php if ($user['status'] === 'active'): ?>
                  <span class="badge bg-success-subtle text-success border border-success-subtle rounded-pill">Active</span>
                <?php else: ?>
                  <span class="badge bg-danger-subtle text-danger border border-danger-subtle rounded-pill">Inactive</span>
                <?php endif; ?>
              </td>
              <td class="small text-muted">
                <?= $user['last_login'] ? date('M j, Y g:i A', strtotime($user['last_login'])) : '<span class="text-muted fst-italic">Never</span>' ?>
              </td>
              <td class="small text-muted">
                <?= date('M j, Y', strtotime($user['created_at'])) ?>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <!-- Toggle Status Form -->
                  <?php if ((int)$user['id'] !== (int)($currentAdmin['id'] ?? 0)): ?>
                    <form method="POST" action="" class="d-inline" onsubmit="return confirm('Toggle status for this account?');">
                      <?= csrf_field() ?>
                      <input type="hidden" name="action" value="toggle_status">
                      <input type="hidden" name="user_id" value="<?= (int)$user['id'] ?>">
                      <button type="submit" class="btn-action-icon" title="<?= $user['status'] === 'active' ? 'Deactivate' : 'Activate' ?>">
                        <span class="material-symbols-rounded" style="font-size: 18px; color: <?= $user['status'] === 'active' ? '#ef4444' : '#10b981' ?>;">
                          <?= $user['status'] === 'active' ? 'block' : 'check_circle' ?>
                        </span>
                      </button>
                    </form>
                  <?php endif; ?>

                  <a href="<?= base_url('users/edit.php?id=' . (int)$user['id']) ?>" class="btn-action-icon" title="Edit">
                    <span class="material-symbols-rounded" style="font-size: 18px;">edit</span>
                  </a>

                  <?php if ((int)$user['id'] !== (int)($currentAdmin['id'] ?? 0)): ?>
                    <a href="<?= base_url('users/delete.php?id=' . (int)$user['id'] . '&csrf_token=' . e(csrf_token())) ?>"
                       class="btn-action-icon danger"
                       title="Delete"
                       onclick="return confirm('Are you sure you want to permanently delete <?= e(addslashes($user['name'])) ?>?');">
                      <span class="material-symbols-rounded" style="font-size: 18px;">delete</span>
                    </a>
                  <?php endif; ?>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
