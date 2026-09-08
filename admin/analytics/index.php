<?php
/**
 * Admin Panel - Real MySQL Analytics Reports
 * Includes Recipes, Categories, and Real-Time Product Inventory & Expiry Metrics
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

// 1. Content Metrics from MySQL
$totalRecipes = (int)$db->query('SELECT COUNT(*) FROM recipes')->fetchColumn();
$totalCategories = (int)$db->query('SELECT COUNT(*) FROM categories')->fetchColumn();
$totalIngredients = (int)$db->query('SELECT COUNT(*) FROM recipe_ingredients')->fetchColumn();
$activeAnnouncements = (int)$db->query("SELECT COUNT(*) FROM announcements WHERE status = 'published' AND CURRENT_DATE() BETWEEN start_date AND end_date")->fetchColumn();

// 2. Product Inventory & Expiry Metrics
$totalActiveProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0")->fetchColumn();
$expiredProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date < CURDATE()")->fetchColumn();
$expiringSoonProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 0 AND expiry_date IS NOT NULL AND expiry_date >= CURDATE() AND expiry_date <= DATE_ADD(CURDATE(), INTERVAL 7 DAY)")->fetchColumn();
$consumedProducts = (int)$db->query("SELECT COUNT(*) FROM products WHERE is_consumed = 1")->fetchColumn();

// 3. Category Distribution for Recipes
$catDistribution = $db->query('
    SELECT c.name, c.color, COUNT(r.id) AS recipe_count
    FROM categories c
    LEFT JOIN recipes r ON r.category_id = c.id
    GROUP BY c.id, c.name, c.color
    ORDER BY recipe_count DESC
')->fetchAll();

// 4. Product Storage Location Breakdown
$storageBreakdown = $db->query("
    SELECT storage_location, COUNT(*) AS count
    FROM products
    WHERE is_consumed = 0
    GROUP BY storage_location
    ORDER BY count DESC
")->fetchAll();

// 5. Product Category Volume
$productCatBreakdown = $db->query("
    SELECT category, COUNT(*) AS count
    FROM products
    WHERE is_consumed = 0
    GROUP BY category
    ORDER BY count DESC
    LIMIT 6
")->fetchAll();

// 6. Difficulty Breakdown
$difficultyBreakdown = $db->query('
    SELECT difficulty, COUNT(*) AS count
    FROM recipes
    GROUP BY difficulty
')->fetchAll();

// 7. Recipes by Ingredient Count
$recipesByIngredients = $db->query('
    SELECT r.title, c.name AS category_name, COUNT(ri.id) AS ingredient_count
    FROM recipes r
    LEFT JOIN categories c ON r.category_id = c.id
    LEFT JOIN recipe_ingredients ri ON ri.recipe_id = r.id
    GROUP BY r.id, r.title, c.name
    ORDER BY ingredient_count DESC
    LIMIT 6
')->fetchAll();

$pageTitle = 'Application Analytics';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="mb-4">
  <h2 class="fw-bold mb-1" style="font-size: 20px;">System & Inventory Analytics</h2>
  <p class="text-muted small mb-0">Live data reports computed directly from MySQL database tables.</p>
</div>

<!-- Product Inventory Health Metrics -->
<h3 class="fw-bold mb-3" style="font-size: 16px;">Product Expiration & Waste Prevention</h3>
<div class="row g-3 mb-4">
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon emerald"><span class="material-symbols-rounded fs-3">inventory_2</span></div>
      <div>
        <div class="stat-label">Active Products</div>
        <div class="stat-value"><?= $totalActiveProducts ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon rose"><span class="material-symbols-rounded fs-3">error</span></div>
      <div>
        <div class="stat-label">Expired Products</div>
        <div class="stat-value text-danger"><?= $expiredProducts ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon amber"><span class="material-symbols-rounded fs-3">warning</span></div>
      <div>
        <div class="stat-label">Expiring Soon (7d)</div>
        <div class="stat-value text-warning"><?= $expiringSoonProducts ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon blue"><span class="material-symbols-rounded fs-3">eco</span></div>
      <div>
        <div class="stat-label">Rescued / Consumed</div>
        <div class="stat-value text-success"><?= $consumedProducts ?></div>
      </div>
    </div>
  </div>
</div>

<!-- Content Overview Stat Cards -->
<h3 class="fw-bold mb-3" style="font-size: 16px;">Catalog & Community Content</h3>
<div class="row g-3 mb-4">
  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon emerald"><span class="material-symbols-rounded fs-3">restaurant</span></div>
      <div>
        <div class="stat-label">Total Recipes</div>
        <div class="stat-value"><?= $totalRecipes ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon blue"><span class="material-symbols-rounded fs-3">category</span></div>
      <div>
        <div class="stat-label">Grocery Categories</div>
        <div class="stat-value"><?= $totalCategories ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon amber"><span class="material-symbols-rounded fs-3">receipt_long</span></div>
      <div>
        <div class="stat-label">Mapped Ingredients</div>
        <div class="stat-value"><?= $totalIngredients ?></div>
      </div>
    </div>
  </div>

  <div class="col-sm-6 col-xl-3">
    <div class="card-box stat-card mb-0">
      <div class="stat-icon rose"><span class="material-symbols-rounded fs-3">campaign</span></div>
      <div>
        <div class="stat-label">Active Announcements</div>
        <div class="stat-value"><?= $activeAnnouncements ?></div>
      </div>
    </div>
  </div>
</div>

<div class="row g-4 mb-4">
  <!-- Storage Location Distribution -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <h3 class="fw-bold mb-1" style="font-size: 16px;">Storage Location Distribution</h3>
      <p class="text-muted small mb-4">Where active products are currently stored in households.</p>

      <?php if (empty($storageBreakdown)): ?>
        <p class="text-muted fst-italic">Analytics will appear after product inventory is added.</p>
      <?php else: ?>
        <div class="d-flex flex-column gap-3">
          <?php foreach ($storageBreakdown as $sb): 
            $pct = $totalActiveProducts > 0 ? round(($sb['count'] / $totalActiveProducts) * 100) : 0;
            $locName = ucfirst(preg_replace('/(?<!\ )[A-Z]/', ' $0', $sb['storage_location']));
          ?>
            <div>
              <div class="d-flex justify-content-between align-items-center mb-1 small fw-bold">
                <span><?= e($locName) ?></span>
                <span class="text-muted"><?= $sb['count'] ?> items (<?= $pct ?>%)</span>
              </div>
              <div class="progress" style="height: 8px; border-radius: 4px; background-color: #F1F5F9;">
                <div class="progress-bar bg-success" role="progressbar" style="width: <?= $pct ?>%;" aria-valuenow="<?= $pct ?>" aria-valuemin="0" aria-valuemax="100"></div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>
  </div>

  <!-- Product Category Volume -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <h3 class="fw-bold mb-1" style="font-size: 16px;">Top Product Categories</h3>
      <p class="text-muted small mb-4">Most common categories tracked in inventory.</p>

      <?php if (empty($productCatBreakdown)): ?>
        <p class="text-muted fst-italic">Analytics will appear after data is collected.</p>
      <?php else: ?>
        <div class="d-flex flex-column gap-3">
          <?php foreach ($productCatBreakdown as $pc): 
            $pct = $totalActiveProducts > 0 ? round(($pc['count'] / $totalActiveProducts) * 100) : 0;
          ?>
            <div>
              <div class="d-flex justify-content-between align-items-center mb-1 small fw-bold">
                <span><?= e($pc['category']) ?></span>
                <span class="text-muted"><?= $pc['count'] ?> items (<?= $pct ?>%)</span>
              </div>
              <div class="progress" style="height: 8px; border-radius: 4px; background-color: #F1F5F9;">
                <div class="progress-bar bg-primary" role="progressbar" style="width: <?= $pct ?>%;" aria-valuenow="<?= $pct ?>" aria-valuemin="0" aria-valuemax="100"></div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>
  </div>
</div>

<div class="row g-4">
  <!-- Category Distribution Report -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <h3 class="fw-bold mb-1" style="font-size: 16px;">Recipe Category Distribution</h3>
      <p class="text-muted small mb-4">Number of published and draft recipes mapped to each category.</p>

      <?php if (empty($catDistribution)): ?>
        <p class="text-muted fst-italic">Analytics will appear after data is collected.</p>
      <?php else: ?>
        <div class="d-flex flex-column gap-3">
          <?php foreach ($catDistribution as $item): 
            $pct = $totalRecipes > 0 ? round(($item['recipe_count'] / $totalRecipes) * 100) : 0;
          ?>
            <div>
              <div class="d-flex justify-content-between align-items-center mb-1 small fw-bold">
                <span class="d-flex align-items-center gap-2">
                  <span class="d-inline-block rounded-circle" style="width: 10px; height: 10px; background-color: <?= e($item['color'] ?: '#10B981') ?>;"></span>
                  <span><?= e($item['name']) ?></span>
                </span>
                <span class="text-muted"><?= $item['recipe_count'] ?> recipes (<?= $pct ?>%)</span>
              </div>
              <div class="progress" style="height: 8px; border-radius: 4px; background-color: #F1F5F9;">
                <div class="progress-bar" role="progressbar" style="width: <?= $pct ?>%; background-color: <?= e($item['color'] ?: '#10B981') ?>;" aria-valuenow="<?= $pct ?>" aria-valuemin="0" aria-valuemax="100"></div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>
  </div>

  <!-- Difficulty Breakdown -->
  <div class="col-lg-6">
    <div class="card-box h-100">
      <h3 class="fw-bold mb-1" style="font-size: 16px;">Cooking Difficulty Breakdown</h3>
      <p class="text-muted small mb-4">Recipe distribution by preparation difficulty.</p>

      <?php if (empty($difficultyBreakdown)): ?>
        <p class="text-muted fst-italic">Analytics will appear after data is collected.</p>
      <?php else: ?>
        <div class="row g-3 mb-4">
          <?php foreach ($difficultyBreakdown as $diff): 
            $color = match($diff['difficulty']) {
              'Easy' => 'success',
              'Medium' => 'warning',
              'Hard' => 'danger',
              default => 'secondary'
            };
          ?>
            <div class="col-4">
              <div class="p-3 text-center rounded-3 border bg-light">
                <div class="fw-bold text-<?= $color ?> mb-1" style="font-size: 24px;"><?= $diff['count'] ?></div>
                <div class="small fw-semibold text-muted"><?= e($diff['difficulty']) ?></div>
              </div>
            </div>
          <?php endforeach; ?>
        </div>

        <h4 class="fw-bold mb-2" style="font-size: 14px;">Top Recipes by Mapped Ingredients</h4>
        <div class="list-group list-group-flush border-top">
          <?php foreach ($recipesByIngredients as $ri): ?>
            <div class="list-group-item px-0 py-2 d-flex justify-content-between align-items-center small">
              <div>
                <span class="fw-bold text-dark"><?= e($ri['title']) ?></span>
                <span class="text-muted ms-2">(<?= e($ri['category_name'] ?? 'General') ?>)</span>
              </div>
              <span class="badge bg-light text-dark border px-2 py-1 rounded-pill fw-bold">
                <?= $ri['ingredient_count'] ?> ingredients
              </span>
            </div>
          <?php endforeach; ?>
        </div>
      <?php endif; ?>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
