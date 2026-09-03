<?php
/**
 * Announcement Management - Edit Announcement
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid announcement ID.');
    header('Location: ' . base_url('announcements/index.php'));
    exit;
}

$db = Database::getConnection();
$stmt = $db->prepare('SELECT * FROM announcements WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$announcement = $stmt->fetch();

if (!$announcement) {
    set_flash('danger', 'Announcement not found.');
    header('Location: ' . base_url('announcements/index.php'));
    exit;
}

$errorMessage = '';
$title = $announcement['title'];
$message = $announcement['message'];
$imageUrl = $announcement['image_url'] ?? '';
$status = $announcement['status'];
$startDate = $announcement['start_date'];
$endDate = $announcement['end_date'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security token invalid or expired. Please resubmit.';
    } else {
        $title = trim($_POST['title'] ?? '');
        $message = trim($_POST['message'] ?? '');
        $imageUrl = trim($_POST['image_url'] ?? '');
        $status = in_array($_POST['status'] ?? '', ['published', 'draft', 'archived'], true) ? $_POST['status'] : 'published';
        $startDate = trim($_POST['start_date'] ?? '');
        $endDate = trim($_POST['end_date'] ?? '');

        if ($title === '' || $message === '') {
            $errorMessage = 'Title and Message are both required.';
        } elseif ($startDate > $endDate) {
            $errorMessage = 'Start date cannot be after the end date.';
        } else {
            $updateStmt = $db->prepare('
                UPDATE announcements 
                SET title = ?, message = ?, image_url = ?, status = ?, start_date = ?, end_date = ?
                WHERE id = ?
            ');
            $updateStmt->execute([$title, $message, $imageUrl ?: null, $status, $startDate, $endDate, $id]);

            set_flash('success', "Announcement '{$title}' updated successfully.");
            header('Location: ' . base_url('announcements/index.php'));
            exit;
        }
    }
}

$pageTitle = 'Edit Announcement';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="row justify-content-center">
  <div class="col-lg-8 col-xl-7">
    <div class="card-box">
      <div class="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
        <div>
          <h2 class="fw-bold mb-1" style="font-size: 18px;">Edit Announcement</h2>
          <span class="text-muted small">Update notice schedule and content.</span>
        </div>
        <a href="<?= base_url('announcements/index.php') ?>" class="btn btn-secondary-custom btn-sm">
          <span class="material-symbols-rounded fs-6">arrow_back</span>
          <span>Back</span>
        </a>
      </div>

      <?php if (!empty($errorMessage)): ?>
        <div class="alert alert-danger d-flex align-items-center mb-4 py-2 px-3 small rounded-3" role="alert">
          <span class="material-symbols-rounded me-2 fs-5">error</span>
          <div><?= e($errorMessage) ?></div>
        </div>
      <?php endif; ?>

      <form method="POST" action="">
        <?= csrf_field() ?>

        <div class="mb-3">
          <label for="title" class="form-label">Announcement Title <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="title" name="title" value="<?= e($title) ?>" required>
        </div>

        <div class="mb-3">
          <label for="message" class="form-label">Message Content <span class="text-danger">*</span></label>
          <textarea class="form-control" id="message" name="message" rows="4" required><?= e($message) ?></textarea>
        </div>

        <div class="mb-3">
          <label for="image_url" class="form-label">Banner Image URL (Optional)</label>
          <input type="url" class="form-control" id="image_url" name="image_url" value="<?= e($imageUrl) ?>">
        </div>

        <div class="row g-3 mb-3">
          <div class="col-sm-6">
            <label for="start_date" class="form-label">Start Date</label>
            <input type="date" class="form-control" id="start_date" name="start_date" value="<?= e($startDate) ?>" required>
          </div>

          <div class="col-sm-6">
            <label for="end_date" class="form-label">End Date</label>
            <input type="date" class="form-control" id="end_date" name="end_date" value="<?= e($endDate) ?>" required>
          </div>
        </div>

        <div class="mb-4">
          <label for="status" class="form-label">Publication Status</label>
          <select class="form-select" id="status" name="status">
            <option value="published" <?= $status === 'published' ? 'selected' : '' ?>>Published</option>
            <option value="draft" <?= $status === 'draft' ? 'selected' : '' ?>>Draft</option>
            <option value="archived" <?= $status === 'archived' ? 'selected' : '' ?>>Archived</option>
          </select>
        </div>

        <div class="d-flex align-items-center justify-content-end gap-2 pt-3 border-top">
          <a href="<?= base_url('announcements/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
          <button type="submit" class="btn btn-primary-custom">
            <span class="material-symbols-rounded fs-6">save</span>
            <span>Update Announcement</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
