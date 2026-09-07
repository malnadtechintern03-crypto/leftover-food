<?php
/**
 * Administrator Secure Login Screen
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
$emailInput = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security token expired. Please try submitting again.';
    } else {
        $emailInput = trim($_POST['email'] ?? '');
        $passwordInput = (string)($_POST['password'] ?? '');

        if ($emailInput === '' || $passwordInput === '') {
            $errorMessage = 'Please enter both your email and password.';
        } else {
            if (admin_login($emailInput, $passwordInput)) {
                $returnUrl = $_GET['return'] ?? '';
                $target = (!empty($returnUrl) && !str_starts_with($returnUrl, 'http')) 
                    ? urldecode($returnUrl) 
                    : base_url('dashboard.php');
                header('Location: ' . $target);
                exit;
            } else {
                $errorMessage = 'Invalid email address or password. Please verify your credentials.';
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
  <title>Admin Login — Home Pantry</title>
  
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" />
  
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <style>
    body {
      font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
      background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .login-card {
      background: #FFFFFF;
      border-radius: 24px;
      padding: 40px;
      width: 100%;
      max-width: 440px;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.35);
    }
    .brand-icon-box {
      width: 52px;
      height: 52px;
      background: linear-gradient(135deg, #10B981, #059669);
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #FFFFFF;
      margin: 0 auto 16px auto;
      box-shadow: 0 10px 15px -3px rgba(16, 185, 129, 0.3);
    }
    .form-control {
      padding: 12px 16px;
      border-radius: 12px;
      border: 1px solid #E2E8F0;
      font-size: 14.5px;
    }
    .form-control:focus {
      border-color: #10B981;
      box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.15);
    }
    .btn-login {
      background: #10B981;
      color: #FFFFFF;
      border: none;
      padding: 13px;
      font-size: 15px;
      font-weight: 700;
      border-radius: 12px;
      width: 100%;
      transition: background 0.2s;
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
    }
    .btn-login:hover {
      background: #059669;
      color: #FFFFFF;
    }
  </style>
</head>
<body>
  <div class="login-card">
    <div class="text-center mb-4">
      <div class="brand-icon-box">
        <span class="material-symbols-rounded fs-2">kitchen</span>
      </div>
      <h2 class="fw-bold mb-1" style="font-size: 22px; color: #0F172A;">Home Pantry</h2>
      <p class="text-muted small">Grocery & Expiry Management Admin</p>
    </div>

    <?php if ($isExpired): ?>
      <div class="alert alert-warning d-flex align-items-center mb-3 py-2 px-3 small rounded-3" role="alert">
        <span class="material-symbols-rounded me-2 fs-5">timer</span>
        <div>Your session timed out. Please log in again.</div>
      </div>
    <?php endif; ?>

    <?php if ($isLoggedOut): ?>
      <div class="alert alert-info d-flex align-items-center mb-3 py-2 px-3 small rounded-3" role="alert">
        <span class="material-symbols-rounded me-2 fs-5">info</span>
        <div>You have been safely signed out.</div>
      </div>
    <?php endif; ?>

    <?php if (!empty($errorMessage)): ?>
      <div class="alert alert-danger d-flex align-items-center mb-3 py-2 px-3 small rounded-3" role="alert">
        <span class="material-symbols-rounded me-2 fs-5">error</span>
        <div><?= e($errorMessage) ?></div>
      </div>
    <?php endif; ?>

    <form method="POST" action="">
      <?= csrf_field() ?>

      <div class="mb-3">
        <label for="email" class="form-label fw-bold text-dark small">Admin Email</label>
        <div class="input-group">
          <span class="input-group-text bg-light border-end-0 rounded-start-3 text-muted">
            <span class="material-symbols-rounded fs-5">mail</span>
          </span>
          <input type="email" class="form-control border-start-0" id="email" name="email" value="<?= e($emailInput ?: 'admin@homepantry.com') ?>" required autofocus placeholder="name@homepantry.com">
        </div>
      </div>

      <div class="mb-4">
        <label for="password" class="form-label fw-bold text-dark small">Password</label>
        <div class="input-group">
          <span class="input-group-text bg-light border-end-0 rounded-start-3 text-muted">
            <span class="material-symbols-rounded fs-5">lock</span>
          </span>
          <input type="password" class="form-control border-start-0" id="password" name="password" required placeholder="••••••••">
        </div>
      </div>

      <button type="submit" class="btn btn-login">
        Sign In to Console
      </button>

      <div class="mt-4 pt-3 border-top text-center text-muted" style="font-size: 12px;">
        Local Development: <code>admin@homepantry.com</code> / <code>admin123</code>
      </div>
    </form>
  </div>
</body>
</html>
