<?php
/**
 * ScanSmart User Management - Edit User Account
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

$errors = [];
$name = $user['name'];
$email = $user['email'];
$role = $user['role'];
$status = $user['status'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security token expired.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $role = trim($_POST['role'] ?? 'user');
        $status = in_array($_POST['status'] ?? '', ['active', 'inactive', 'banned']) ? $_POST['status'] : 'active';
        $newPass = trim((string)($_POST['new_password'] ?? ''));

        if ($name === '' || $email === '') {
            $errors[] = 'Name and Email are required.';
        } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'Please enter a valid email address.';
        } else {
            $chk = $db->prepare('SELECT id FROM users WHERE email = ? AND id != ? LIMIT 1');
            $chk->execute([$email, $id]);
            if ($chk->fetch()) {
                $errors[] = "Email '{$email}' is already in use by another user.";
            }
        }

        if (empty($errors)) {
            if ($newPass !== '') {
                $hash = password_hash($newPass, PASSWORD_BCRYPT);
                $upd = $db->prepare('UPDATE users SET name = ?, email = ?, role = ?, status = ?, password = ? WHERE id = ?');
                $upd->execute([$name, $email, $role, $status, $hash, $id]);
                log_admin_activity('Reset User Password', "Reset password and profile for user '{$name}'");
            } else {
                $upd = $db->prepare('UPDATE users SET name = ?, email = ?, role = ?, status = ? WHERE id = ?');
                $upd->execute([$name, $email, $role, $status, $id]);
                log_admin_activity('Edit User', "Updated account profile for '{$name}'");
            }

            set_flash('success', "User account '{$name}' updated successfully.");
            header('Location: ' . base_url('users.php'));
            exit;
        }
    }
}

$pageTitle = 'Edit User — ' . $user['name'];
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-2xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h2 class="h4 fw-bold mb-1">Edit User Account</h2>
      <div class="text-muted small">User ID: <code><?= e($user['id']) ?></code></div>
    </div>
    <a href="<?= base_url('users.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-6">arrow_back</span>
      <span>Back</span>
    </a>
  </div>

  <?php if (!empty($errors)): ?>
    <div class="alert alert-danger rounded-4 mb-4">
      <ul class="mb-0 ps-3">
        <?php foreach ($errors as $err): ?>
          <li><?= e($err) ?></li>
        <?php endforeach; ?>
      </ul>
    </div>
  <?php endif; ?>

  <div class="card border-0 shadow-sm rounded-4 p-4 bg-white">
    <form method="POST" action="">
      <?= csrf_field() ?>

      <div class="mb-3">
        <label for="name" class="form-label small fw-bold">Full Name <span class="text-danger">*</span></label>
        <input type="text" name="name" id="name" class="form-control" value="<?= e($name) ?>" required>
      </div>

      <div class="mb-3">
        <label for="email" class="form-label small fw-bold">Email Address <span class="text-danger">*</span></label>
        <input type="email" name="email" id="email" class="form-control" value="<?= e($email) ?>" required>
      </div>

      <div class="row g-3 mb-3">
        <div class="col-md-6">
          <label for="role" class="form-label small fw-bold">Role</label>
          <select name="role" id="role" class="form-select">
            <option value="user" <?= $role === 'user' ? 'selected' : '' ?>>Standard User</option>
            <option value="premium" <?= $role === 'premium' ? 'selected' : '' ?>>Premium Member</option>
          </select>
        </div>

        <div class="col-md-6">
          <label for="status" class="form-label small fw-bold">Account Status</label>
          <select name="status" id="status" class="form-select">
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active</option>
            <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Inactive</option>
            <option value="banned" <?= $status === 'banned' ? 'selected' : '' ?>>Banned / Suspended</option>
          </select>
        </div>
      </div>

      <div class="mb-3 p-3 bg-light rounded-3 border">
        <label for="new_password" class="form-label small fw-bold mb-1">Reset Password</label>
        <div class="text-muted small mb-2">Leave blank to keep the current password unchanged.</div>
        <input type="password" name="new_password" id="new_password" class="form-control" placeholder="Enter new secure password...">
      </div>

      <div class="d-flex justify-content-end gap-2 mt-4 pt-3 border-top">
        <a href="<?= base_url('users.php') ?>" class="btn btn-light rounded-pill px-4">Cancel</a>
        <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Save Changes</button>
      </div>
    </form>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
