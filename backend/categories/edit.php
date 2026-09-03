<?php
/**
 * Category Management - Edit Category
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid category ID.');
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

$db = Database::getConnection();
$stmt = $db->prepare('SELECT * FROM categories WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$category = $stmt->fetch();

if (!$category) {
    set_flash('danger', 'Category not found.');
    header('Location: ' . base_url('categories/index.php'));
    exit;
}

$errorMessage = '';
$name = $category['name'];
$description = $category['description'] ?? '';
$status = $category['status'];
$color = $category['color'] ?? '#10B981';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security token invalid or expired. Please resubmit.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $status = in_array($_POST['status'] ?? '', ['active', 'inactive'], true) ? $_POST['status'] : 'active';
        $color = trim($_POST['color'] ?? '#10B981');

        if ($name === '') {
            $errorMessage = 'Category name is required.';
        } else {
            // Check unique name for other categories
            $checkStmt = $db->prepare('SELECT id FROM categories WHERE name = ? AND id != ? LIMIT 1');
            $checkStmt->execute([$name, $id]);
            if ($checkStmt->fetch()) {
                $errorMessage = 'Another category with this name already exists.';
            } else {
                $updateStmt = $db->prepare('UPDATE categories SET name = ?, description = ?, color = ?, status = ? WHERE id = ?');
                $updateStmt->execute([$name, $description, $color, $status, $id]);

                set_flash('success', "Category '{$name}' updated successfully.");
                header('Location: ' . base_url('categories/index.php'));
                exit;
            }
        }
    }
}

$pageTitle = 'Edit Category — ' . $category['name'];
require_once __DIR__ . '/../includes/header.php';
?>

<div class="row justify-content-center">
  <div class="col-lg-8 col-xl-7">
    <div class="card-box">
      <div class="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
        <div>
          <h2 class="fw-bold mb-1" style="font-size: 18px;">Edit Category</h2>
          <span class="text-muted small">Update grocery category information and visibility status.</span>
        </div>
        <a href="<?= base_url('categories/index.php') ?>" class="btn btn-secondary-custom btn-sm">
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
          <label for="name" class="form-label">Category Name <span class="text-danger">*</span></label>
          <input type="text" class="form-control" id="name" name="name" value="<?= e($name) ?>" required>
        </div>

        <div class="mb-3">
          <label for="description" class="form-label">Description</label>
          <textarea class="form-control" id="description" name="description" rows="3"><?= e($description) ?></textarea>
        </div>

        <div class="row g-3 mb-4">
          <div class="col-sm-6">
            <label for="color" class="form-label">Theme Color</label>
            <div class="d-flex align-items-center gap-2">
              <input type="color" class="form-control form-control-color p-1" id="color" name="color" value="<?= e($color) ?>">
              <span class="text-muted small">Category badge color</span>
            </div>
          </div>

          <div class="col-sm-6">
            <label for="status" class="form-label">Status</label>
            <select class="form-select" id="status" name="status">
              <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active (Visible in App)</option>
              <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Inactive (Hidden)</option>
            </select>
          </div>
        </div>

        <div class="d-flex align-items-center justify-content-end gap-2 pt-3 border-top">
          <a href="<?= base_url('categories/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
          <button type="submit" class="btn btn-primary-custom">
            <span class="material-symbols-rounded fs-6">save</span>
            <span>Update Category</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
