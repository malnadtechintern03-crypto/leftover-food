<?php
/**
 * Admin Panel - Edit Administrator Account
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();
$currentAdmin = get_logged_in_admin();
$userId = (int)($_GET['id'] ?? 0);

if ($userId <= 0) {
    set_flash('danger', 'Invalid user ID.');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

$userStmt = $db->prepare('SELECT id, name, email, role, status FROM admins WHERE id = ? LIMIT 1');
$userStmt->execute([$userId]);
$user = $userStmt->fetch();

if (!$user) {
    set_flash('danger', 'Administrator account not found.');
    header('Location: ' . base_url('users/index.php'));
    exit;
}

$errors = [];
$name = $user['name'];
$email = $user['email'];
$role = $user['role'];
$status = $user['status'];
$isSelf = ((int)$currentAdmin['id'] === $userId);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security validation failed. Please try again.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $password = (string)($_POST['password'] ?? '');
        $confirmPassword = (string)($_POST['confirm_password'] ?? '');
        $role = trim($_POST['role'] ?? $user['role']);
        $status = trim($_POST['status'] ?? $user['status']);

        if ($name === '') {
            $errors[] = 'Full name is required.';
        }

        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'A valid email address is required.';
        } else {
            // Check uniqueness if email changed
            $checkStmt = $db->prepare('SELECT id FROM admins WHERE email = ? AND id != ? LIMIT 1');
            $checkStmt->execute([$email, $userId]);
            if ($checkStmt->fetch()) {
                $errors[] = 'Another account already uses this email address.';
            }
        }

        // Safeguard self: cannot deactivate own account
        if ($isSelf && $status !== 'active') {
            $errors[] = 'You cannot deactivate your own currently active account.';
            $status = 'active';
        }

        // Safeguard last super_admin: cannot demote last super_admin
        if ($user['role'] === 'super_admin' && $role !== 'super_admin') {
            $superCount = (int)$db->query("SELECT COUNT(*) FROM admins WHERE role = 'super_admin' AND status = 'active'")->fetchColumn();
            if ($superCount <= 1) {
                $errors[] = 'Cannot demote the only remaining Super Administrator.';
                $role = 'super_admin';
            }
        }

        // Password change validation
        $updatePassword = false;
        if ($password !== '') {
            if (strlen($password) < 6) {
                $errors[] = 'New password must be at least 6 characters long.';
            } elseif ($password !== $confirmPassword) {
                $errors[] = 'New passwords do not match.';
            } else {
                $updatePassword = true;
            }
        }

        if (!in_array($role, ['admin', 'super_admin'], true)) {
            $role = 'admin';
        }

        if (!in_array($status, ['active', 'inactive'], true)) {
            $status = 'active';
        }

        if (empty($errors)) {
            if ($updatePassword) {
                $hash = password_hash($password, PASSWORD_BCRYPT);
                $stmt = $db->prepare('
                    UPDATE admins
                    SET name = ?, email = ?, password = ?, role = ?, status = ?, updated_at = NOW()
                    WHERE id = ?
                ');
                $stmt->execute([$name, $email, $hash, $role, $status, $userId]);
            } else {
                $stmt = $db->prepare('
                    UPDATE admins
                    SET name = ?, email = ?, role = ?, status = ?, updated_at = NOW()
                    WHERE id = ?
                ');
                $stmt->execute([$name, $email, $role, $status, $userId]);
            }

            // Update session if user updated their own info
            if ($isSelf) {
                $_SESSION['admin_name'] = $name;
                $_SESSION['admin_email'] = $email;
                $_SESSION['admin_role'] = $role;
            }

            set_flash('success', "Administrator account '{$name}' updated successfully.");
            header('Location: ' . base_url('users/index.php'));
            exit;
        }
    }
}

$pageTitle = 'Edit Administrator';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex align-items-center justify-content-between mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Edit Administrator</h2>
    <p class="text-muted small mb-0">Update account credentials, role permissions, and access status.</p>
  </div>
  <a href="<?= base_url('users/index.php') ?>" class="btn btn-secondary-custom btn-sm">
    <span class="material-symbols-rounded fs-6">arrow_back</span>
    <span>Back to Users</span>
  </a>
</div>

<?php if (!empty($errors)): ?>
  <div class="alert alert-danger rounded-3 mb-4">
    <ul class="mb-0 ps-3">
      <?php foreach ($errors as $err): ?>
        <li><?= e($err) ?></li>
      <?php endforeach; ?>
    </ul>
  </div>
<?php endif; ?>

<div class="card-box" style="max-width: 720px;">
  <form method="POST" action="">
    <?= csrf_field() ?>

    <div class="row g-3">
      <div class="col-md-12">
        <label for="name" class="form-label fw-bold">Full Name <span class="text-danger">*</span></label>
        <input type="text" class="form-control" id="name" name="name" value="<?= e($name) ?>" required>
      </div>

      <div class="col-md-12">
        <label for="email" class="form-label fw-bold">Email Address <span class="text-danger">*</span></label>
        <input type="email" class="form-control" id="email" name="email" value="<?= e($email) ?>" required>
        <div class="form-text">Primary login email address.</div>
      </div>

      <div class="col-md-12">
        <div class="p-3 bg-light rounded-3 border">
          <div class="fw-bold small mb-2 text-primary">Change Password (Leave blank to keep current)</div>
          <div class="row g-3">
            <div class="col-md-6">
              <label for="password" class="form-label small fw-bold">New Password</label>
              <input type="password" class="form-control" id="password" name="password" minlength="6" placeholder="Leave blank if unchanged">
            </div>
            <div class="col-md-6">
              <label for="confirm_password" class="form-label small fw-bold">Confirm New Password</label>
              <input type="password" class="form-control" id="confirm_password" name="confirm_password" minlength="6" placeholder="Re-enter new password">
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <label for="role" class="form-label fw-bold">Access Role</label>
        <select class="form-select" id="role" name="role">
          <option value="admin" <?= $role === 'admin' ? 'selected' : '' ?>>Admin — Standard catalog & recipe operations</option>
          <option value="super_admin" <?= $role === 'super_admin' ? 'selected' : '' ?>>Super Admin — Full system & user administration</option>
        </select>
      </div>

      <div class="col-md-6">
        <label for="status" class="form-label fw-bold">Account Status</label>
        <select class="form-select" id="status" name="status" <?= $isSelf ? 'disabled' : '' ?>>
          <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active — Can log in</option>
          <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Inactive — Suspended</option>
        </select>
        <?php if ($isSelf): ?>
          <input type="hidden" name="status" value="active">
          <div class="form-text text-muted">You cannot deactivate your own logged-in account.</div>
        <?php endif; ?>
      </div>
    </div>

    <div class="d-flex gap-2 justify-content-end mt-4 pt-3 border-top">
      <a href="<?= base_url('users/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
      <button type="submit" class="btn btn-primary-custom px-4">
        <span class="material-symbols-rounded fs-6">save</span>
        <span>Update Administrator</span>
      </button>
    </div>
  </form>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
