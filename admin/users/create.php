<?php
/**
 * Admin Panel - Create New Administrator Account
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();
$errors = [];

$name = '';
$email = '';
$role = 'admin';
$status = 'active';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security validation failed. Please try again.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $email = trim($_POST['email'] ?? '');
        $password = (string)($_POST['password'] ?? '');
        $confirmPassword = (string)($_POST['confirm_password'] ?? '');
        $role = trim($_POST['role'] ?? 'admin');
        $status = trim($_POST['status'] ?? 'active');

        if ($name === '') {
            $errors[] = 'Full name is required.';
        }

        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors[] = 'A valid email address is required.';
        } else {
            // Check uniqueness
            $checkStmt = $db->prepare('SELECT id FROM admins WHERE email = ? LIMIT 1');
            $checkStmt->execute([$email]);
            if ($checkStmt->fetch()) {
                $errors[] = 'An administrator account with this email already exists.';
            }
        }

        if (strlen($password) < 6) {
            $errors[] = 'Password must be at least 6 characters long.';
        } elseif ($password !== $confirmPassword) {
            $errors[] = 'Passwords do not match.';
        }

        if (!in_array($role, ['admin', 'super_admin'], true)) {
            $role = 'admin';
        }

        if (!in_array($status, ['active', 'inactive'], true)) {
            $status = 'active';
        }

        if (empty($errors)) {
            $hash = password_hash($password, PASSWORD_BCRYPT);
            $stmt = $db->prepare('
                INSERT INTO admins (name, email, password, role, status, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, NOW(), NOW())
            ');
            $stmt->execute([$name, $email, $hash, $role, $status]);

            set_flash('success', "Administrator account for '{$name}' created successfully.");
            header('Location: ' . base_url('users/index.php'));
            exit;
        }
    }
}

$pageTitle = 'Add New Administrator';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex align-items-center justify-content-between mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Create Administrator</h2>
    <p class="text-muted small mb-0">Add a new admin or staff member with access to the console.</p>
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
        <input type="text" class="form-control" id="name" name="name" value="<?= e($name) ?>" placeholder="e.g. Sarah Jenkins" required>
      </div>

      <div class="col-md-12">
        <label for="email" class="form-label fw-bold">Email Address <span class="text-danger">*</span></label>
        <input type="email" class="form-control" id="email" name="email" value="<?= e($email) ?>" placeholder="sarah@homepantry.com" required>
        <div class="form-text">Used for admin login and administrative notifications.</div>
      </div>

      <div class="col-md-6">
        <label for="password" class="form-label fw-bold">Password <span class="text-danger">*</span></label>
        <input type="password" class="form-control" id="password" name="password" minlength="6" placeholder="Minimum 6 characters" required>
      </div>

      <div class="col-md-6">
        <label for="confirm_password" class="form-label fw-bold">Confirm Password <span class="text-danger">*</span></label>
        <input type="password" class="form-control" id="confirm_password" name="confirm_password" minlength="6" placeholder="Re-enter password" required>
      </div>

      <div class="col-md-6">
        <label for="role" class="form-label fw-bold">Access Role</label>
        <select class="form-select" id="role" name="role">
          <option value="admin" <?= $role === 'admin' ? 'selected' : '' ?>>Admin — Standard inventory & recipe management</option>
          <option value="super_admin" <?= $role === 'super_admin' ? 'selected' : '' ?>>Super Admin — Full system & user administration</option>
        </select>
      </div>

      <div class="col-md-6">
        <label for="status" class="form-label fw-bold">Account Status</label>
        <select class="form-select" id="status" name="status">
          <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active — Can log in immediately</option>
          <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Inactive — Suspended / Deactivated</option>
        </select>
      </div>
    </div>

    <div class="d-flex gap-2 justify-content-end mt-4 pt-3 border-top">
      <a href="<?= base_url('users/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
      <button type="submit" class="btn btn-primary-custom px-4">
        <span class="material-symbols-rounded fs-6">save</span>
        <span>Create Administrator</span>
      </button>
    </div>
  </form>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
