<?php
/**
 * Category Management - List Categories
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

// Search query support
$search = trim($_GET['q'] ?? '');

if ($search !== '') {
    $stmt = $db->prepare('
        SELECT c.*, 
               (SELECT COUNT(*) FROM recipes WHERE category_id = c.id) AS recipe_count
        FROM categories c
        WHERE c.name LIKE ? OR c.description LIKE ?
        ORDER BY c.name ASC
    ');
    $stmt->execute(["%$search%", "%$search%"]);
} else {
    $stmt = $db->query('
        SELECT c.*, 
               (SELECT COUNT(*) FROM recipes WHERE category_id = c.id) AS recipe_count
        FROM categories c
        ORDER BY c.id ASC
    ');
}

$categories = $stmt->fetchAll();

$pageTitle = 'Category Management';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Grocery Categories</h2>
    <p class="text-muted small mb-0">Configure standard grocery classifications used by the mobile app and smart recipes.</p>
  </div>
  <a href="<?= base_url('categories/create.php') ?>" class="btn btn-primary-custom align-self-start align-self-md-center">
    <span class="material-symbols-rounded fs-5">add_circle</span>
    <span>Add Category</span>
  </a>
</div>

<div class="card-box">
  <!-- Search & Filter Controls -->
  <div class="row g-3 align-items-center mb-3">
    <div class="col-md-6 col-lg-4">
      <form method="GET" action="" class="position-relative">
        <input type="text" name="q" value="<?= e($search) ?>" class="form-control ps-5" placeholder="Search categories..." id="tableSearchInput">
        <span class="material-symbols-rounded position-absolute top-50 start-0 translate-middle-y ms-3 text-muted" style="font-size: 20px;">search</span>
      </form>
    </div>
    <div class="col-md-6 col-lg-8 text-md-end text-muted small">
      Showing <strong><?= count($categories) ?></strong> categories
    </div>
  </div>

  <?php if (empty($categories)): ?>
    <div class="empty-state py-5">
      <div class="empty-icon"><span class="material-symbols-rounded">category</span></div>
      <div class="empty-title">No data available.</div>
      <p class="empty-text"><?= $search !== '' ? 'No categories matched your search term.' : 'No grocery categories have been added yet.' ?></p>
      <?php if ($search !== ''): ?>
        <a href="<?= base_url('categories/index.php') ?>" class="btn btn-secondary-custom">Clear Search</a>
      <?php else: ?>
        <a href="<?= base_url('categories/create.php') ?>" class="btn btn-primary-custom">Add First Category</a>
      <?php endif; ?>
    </div>
  <?php else: ?>
    <div class="table-responsive">
      <table class="custom-table">
        <thead>
          <tr>
            <th style="width: 60px;">ID</th>
            <th>Category Name</th>
            <th>Description</th>
            <th style="width: 140px;">Recipes Linked</th>
            <th style="width: 120px;">Status</th>
            <th style="width: 140px;" class="text-end">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($categories as $cat): ?>
            <tr>
              <td class="text-muted fw-bold">#<?= $cat['id'] ?></td>
              <td>
                <div class="fw-bold text-dark d-flex align-items-center gap-2">
                  <span class="d-inline-block rounded-circle" style="width: 10px; height: 10px; background-color: <?= e($cat['color'] ?: '#10B981') ?>;"></span>
                  <span><?= e($cat['name']) ?></span>
                </div>
                <div class="text-muted" style="font-size: 11px;">Created <?= format_date($cat['created_at']) ?></div>
              </td>
              <td>
                <div class="text-muted small" style="max-width: 320px;">
                  <?= e($cat['description'] ?: '—') ?>
                </div>
              </td>
              <td>
                <span class="badge bg-light text-dark border px-2.5 py-1 rounded-pill fw-semibold">
                  <?= $cat['recipe_count'] ?> recipes
                </span>
              </td>
              <td>
                <span class="badge-status <?= e($cat['status']) ?>">
                  <?= ucfirst(e($cat['status'])) ?>
                </span>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <a href="<?= base_url('categories/edit.php?id=' . $cat['id']) ?>" class="btn-action-icon" title="Edit Category">
                    <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                  </a>
                  <form method="POST" action="<?= base_url('categories/delete.php') ?>" onsubmit="return confirmDelete('Are you sure you want to delete category \'<?= e(addslashes($cat['name'])) ?>\'?');" class="d-inline">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= $cat['id'] ?>">
                    <button type="submit" class="btn-action-icon danger" title="Delete Category">
                      <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                    </button>
                  </form>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
