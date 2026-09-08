<?php
/**
 * ScanSmart Administrator Secure Login Screen
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

// If already logged in, redirect directly to dashboard
if (is_admin_logged_in()) {
    header('Location: ' . base_url('dashboard.php'));
    exit;
}

$errorMessage = '';
$userInput = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security token expired. Please try submitting again.';
    } else {
        $userInput = trim($_POST['username_or_email'] ?? '');
        $passwordInput = (string)($_POST['password'] ?? '');

        if ($userInput === '' || $passwordInput === '') {
            $errorMessage = 'Please enter both your username/email and password.';
        } else {
            if (admin_login($userInput, $passwordInput)) {
                $returnUrl = $_GET['return'] ?? '';
                $target = (!empty($returnUrl) && !str_starts_with($returnUrl, 'http')) 
                    ? urldecode($returnUrl) 
                    : base_url('dashboard.php');
                header('Location: ' . $target);
                exit;
            } else {
                $errorMessage = 'Invalid username/email or password. Please verify your credentials.';
            }
        }
    }
}

$isExpired = isset($_GET['expired']);
$isLoggedOut = isset($_GET['loggedout']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Admin Login — ScanSmart</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
  
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="<?= base_url('assets/css/admin.css') ?>">
</head>
<body class="bg-light d-flex align-items-center justify-content-center min-vh-100 py-5">
  <div class="container">
    <div class="row justify-content-center">
      <div class="col-12 col-sm-10 col-md-8 col-lg-5">
        
        <!-- Brand Header -->
        <div class="text-center mb-4">
          <div class="d-inline-flex align-items-center justify-content-center rounded-4 shadow-sm mb-3" style="width: 58px; height: 58px; background: linear-gradient(135deg, #10B981, #059669); color: white; box-shadow: 0 10px 25px rgba(16, 185, 129, 0.35);">
            <span class="material-symbols-rounded fs-2">barcode_scanner</span>
          </div>
          <h1 class="h3 fw-bold text-dark mb-1" style="letter-spacing: -0.5px;">ScanSmart</h1>
          <p class="text-muted small mb-0">“Scan Anything. Know Everything. Never Miss an Expiry.”</p>
        </div>

        <!-- Login Card -->
        <div class="card border-0 shadow-sm rounded-4 overflow-hidden">
          <div class="card-body p-4 p-sm-5">
            <div class="mb-4">
              <h2 class="h5 fw-bold text-dark mb-1">Admin Portal</h2>
              <p class="text-muted small">Sign in to manage universal product catalog, inventory & expiry tracking.</p>
            </div>

            <?php if ($isExpired): ?>
              <div class="alert alert-warning d-flex align-items-center gap-2 rounded-3 py-2 px-3 small mb-3" role="alert">
                <span class="material-symbols-rounded fs-5">timer</span>
                <div>Your session has expired due to 60 minutes of inactivity. Please sign in again.</div>
              </div>
            <?php endif; ?>

            <?php if ($isLoggedOut): ?>
              <div class="alert alert-info d-flex align-items-center gap-2 rounded-3 py-2 px-3 small mb-3" role="alert">
                <span class="material-symbols-rounded fs-5">info</span>
                <div>You have been successfully signed out.</div>
              </div>
            <?php endif; ?>

            <?php if (!empty($errorMessage)): ?>
              <div class="alert alert-danger d-flex align-items-center gap-2 rounded-3 py-2 px-3 small mb-3" role="alert">
                <span class="material-symbols-rounded fs-5">error</span>
                <div><?= e($errorMessage) ?></div>
              </div>
            <?php endif; ?>

            <form method="POST" action="" novalidate>
              <?= csrf_field() ?>

              <div class="mb-3">
                <label for="username_or_email" class="form-label fw-semibold small text-dark">Email or Username</label>
                <div class="input-group">
                  <span class="input-group-text bg-light border-end-0 text-muted">
                    <span class="material-symbols-rounded fs-5">person</span>
                  </span>
                  <input 
                    type="text" 
                    class="form-control bg-light border-start-0 ps-0" 
                    id="username_or_email" 
                    name="username_or_email" 
                    value="<?= e($userInput) ?>" 
                    placeholder="admin@scansmart.com" 
                    required 
                    autofocus
                  >
                </div>
              </div>

              <div class="mb-4">
                <label for="password" class="form-label fw-semibold small text-dark">Password</label>
                <div class="input-group">
                  <span class="input-group-text bg-light border-end-0 text-muted">
                    <span class="material-symbols-rounded fs-5">lock</span>
                  </span>
                  <input 
                    type="password" 
                    class="form-control bg-light border-start-0 ps-0" 
                    id="password" 
                    name="password" 
                    placeholder="••••••••" 
                    required
                  >
                </div>
              </div>

              <button type="submit" class="btn btn-primary w-100 py-2 fw-semibold rounded-3 d-flex align-items-center justify-content-center gap-2" style="background-color: #10B981; border-color: #10B981;">
                <span>Sign In to Admin Console</span>
                <span class="material-symbols-rounded fs-5">arrow_forward</span>
              </button>
            </form>

            <div class="mt-4 pt-3 border-top text-center">
              <div class="text-muted" style="font-size: 12px;">
                Default Super Admin: <code class="text-dark">admin@scansmart.com</code> / <code class="text-dark">admin123</code>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer Notice -->
        <div class="text-center mt-4">
          <small class="text-muted">&copy; <?= date('Y') ?> ScanSmart. Universal Product Scanner & Smart Inventory.</small>
        </div>

      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
