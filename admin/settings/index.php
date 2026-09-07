<?php
/**
 * Admin Panel - Settings & Profile Management
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();
$currentAdmin = get_logged_in_admin();
$adminId = (int)$currentAdmin['id'];

$successMessage = '';
$errorMessage = '';

// Handle Password Change & Profile Update
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security validation failed. Please try again.';
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'change_password') {
            $currentPassword = (string)($_POST['current_password'] ?? '');
            $newPassword = (string)($_POST['new_password'] ?? '');
            $confirmPassword = (string)($_POST['confirm_password'] ?? '');

            if ($currentPassword === '' || $newPassword === '') {
                $errorMessage = 'All password fields are required.';
            } elseif (strlen($newPassword) < 6) {
                $errorMessage = 'New password must be at least 6 characters long.';
            } elseif ($newPassword !== $confirmPassword) {
                $errorMessage = 'New password and confirmation do not match.';
            } else {
                // Verify current password
                $stmt = $db->prepare('SELECT password FROM admins WHERE id = ? LIMIT 1');
                $stmt->execute([$adminId]);
                $hash = $stmt->fetchColumn();

                if (!$hash || !password_verify($currentPassword, $hash)) {
                    $errorMessage = 'Incorrect current password.';
                } else {
                    $newHash = password_hash($newPassword, PASSWORD_BCRYPT);
                    $updateStmt = $db->prepare('UPDATE admins SET password = ? WHERE id = ?');
                    $updateStmt->execute([$newHash, $adminId]);
                    $successMessage = 'Password changed successfully.';
                }
            }
        } elseif ($action === 'update_settings') {
            $currency = trim($_POST['default_currency'] ?? '₹');
            $warningDays = trim($_POST['expiry_warning_days'] ?? '2');
            $adminEmail = trim($_POST['admin_email'] ?? '');

            $upsert = $db->prepare('
                INSERT INTO app_settings (setting_key, setting_value) 
                VALUES (?, ?) 
                ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)
            ');
            $upsert->execute(['default_currency', $currency]);
            $upsert->execute(['expiry_warning_days', $warningDays]);
            if ($adminEmail !== '') {
                $upsert->execute(['admin_email', $adminEmail]);
            }

            $successMessage = 'System settings updated successfully.';
        }
    }
}

// Fetch current app_settings
$settingsRows = $db->query('SELECT setting_key, setting_value FROM app_settings')->fetchAll();
$settings = [];
foreach ($settingsRows as $r) {
    $settings[$r['setting_key']] = $r['setting_value'];
}

$pageTitle = 'Settings & Profile';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="mb-4">
  <h2 class="fw-bold mb-1" style="font-size: 20px;">System Settings</h2>
  <p class="text-muted small mb-0">Configure administrator account, system defaults, and inspect localhost environment.</p>
</div>

<?php if (!empty($successMessage)): ?>
  <div class="alert alert-success d-flex align-items-center mb-4 py-2 px-3 small rounded-3" role="alert">
    <span class="material-symbols-rounded me-2 fs-5">check_circle</span>
    <div><?= e($successMessage) ?></div>
  </div>
<?php endif; ?>

<?php if (!empty($errorMessage)): ?>
  <div class="alert alert-danger d-flex align-items-center mb-4 py-2 px-3 small rounded-3" role="alert">
    <span class="material-symbols-rounded me-2 fs-5">error</span>
    <div><?= e($errorMessage) ?></div>
  </div>
<?php endif; ?>

<div class="row g-4">
  <!-- Admin Security & Password Change -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <div class="d-flex align-items-center gap-2 mb-3 pb-2 border-bottom">
        <span class="material-symbols-rounded text-success fs-5">lock</span>
        <h3 class="fw-bold mb-0" style="font-size: 16px;">Change Admin Password</h3>
      </div>

      <form method="POST" action="">
        <?= csrf_field() ?>
        <input type="hidden" name="action" value="change_password">

        <div class="mb-3">
          <label for="current_password" class="form-label">Current Password <span class="text-danger">*</span></label>
          <input type="password" class="form-control" id="current_password" name="current_password" required placeholder="••••••••">
        </div>

        <div class="mb-3">
          <label for="new_password" class="form-label">New Password <span class="text-danger">*</span></label>
          <input type="password" class="form-control" id="new_password" name="new_password" required minlength="6" placeholder="At least 6 characters">
        </div>

        <div class="mb-4">
          <label for="confirm_password" class="form-label">Confirm New Password <span class="text-danger">*</span></label>
          <input type="password" class="form-control" id="confirm_password" name="confirm_password" required placeholder="Repeat new password">
        </div>

        <button type="submit" class="btn btn-primary-custom">
          <span class="material-symbols-rounded fs-6">key</span>
          <span>Update Password</span>
        </button>
      </form>
    </div>
  </div>

  <!-- Application Default Settings -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <div class="d-flex align-items-center gap-2 mb-3 pb-2 border-bottom">
        <span class="material-symbols-rounded text-success fs-5">tune</span>
        <h3 class="fw-bold mb-0" style="font-size: 16px;">Pantry Defaults</h3>
      </div>

      <form method="POST" action="">
        <?= csrf_field() ?>
        <input type="hidden" name="action" value="update_settings">

        <div class="mb-3">
          <label for="default_currency" class="form-label">Default Currency Symbol</label>
          <input type="text" class="form-control" id="default_currency" name="default_currency" value="<?= e($settings['default_currency'] ?? '₹') ?>" placeholder="₹, $, €">
          <div class="form-text">Used for pricing display across mobile pantry inventory.</div>
        </div>

        <div class="mb-3">
          <label for="expiry_warning_days" class="form-label">Urgent Expiry Threshold (Days)</label>
          <input type="number" class="form-control" id="expiry_warning_days" name="expiry_warning_days" value="<?= e($settings['expiry_warning_days'] ?? '2') ?>" min="1" max="14">
          <div class="form-text">Items expiring within this threshold trigger high-priority alerts.</div>
        </div>

        <div class="mb-4">
          <label for="admin_email" class="form-label">System Notification Email</label>
          <input type="email" class="form-control" id="admin_email" name="admin_email" value="<?= e($settings['admin_email'] ?? 'admin@homepantry.com') ?>">
        </div>

        <button type="submit" class="btn btn-primary-custom">
          <span class="material-symbols-rounded fs-6">save</span>
          <span>Save System Settings</span>
        </button>
      </form>
    </div>
  </div>

  <!-- Localhost & Database Environment Inspector -->
  <div class="col-12">
    <div class="card-box">
      <h3 class="fw-bold mb-3" style="font-size: 16px;">Localhost Deployment Info</h3>
      
      <div class="row g-3">
        <div class="col-md-3">
          <div class="p-3 bg-light rounded-3 border">
            <div class="small text-muted mb-1">Local Host URL</div>
            <div class="fw-bold text-dark font-monospace small">http://localhost/grocery_admin/</div>
          </div>
        </div>

        <div class="col-md-3">
          <div class="p-3 bg-light rounded-3 border">
            <div class="small text-muted mb-1">MySQL Database</div>
            <div class="fw-bold text-dark font-monospace small">grocery_admin_db (Port 3306)</div>
          </div>
        </div>

        <div class="col-md-3">
          <div class="p-3 bg-light rounded-3 border">
            <div class="small text-muted mb-1">PHP Engine</div>
            <div class="fw-bold text-dark font-monospace small">v<?= PHP_VERSION ?> (XAMPP)</div>
          </div>
        </div>

        <div class="col-md-3">
          <div class="p-3 bg-light rounded-3 border">
            <div class="small text-muted mb-1">REST API Base</div>
            <div class="fw-bold text-dark font-monospace small">/api/recipes.php</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
