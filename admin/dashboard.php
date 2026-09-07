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

// 2. Product Expiration Metrics
$totalProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0")->fetchColumn();
$expiredProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date < CURDATE()")->fetchColumn();
$expiringToday = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date = CURDATE()")->fetchColumn();
$expiringWithin7 = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date > CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();
$expiringWithin30 = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date > DATE_ADD(CURDATE(), INTERVAL 7 DAY) AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY)")->fetchColumn();
$noExpiryProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NULL")->fetchColumn();

// 3. Fetch Recent Expiring Products
$expiringStmt = $db->query("
    SELECT p.*, DATEDIFF(p.expiry_date, CURDATE()) AS days_remaining
    FROM products p
    WHERE p.is_consumed = 0 AND p.expiry_date IS NOT NULL
    ORDER BY p.expiry_date ASC
    LIMIT 5
");
$recentExpiring = $expiringStmt->fetchAll();

// 4. Fetch Recent Recipes
$recipesStmt = $db->query('
    SELECT r.id, r.title, r.prep_time, r.difficulty, r.calories, r.status, r.created_at, c.name AS category_name,
           (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = r.id) AS ingredient_count
    FROM recipes r
    LEFT JOIN categories c ON r.category_id = c.id
    ORDER BY r.id DESC
    LIMIT 5
');
$recentRecipes = $recipesStmt->fetchAll();

// 5. Fetch Recent Categories
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
        Universal Inventory Console
      </span>
      <h2 class="fw-bold mb-1" style="font-size: 22px;">Welcome back, <?= e($currentAdmin['name']) ?>! 👋</h2>
      <p class="text-white-50 mb-0 small">
        Universal product expiration monitoring, automated reminders, smart recipes, and category administration.
      </p>
    </div>
    <div class="col-md-5 text-md-end d-flex flex-wrap gap-2 justify-content-md-end">
      <a href="<?= base_url('products/index.php') ?>" class="btn btn-sm btn-light fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6 text-success">inventory_2</span>
        <span>Products</span>
      </a>
      <a href="<?= base_url('products/index.php?status=expiring_soon') ?>" class="btn btn-sm btn-warning fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">notifications_active</span>
        <span>Alerts</span>
      </a>
      <a href="<?= base_url('products/export.php') ?>" class="btn btn-sm btn-outline-light fw-bold rounded-3 px-3 py-2 d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">download</span>
        <span>Export CSV</span>
      </a>
    </div>
  </div>
</div>

<!-- 5 REQUIRED PRODUCT EXPIRATION METRIC CARDS -->
<div class="d-flex align-items-center justify-content-between mb-3">
  <div>
    <h3 class="fw-bold mb-0" style="font-size: 16px;">Product Expiration Health</h3>
    <span class="text-muted small">Real-time status of product expiration timelines & automated reminders</span>
  </div>
  <a href="<?= base_url('products/index.php') ?>" class="btn btn-sm btn-outline-secondary rounded-pill px-3">
    Manage Inventory
  </a>
</div>

<div class="row g-3 mb-4">
  <!-- 1. Total Products -->
  <div class="col-sm-6 col-lg">
    <a href="<?= base_url('products/index.php') ?>" class="text-decoration-none">
      <div class="card-box stat-card mb-0 h-100">
        <div class="stat-icon emerald">
          <span class="material-symbols-rounded fs-3">inventory_2</span>
        </div>
        <div>
          <div class="stat-label">Total Products</div>
          <div class="stat-value text-dark"><?= $totalProducts ?></div>
          <div class="text-muted small" style="font-size: 11px;"><?= $noExpiryProducts ?> non-expiring</div>
        </div>
      </div>
    </a>
  </div>

  <!-- 2. Expired Products -->
  <div class="col-sm-6 col-lg">
    <a href="<?= base_url('products/index.php?status=expired') ?>" class="text-decoration-none">
      <div class="card-box stat-card mb-0 h-100">
        <div class="stat-icon rose">
          <span class="material-symbols-rounded fs-3">error</span>
        </div>
        <div>
          <div class="stat-label">Expired Products</div>
          <div class="stat-value text-danger"><?= $expiredProducts ?></div>
          <div class="text-danger small" style="font-size: 11px;">Action needed</div>
        </div>
      </div>
    </a>
  </div>

  <!-- 3. Expiring Today -->
  <div class="col-sm-6 col-lg">
    <a href="<?= base_url('products/index.php?status=expiring_today') ?>" class="text-decoration-none">
      <div class="card-box stat-card mb-0 h-100">
        <div class="stat-icon amber">
          <span class="material-symbols-rounded fs-3">today</span>
        </div>
        <div>
          <div class="stat-label">Expiring Today</div>
          <div class="stat-value text-warning"><?= $expiringToday ?></div>
          <div class="text-warning small" style="font-size: 11px;">Consume today</div>
        </div>
      </div>
    </a>
  </div>

  <!-- 4. Expiring Within 7 Days -->
  <div class="col-sm-6 col-lg">
    <a href="<?= base_url('products/index.php?status=expiring_soon') ?>" class="text-decoration-none">
      <div class="card-box stat-card mb-0 h-100">
        <div class="stat-icon amber">
          <span class="material-symbols-rounded fs-3">warning</span>
        </div>
        <div>
          <div class="stat-label">Within 7 Days</div>
          <div class="stat-value text-warning"><?= $expiringWithin7 ?></div>
          <div class="text-muted small" style="font-size: 11px;">Urgent horizon</div>
        </div>
      </div>
    </a>
  </div>

  <!-- 5. Expiring Within 30 Days -->
  <div class="col-sm-6 col-lg">
    <a href="<?= base_url('products/index.php?status=within_30_days') ?>" class="text-decoration-none">
      <div class="card-box stat-card mb-0 h-100">
        <div class="stat-icon blue">
          <span class="material-symbols-rounded fs-3">schedule</span>
        </div>
        <div>
          <div class="stat-label">Within 30 Days</div>
          <div class="stat-value text-primary"><?= $expiringWithin30 ?></div>
          <div class="text-muted small" style="font-size: 11px;">Monthly horizon</div>
        </div>
      </div>
    </a>
  </div>
</div>

<!-- Recent Expiring Products Section -->
<?php if (!empty($recentExpiring)): ?>
  <div class="card-box mb-4">
    <div class="d-flex align-items-center justify-content-between mb-3">
      <div>
        <h3 class="fw-bold mb-0" style="font-size: 16px;">Top Expiration Alerts</h3>
        <span class="text-muted small">Earliest expiring items in the inventory</span>
      </div>
      <a href="<?= base_url('products/index.php?status=expiring_soon') ?>" class="btn btn-sm btn-outline-warning rounded-pill px-3">
        View All Alerts
      </a>
    </div>

    <div class="table-responsive">
      <table class="custom-table">
        <thead>
          <tr>
            <th>Product</th>
            <th>Category</th>
            <th>Expiration Date</th>
            <th>Countdown</th>
            <th>Status</th>
            <th class="text-end">Action</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($recentExpiring as $item): ?>
            <?php
              $days = (int)$item['days_remaining'];
              $badgeClass = $days < 0 ? 'bg-danger' : ($days <= 2 ? 'bg-warning text-dark' : 'bg-success');
              $statusTxt = $days < 0 ? 'Expired' : ($days <= 2 ? 'Expiring Soon' : 'Safe');
            ?>
            <tr>
              <td>
                <div class="fw-bold text-dark"><?= e($item['name']) ?></div>
                <?php if (!empty($item['brand'])): ?>
                  <span class="badge bg-light text-muted border px-1.5 py-0.5" style="font-size: 10px;"><?= e($item['brand']) ?></span>
                <?php endif; ?>
              </td>
              <td><span class="small fw-semibold"><?= e($item['category']) ?></span></td>
              <td><div class="small fw-bold"><?= format_date($item['expiry_date']) ?></div></td>
              <td>
                <span class="small text-muted">
                  <?= $days < 0 ? abs($days) . ' days ago' : ($days == 0 ? 'Today' : 'In ' . $days . ' days') ?>
                </span>
              </td>
              <td><span class="badge <?= $badgeClass ?> px-2 py-1 rounded-pill fw-bold" style="font-size: 11px;"><?= $statusTxt ?></span></td>
              <td class="text-end">
                <a href="<?= base_url('products/edit.php?id=' . $item['id']) ?>" class="btn-action-icon text-primary" title="Edit">
                  <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                </a>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  </div>
<?php endif; ?>

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
