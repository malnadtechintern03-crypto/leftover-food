<?php
/**
 * Admin Panel - Overview Dashboard
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// 1. Fetch Real Counts from MySQL
$categoryCount = (int)$db->query('SELECT COUNT(*) FROM categories')->fetchColumn();
$recipeCount = (int)$db->query('SELECT COUNT(*) FROM recipes')->fetchColumn();
$ingredientCount = (int)$db->query('SELECT COUNT(*) FROM recipe_ingredients')->fetchColumn();
$announcementCount = (int)$db->query('SELECT COUNT(*) FROM announcements')->fetchColumn();

// 2. Fetch Recent Recipes
$recipesStmt = $db->query('
    SELECT r.id, r.title, r.prep_time, r.difficulty, r.calories, r.status, r.created_at, c.name AS category_name,
           (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = r.id) AS ingredient_count
    FROM recipes r
    LEFT JOIN categories c ON r.category_id = c.id
    ORDER BY r.id DESC
    LIMIT 5
');
$recentRecipes = $recipesStmt->fetchAll();

// 3. Fetch Recent Categories
$categoriesStmt = $db->query('
    SELECT c.id, c.name, c.status, c.created_at,
           (SELECT COUNT(*) FROM recipes WHERE category_id = c.id) AS recipe_count
    FROM categories c
    ORDER BY c.id DESC
    LIMIT 5
');
$recentCategories = $categoriesStmt->fetchAll();

$pageTitle = 'Admin Dashboard';
require_once __DIR__ . '/includes/header.php';
?>

<!-- Quick Actions Header Banner -->
<div class="card-box p-4 mb-4 border-0 text-white" style="background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);">
  <div class="row align-items-center">
    <div class="col-md-7 mb-3 mb-md-0">
      <span class="badge bg-emerald text-white px-3 py-1.5 rounded-pill mb-2 fw-bold" style="background: #10B981; font-size: 11.5px;">
        Localhost Console
      </span>
      <h2 class="fw-bold mb-1" style="font-size: 22px;">Welcome back, <?= e($currentAdmin['name']) ?>! 👋</h2>
      <p class="text-white-50 mb-0 small">
        Manage common application data, grocery categories, smart recipes, and announcements for the Home Pantry app.
      </p>
    </div>
    <div class="col-md-5 text-md-end d-flex flex-wrap gap-2 justify-content-md-end">
      <a href="<?= base_url('categories/create.php') ?>" class="btn btn-sm btn-light fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6 text-success">add_circle</span>
        <span>Add Category</span>
      </a>
      <a href="<?= base_url('recipes/create.php') ?>" class="btn btn-sm btn-success fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1" style="background: #10B981; border-color: #10B981;">
        <span class="material-symbols-rounded fs-6">restaurant</span>
        <span>Add Recipe</span>
      </a>
      <a href="<?= base_url('announcements/create.php') ?>" class="btn btn-sm btn-outline-light fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">campaign</span>
        <span>Add Announcement</span>
      </a>
    </div>
  </div>
</div>

<!-- Key Performance Metric Cards -->
<div class="row g-3 mb-4">
  <!-- Total Categories -->
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon emerald">
        <span class="material-symbols-rounded fs-3">category</span>
      </div>
      <div>
        <div class="stat-label">Grocery Categories</div>
        <div class="stat-value"><?= $categoryCount ?></div>
      </div>
    </div>
  </div>

  <!-- Total Recipes -->
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon blue">
        <span class="material-symbols-rounded fs-3">menu_book</span>
      </div>
      <div>
        <div class="stat-label">Smart Recipes</div>
        <div class="stat-value"><?= $recipeCount ?></div>
      </div>
    </div>
  </div>

  <!-- Total Ingredients -->
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon amber">
        <span class="material-symbols-rounded fs-3">grocery</span>
      </div>
      <div>
        <div class="stat-label">Mapped Ingredients</div>
        <div class="stat-value"><?= $ingredientCount ?></div>
      </div>
    </div>
  </div>

  <!-- Total Announcements -->
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon rose">
        <span class="material-symbols-rounded fs-3">campaign</span>
      </div>
      <div>
        <div class="stat-label">Announcements</div>
        <div class="stat-value"><?= $announcementCount ?></div>
      </div>
    </div>
  </div>
</div>

<div class="row g-4">
  <!-- Recent Smart Recipes Table -->
  <div class="col-lg-8">
    <div class="card-box mb-0">
      <div class="d-flex align-items-center justify-content-between mb-3">
        <div>
          <h3 class="fw-bold mb-0" style="font-size: 16px;">Recent Smart Recipes</h3>
          <span class="text-muted small">Latest recipe entries configured for inventory matching</span>
        </div>
        <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-sm btn-outline-secondary rounded-pill px-3">
          View All
        </a>
      </div>

      <?php if (empty($recentRecipes)): ?>
        <div class="empty-state py-4">
          <div class="empty-icon"><span class="material-symbols-rounded">restaurant_menu</span></div>
          <div class="empty-title">No data available.</div>
          <p class="empty-text">Add recipes to enable smart recipe matching in the mobile app.</p>
          <a href="<?= base_url('recipes/create.php') ?>" class="btn btn-primary-custom">Add First Recipe</a>
        </div>
      <?php else: ?>
        <div class="table-responsive">
          <table class="custom-table">
            <thead>
              <tr>
                <th>Recipe</th>
                <th>Category</th>
                <th>Time & Cal</th>
                <th>Ingredients</th>
                <th>Status</th>
                <th class="text-end">Action</th>
              </tr>
            </thead>
            <tbody>
              <?php foreach ($recentRecipes as $recipe): ?>
                <tr>
                  <td>
                    <div class="fw-bold text-dark"><?= e($recipe['title']) ?></div>
                    <div class="text-muted" style="font-size: 11.5px;">Added <?= format_date($recipe['created_at']) ?></div>
                  </td>
                  <td>
                    <span class="badge bg-light text-dark border px-2 py-1 rounded-3">
                      <?= e($recipe['category_name'] ?? 'Unassigned') ?>
                    </span>
                  </td>
                  <td>
                    <div class="small fw-semibold"><?= e($recipe['prep_time']) ?></div>
                    <div class="text-muted" style="font-size: 11px;"><?= $recipe['calories'] ?> kcal</div>
                  </td>
                  <td>
                    <span class="badge bg-emerald-subtle text-success px-2 py-1 rounded-pill fw-bold" style="background: rgba(16, 185, 129, 0.12);">
                      <?= $recipe['ingredient_count'] ?> mapped
                    </span>
                  </td>
                  <td>
                    <span class="badge-status <?= e($recipe['status']) ?>">
                      <?= ucfirst(e($recipe['status'])) ?>
                    </span>
                  </td>
                  <td class="text-end">
                    <a href="<?= base_url('recipes/edit.php?id=' . $recipe['id']) ?>" class="btn-action-icon" title="Edit">
                      <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                    </a>
                    <a href="<?= base_url('recipes/ingredients.php?recipe_id=' . $recipe['id']) ?>" class="btn-action-icon" title="Manage Ingredients">
                      <span class="material-symbols-rounded" style="font-size: 16px;">grocery</span>
                    </a>
                  </td>
                </tr>
              <?php endforeach; ?>
            </tbody>
          </table>
        </div>
      <?php endif; ?>
    </div>
  </div>

  <!-- Recent Categories & Activity Sidebar -->
  <div class="col-lg-4">
    <!-- Categories Overview -->
    <div class="card-box mb-4">
      <div class="d-flex align-items-center justify-content-between mb-3">
        <h3 class="fw-bold mb-0" style="font-size: 16px;">Active Categories</h3>
        <a href="<?= base_url('categories/index.php') ?>" class="btn btn-sm btn-outline-secondary rounded-pill px-3">
          Manage
        </a>
      </div>

      <?php if (empty($recentCategories)): ?>
        <div class="empty-state py-4">
          <div class="empty-title">No data available.</div>
        </div>
      <?php else: ?>
        <div class="list-group list-group-flush">
          <?php foreach ($recentCategories as $category): ?>
            <div class="list-group-item px-0 py-2.5 d-flex align-items-center justify-content-between border-bottom">
              <div>
                <div class="fw-bold small text-dark"><?= e($category['name']) ?></div>
                <div class="text-muted" style="font-size: 11.5px;"><?= $category['recipe_count'] ?> recipes linked</div>
              </div>
              <span class="badge-status <?= e($category['status']) ?>">
                <?= ucfirst(e($category['status'])) ?>
              </span>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>

    <!-- System Status Card -->
    <div class="card-box">
      <h3 class="fw-bold mb-3" style="font-size: 16px;">Environment & REST API</h3>
      <div class="p-3 bg-light rounded-3 border mb-3">
        <div class="d-flex align-items-center justify-content-between mb-2">
          <span class="small text-muted">Web Server</span>
          <span class="badge bg-success">Apache (XAMPP)</span>
        </div>
        <div class="d-flex align-items-center justify-content-between mb-2">
          <span class="small text-muted">PHP Engine</span>
          <span class="small fw-bold">PHP <?= PHP_VERSION ?></span>
        </div>
        <div class="d-flex align-items-center justify-content-between mb-2">
          <span class="small text-muted">Database</span>
          <span class="small fw-bold">MySQL (grocery_admin_db)</span>
        </div>
        <div class="d-flex align-items-center justify-content-between">
          <span class="small text-muted">Mobile Client</span>
          <span class="small fw-bold">Offline SQLite + REST Sync</span>
        </div>
      </div>

      <div class="d-grid gap-2">
        <a href="<?= base_url('api/categories.php') ?>" target="_blank" class="btn btn-sm btn-outline-primary d-flex align-items-center justify-content-center gap-1 rounded-3">
          <span class="material-symbols-rounded fs-6">open_in_new</span>
          <span>Test /api/categories.php</span>
        </a>
      </div>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
