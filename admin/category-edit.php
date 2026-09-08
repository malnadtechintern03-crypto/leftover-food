<?php
/**
 * ScanSmart Category Management - Edit Category Form
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin', 'editor');

$db = Database::getConnection();

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    set_flash('error', 'Invalid category ID.');
    header('Location: ' . base_url('categories.php'));
    exit;
}

$stmt = $db->prepare('SELECT * FROM categories WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$category = $stmt->fetch();

if (!$category) {
    set_flash('error', 'Category not found.');
    header('Location: ' . base_url('categories.php'));
    exit;
}

$errors = [];
$name = $category['name'];
$description = $category['description'] ?? '';
$icon = $category['icon'] ?? 'category';
$color = $category['color'] ?? '#10B981';
$status = $category['status'] ?? 'active';
$sortOrder = (int)($category['sort_order'] ?? 0);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security token expired.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $icon = trim($_POST['icon'] ?? 'category');
        $color = trim($_POST['color'] ?? '#10B981');
        $status = in_array($_POST['status'] ?? '', ['active', 'inactive']) ? $_POST['status'] : 'active';
        $sortOrder = (int)($_POST['sort_order'] ?? 0);

        if ($name === '') {
            $errors[] = 'Category name is required.';
        } else {
            $check = $db->prepare('SELECT id FROM categories WHERE name = ? AND id != ? LIMIT 1');
            $check->execute([$name, $id]);
            if ($check->fetch()) {
                $errors[] = "Category '{$name}' is already in use.";
            }
        }

        if (empty($errors)) {
            $oldName = $category['name'];
            $update = $db->prepare('UPDATE categories SET name = ?, description = ?, icon = ?, color = ?, status = ?, sort_order = ? WHERE id = ?');
            $update->execute([$name, $description ?: null, $icon, $color, $status, $sortOrder, $id]);

            // If name changed, update products referencing the old category name string
            if ($oldName !== $name) {
                $updProds = $db->prepare('UPDATE products SET category = ? WHERE category = ? OR category_id = ?');
                $updProds->execute([$name, $oldName, $id]);
            }

            log_admin_activity('Edit Category', "Updated category '{$name}' (ID: {$id})");
            set_flash('success', "Category '{$name}' updated successfully.");
            header('Location: ' . base_url('categories.php'));
            exit;
        }
    }
}

$pageTitle = 'Edit Category — ' . $category['name'];
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-2xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h2 class="h4 fw-bold mb-1">Edit Category: <?= e($category['name']) ?></h2>
      <div class="text-muted small">Category ID: <code>#<?= $category['id'] ?></code></div>
    </div>
    <a href="<?= base_url('categories.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
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
        <label for="name" class="form-label small fw-bold">Category Name <span class="text-danger">*</span></label>
        <input type="text" name="name" id="name" class="form-control" value="<?= e($name) ?>" required>
      </div>

      <div class="mb-3">
        <label for="description" class="form-label small fw-bold">Description</label>
        <textarea name="description" id="description" rows="3" class="form-control"><?= e($description) ?></textarea>
      </div>

      <div class="row g-3 mb-3">
        <div class="col-md-6">
          <label for="icon" class="form-label small fw-bold">Material Symbol Icon</label>
          <input type="text" name="icon" id="icon" class="form-control" value="<?= e($icon) ?>">
        </div>

        <div class="col-md-6">
          <label for="color" class="form-label small fw-bold">Theme Color</label>
          <div class="input-group">
            <input type="color" name="color" id="color" class="form-control form-control-color" value="<?= e($color) ?>" style="width: 50px;">
            <input type="text" class="form-control" value="<?= e($color) ?>" onchange="document.getElementById('color').value = this.value">
          </div>
        </div>

        <div class="col-md-6">
          <label for="status" class="form-label small fw-bold">Status</label>
          <select name="status" id="status" class="form-select">
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>Active</option>
            <option value="inactive" <?= $status === 'inactive' ? 'selected' : '' ?>>Inactive</option>
          </select>
        </div>

        <div class="col-md-6">
          <label for="sort_order" class="form-label small fw-bold">Sort Order</label>
          <input type="number" name="sort_order" id="sort_order" class="form-control" value="<?= $sortOrder ?>">
        </div>
      </div>

      <div class="d-flex justify-content-end gap-2 mt-4 pt-3 border-top">
        <a href="<?= base_url('categories.php') ?>" class="btn btn-light rounded-pill px-4">Cancel</a>
        <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Save Changes</button>
      </div>
    </form>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
