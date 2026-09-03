<?php
/**
 * Recipe Management - List Recipes
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

// Filters
$search = trim($_GET['q'] ?? '');
$categoryId = (int)($_GET['category_id'] ?? 0);

// Fetch categories for filter dropdown
$categories = $db->query('SELECT id, name FROM categories ORDER BY name ASC')->fetchAll();

// Build query
$sql = '
    SELECT r.*, c.name AS category_name, c.color AS category_color,
           (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = r.id) AS ingredient_count
    FROM recipes r
    LEFT JOIN categories c ON r.category_id = c.id
    WHERE 1=1
';
$params = [];

if ($search !== '') {
    $sql .= ' AND (r.title LIKE ? OR r.description LIKE ?)';
    $params[] = "%$search%";
    $params[] = "%$search%";
}

if ($categoryId > 0) {
    $sql .= ' AND r.category_id = ?';
    $params[] = $categoryId;
}

$sql .= ' ORDER BY r.id DESC';

$stmt = $db->prepare($sql);
$stmt->execute($params);
$recipes = $stmt->fetchAll();

$pageTitle = 'Recipe Management';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Smart Recipes</h2>
    <p class="text-muted small mb-0">Manage recipes and map grocery ingredients for the mobile app's smart recipe engine.</p>
  </div>
  <a href="<?= base_url('recipes/create.php') ?>" class="btn btn-primary-custom align-self-start align-self-md-center">
    <span class="material-symbols-rounded fs-5">add_circle</span>
    <span>Add Recipe</span>
  </a>
</div>

<div class="card-box">
  <!-- Search & Category Filters -->
  <form method="GET" action="" class="row g-3 align-items-center mb-4">
    <div class="col-md-5 col-lg-4">
      <div class="position-relative">
        <input type="text" name="q" value="<?= e($search) ?>" class="form-control ps-5" placeholder="Search recipe titles..." id="tableSearchInput">
        <span class="material-symbols-rounded position-absolute top-50 start-0 translate-middle-y ms-3 text-muted" style="font-size: 20px;">search</span>
      </div>
    </div>

    <div class="col-md-4 col-lg-3">
      <select name="category_id" class="form-select" onchange="this.form.submit()">
        <option value="0">All Grocery Categories</option>
        <?php foreach ($categories as $cat): ?>
          <option value="<?= $cat['id'] ?>" <?= $categoryId === (int)$cat['id'] ? 'selected' : '' ?>>
            <?= e($cat['name']) ?>
          </option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-md-3 col-lg-5 text-md-end text-muted small">
      Showing <strong><?= count($recipes) ?></strong> recipes
      <?php if ($search !== '' || $categoryId > 0): ?>
        <a href="<?= base_url('recipes/index.php') ?>" class="ms-2 text-danger text-decoration-none fw-semibold">Clear Filters</a>
      <?php endif; ?>
    </div>
  </form>

  <?php if (empty($recipes)): ?>
    <div class="empty-state py-5">
      <div class="empty-icon"><span class="material-symbols-rounded">restaurant_menu</span></div>
      <div class="empty-title">No data available.</div>
      <p class="empty-text">No recipes found matching your filter criteria.</p>
      <a href="<?= base_url('recipes/create.php') ?>" class="btn btn-primary-custom">Add First Recipe</a>
    </div>
  <?php else: ?>
    <div class="table-responsive">
      <table class="custom-table">
        <thead>
          <tr>
            <th style="width: 70px;">Image</th>
            <th>Recipe Title</th>
            <th>Category</th>
            <th>Prep Time</th>
            <th>Difficulty</th>
            <th>Ingredients</th>
            <th>Status</th>
            <th class="text-end" style="width: 150px;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($recipes as $recipe): ?>
            <tr>
              <td>
                <?php if (!empty($recipe['image_url'])): ?>
                  <img src="<?= e($recipe['image_url']) ?>" alt="<?= e($recipe['title']) ?>" class="rounded-3" style="width: 52px; height: 52px; object-fit: cover;">
                <?php else: ?>
                  <div class="rounded-3 bg-light d-flex align-items-center justify-content-center text-muted border" style="width: 52px; height: 52px;">
                    <span class="material-symbols-rounded fs-4">restaurant</span>
                  </div>
                <?php endif; ?>
              </td>
              <td>
                <div class="fw-bold text-dark mb-0.5"><?= e($recipe['title']) ?></div>
                <div class="text-muted" style="font-size: 12px; max-width: 280px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                  <?= e($recipe['description'] ?: 'No description provided') ?>
                </div>
              </td>
              <td>
                <span class="badge bg-light text-dark border px-2.5 py-1 rounded-3 small">
                  <?= e($recipe['category_name'] ?? 'Unassigned') ?>
                </span>
              </td>
              <td class="fw-semibold small">
                <?= e($recipe['prep_time']) ?>
              </td>
              <td>
                <span class="badge <?= $recipe['difficulty'] === 'Easy' ? 'bg-success-subtle text-success' : ($recipe['difficulty'] === 'Medium' ? 'bg-warning-subtle text-warning' : 'bg-danger-subtle text-danger') ?> px-2 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                  <?= e($recipe['difficulty']) ?>
                </span>
              </td>
              <td>
                <a href="<?= base_url('recipes/ingredients.php?recipe_id=' . $recipe['id']) ?>" class="badge bg-emerald-subtle text-success text-decoration-none px-2.5 py-1.5 rounded-pill fw-bold d-inline-flex align-items-center gap-1" style="background: rgba(16, 185, 129, 0.12);" title="Click to manage ingredients">
                  <span class="material-symbols-rounded" style="font-size: 14px;">grocery</span>
                  <span><?= $recipe['ingredient_count'] ?> ingredients</span>
                </a>
              </td>
              <td>
                <span class="badge-status <?= e($recipe['status']) ?>">
                  <?= ucfirst(e($recipe['status'])) ?>
                </span>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <a href="<?= base_url('recipes/ingredients.php?recipe_id=' . $recipe['id']) ?>" class="btn-action-icon" title="Map Ingredients">
                    <span class="material-symbols-rounded" style="font-size: 16px;">grocery</span>
                  </a>
                  <a href="<?= base_url('recipes/edit.php?id=' . $recipe['id']) ?>" class="btn-action-icon" title="Edit Recipe">
                    <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                  </a>
                  <form method="POST" action="<?= base_url('recipes/delete.php') ?>" onsubmit="return confirmDelete('Are you sure you want to delete \'<?= e(addslashes($recipe['title'])) ?>\'?');" class="d-inline">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= $recipe['id'] ?>">
                    <button type="submit" class="btn-action-icon danger" title="Delete Recipe">
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
