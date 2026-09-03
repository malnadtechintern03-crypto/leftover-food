<?php
/**
 * Recipe Ingredient Management - Map Grocery Items to Recipes
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

$recipeId = (int)($_GET['recipe_id'] ?? 0);

// Fetch all recipes for selector dropdown
$allRecipes = $db->query('SELECT id, title FROM recipes ORDER BY title ASC')->fetchAll();

if ($recipeId <= 0 && !empty($allRecipes)) {
    $recipeId = (int)$allRecipes[0]['id'];
}

// Fetch selected recipe
$recipeStmt = $db->prepare('SELECT * FROM recipes WHERE id = ? LIMIT 1');
$recipeStmt->execute([$recipeId]);
$recipe = $recipeStmt->fetch();

// Handle adding new ingredient
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        set_flash('danger', 'Security validation failed.');
    } else {
        $action = $_POST['action'] ?? '';

        if ($action === 'add') {
            $name = trim($_POST['ingredient_name'] ?? '');
            $quantity = trim($_POST['quantity'] ?? '');
            $unit = trim($_POST['unit'] ?? '');
            $isRequired = (int)($_POST['is_required'] ?? 1);

            if ($name === '') {
                set_flash('danger', 'Ingredient name is required.');
            } else {
                $insertStmt = $db->prepare('
                    INSERT INTO recipe_ingredients (recipe_id, ingredient_name, quantity, unit, is_required)
                    VALUES (?, ?, ?, ?, ?)
                ');
                $insertStmt->execute([$recipeId, $name, $quantity ?: null, $unit ?: null, $isRequired]);
                set_flash('success', "Added '{$name}' to ingredients.");
            }
        } elseif ($action === 'delete') {
            $ingredientId = (int)($_POST['ingredient_id'] ?? 0);
            if ($ingredientId > 0) {
                $delStmt = $db->prepare('DELETE FROM recipe_ingredients WHERE id = ? AND recipe_id = ?');
                $delStmt->execute([$ingredientId, $recipeId]);
                set_flash('success', 'Ingredient removed.');
            }
        }
    }
    header('Location: ' . base_url('recipes/ingredients.php?recipe_id=' . $recipeId));
    exit;
}

// Fetch ingredients mapped to this recipe
$ingredients = [];
if ($recipe) {
    $ingStmt = $db->prepare('SELECT * FROM recipe_ingredients WHERE recipe_id = ? ORDER BY is_required DESC, id ASC');
    $ingStmt->execute([$recipeId]);
    $ingredients = $ingStmt->fetchAll();
}

$pageTitle = 'Recipe Ingredients Mapping';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Recipe Ingredients</h2>
    <p class="text-muted small mb-0">Map grocery items to recipes to power mobile match percentages and Use-It-First suggestions.</p>
  </div>
  <div class="d-flex gap-2">
    <?php if ($recipe): ?>
      <a href="<?= base_url('recipes/edit.php?id=' . $recipeId) ?>" class="btn btn-secondary-custom btn-sm">
        <span class="material-symbols-rounded fs-6">edit</span>
        <span>Edit Recipe Info</span>
      </a>
    <?php endif; ?>
    <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-secondary-custom btn-sm">
      <span class="material-symbols-rounded fs-6">arrow_back</span>
      <span>Back to Recipes</span>
    </a>
  </div>
</div>

<!-- Recipe Selector Dropdown -->
<div class="card-box mb-4 p-3 bg-light border">
  <form method="GET" action="" class="row g-3 align-items-center">
    <div class="col-md-3">
      <label for="recipe_id_select" class="form-label mb-0 fw-bold">Select Recipe to Map:</label>
    </div>
    <div class="col-md-6">
      <select name="recipe_id" id="recipe_id_select" class="form-select fw-semibold" onchange="this.form.submit()">
        <?php foreach ($allRecipes as $r): ?>
          <option value="<?= $r['id'] ?>" <?= $recipeId === (int)$r['id'] ? 'selected' : '' ?>>
            <?= e($r['title']) ?>
          </option>
        <?php endforeach; ?>
      </select>
    </div>
  </form>
</div>

<?php if (!$recipe): ?>
  <div class="card-box empty-state">
    <div class="empty-icon"><span class="material-symbols-rounded">restaurant</span></div>
    <div class="empty-title">No Recipe Found</div>
    <p class="empty-text">Please create a recipe before mapping ingredients.</p>
    <a href="<?= base_url('recipes/create.php') ?>" class="btn btn-primary-custom">Create Recipe</a>
  </div>
<?php else: ?>
  <div class="row g-4">
    <!-- Existing Mapped Ingredients Table -->
    <div class="col-lg-7">
      <div class="card-box">
        <div class="d-flex align-items-center justify-content-between mb-3">
          <div>
            <h3 class="fw-bold mb-0" style="font-size: 16px;"><?= e($recipe['title']) ?></h3>
            <span class="text-muted small"><strong><?= count($ingredients) ?></strong> grocery ingredients mapped</span>
          </div>
          <span class="badge-status <?= e($recipe['status']) ?>"><?= ucfirst(e($recipe['status'])) ?></span>
        </div>

        <?php if (empty($ingredients)): ?>
          <div class="empty-state py-4">
            <div class="empty-title">No ingredients mapped yet.</div>
            <p class="empty-text">Add grocery items using the form on the right so the mobile app can match pantry groceries to this recipe.</p>
          </div>
        <?php else: ?>
          <div class="table-responsive">
            <table class="custom-table">
              <thead>
                <tr>
                  <th>Grocery Ingredient</th>
                  <th>Quantity</th>
                  <th>Unit</th>
                  <th>Requirement</th>
                  <th class="text-end" style="width: 80px;">Action</th>
                </tr>
              </thead>
              <tbody>
                <?php foreach ($ingredients as $ing): ?>
                  <tr>
                    <td>
                      <div class="fw-bold text-dark d-flex align-items-center gap-2">
                        <span class="material-symbols-rounded text-success fs-5">grocery</span>
                        <span><?= e($ing['ingredient_name']) ?></span>
                      </div>
                    </td>
                    <td>
                      <span class="fw-semibold text-secondary"><?= e($ing['quantity'] ?: '—') ?></span>
                    </td>
                    <td>
                      <span class="text-muted small"><?= e($ing['unit'] ?: '—') ?></span>
                    </td>
                    <td>
                      <?php if ($ing['is_required']): ?>
                        <span class="badge bg-success-subtle text-success px-2.5 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                          Required
                        </span>
                      <?php else: ?>
                        <span class="badge bg-secondary-subtle text-muted px-2.5 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                          Optional
                        </span>
                      <?php endif; ?>
                    </td>
                    <td class="text-end">
                      <form method="POST" action="" onsubmit="return confirmDelete('Remove \'<?= e(addslashes($ing['ingredient_name'])) ?>\' from this recipe?');" class="d-inline">
                        <?= csrf_field() ?>
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="ingredient_id" value="<?= $ing['id'] ?>">
                        <button type="submit" class="btn-action-icon danger" title="Remove Ingredient">
                          <span class="material-symbols-rounded" style="font-size: 16px;">close</span>
                        </button>
                      </form>
                    </td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>
      </div>
    </div>

    <!-- Add Ingredient Form -->
    <div class="col-lg-5">
      <div class="card-box">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Map New Grocery Item</h3>
        <p class="text-muted small mb-3">Map a required or optional grocery item from your pantry to this recipe.</p>

        <form method="POST" action="">
          <?= csrf_field() ?>
          <input type="hidden" name="action" value="add">

          <div class="mb-3">
            <label for="ingredient_name" class="form-label">Grocery Item Name <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="ingredient_name" name="ingredient_name" required placeholder="e.g. Sourdough Bread, Milk, Pure Ghee">
          </div>

          <div class="row g-2 mb-3">
            <div class="col-6">
              <label for="quantity" class="form-label">Quantity</label>
              <input type="text" class="form-control" id="quantity" name="quantity" placeholder="e.g. 2, 500, 1">
            </div>
            <div class="col-6">
              <label for="unit" class="form-label">Unit</label>
              <input type="text" class="form-control" id="unit" name="unit" placeholder="e.g. slices, ml, tbsp">
            </div>
          </div>

          <div class="mb-4">
            <label for="is_required" class="form-label">Ingredient Status</label>
            <select class="form-select" id="is_required" name="is_required">
              <option value="1">Required (Must have in pantry)</option>
              <option value="0">Optional (Garnish / Taste)</option>
            </select>
          </div>

          <button type="submit" class="btn btn-primary-custom w-100 justify-content-center">
            <span class="material-symbols-rounded fs-5">add</span>
            <span>Map Ingredient to Recipe</span>
          </button>
        </form>
      </div>
    </div>
  </div>
<?php endif; ?>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
