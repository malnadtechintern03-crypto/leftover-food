<?php
/**
 * Recipe Management - Create Recipe with Inline Ingredients
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

// Fetch active categories
$categories = $db->query("SELECT id, name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll();

$errorMessage = '';
$title = '';
$categoryId = 0;
$description = '';
$imageUrl = '';
$youtubeUrl = '';
$prepTime = '15 mins';
$difficulty = 'Easy';
$calories = 0;
$instructions = '';
$status = 'published';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errorMessage = 'Security token invalid or expired. Please resubmit.';
    } else {
        $title = trim($_POST['title'] ?? '');
        $categoryId = (int)($_POST['category_id'] ?? 0);
        $description = trim($_POST['description'] ?? '');
        $imageUrl = trim($_POST['image_url'] ?? '');
        $youtubeUrl = trim($_POST['youtube_url'] ?? '');
        $prepTime = trim($_POST['prep_time'] ?? '15 mins');
        $difficulty = in_array($_POST['difficulty'] ?? '', ['Easy', 'Medium', 'Hard'], true) ? $_POST['difficulty'] : 'Easy';
        $calories = (int)($_POST['calories'] ?? 0);
        $instructions = trim($_POST['instructions'] ?? '');
        $status = in_array($_POST['status'] ?? '', ['published', 'draft'], true) ? $_POST['status'] : 'published';

        // Extract YouTube ID if URL provided
        $youtubeId = null;
        if (!empty($youtubeUrl)) {
            if (preg_match('/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i', $youtubeUrl, $match)) {
                $youtubeId = $match[1];
            }
        }

        if ($title === '') {
            $errorMessage = 'Recipe title is required.';
        } else {
            try {
                $db->beginTransaction();

                $stmt = $db->prepare('
                    INSERT INTO recipes 
                    (title, category_id, description, image_url, youtube_id, youtube_url, prep_time, difficulty, calories, instructions, status) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ');
                $stmt->execute([
                    $title,
                    $categoryId > 0 ? $categoryId : null,
                    $description,
                    $imageUrl ?: null,
                    $youtubeId,
                    $youtubeUrl ?: null,
                    $prepTime,
                    $difficulty,
                    $calories,
                    $instructions,
                    $status
                ]);

                $recipeId = (int)$db->lastInsertId();

                // Save inline recipe ingredients if entered
                $ingredients = $_POST['ingredients'] ?? [];
                if (is_array($ingredients)) {
                    $ingStmt = $db->prepare('
                        INSERT INTO recipe_ingredients (recipe_id, ingredient_name, quantity, unit, is_required)
                        VALUES (?, ?, ?, ?, ?)
                    ');

                    foreach ($ingredients as $ing) {
                        $ingName = trim($ing['name'] ?? '');
                        if ($ingName !== '') {
                            $ingQty = trim($ing['quantity'] ?? '');
                            $ingUnit = trim($ing['unit'] ?? '');
                            $isRequired = (int)($ing['is_required'] ?? 1);

                            $ingStmt->execute([
                                $recipeId,
                                $ingName,
                                $ingQty ?: null,
                                $ingUnit ?: null,
                                $isRequired
                            ]);
                        }
                    }
                }

                $db->commit();
                set_flash('success', "Recipe '{$title}' created successfully.");
                header('Location: ' . base_url('recipes/index.php'));
                exit;
            } catch (Exception $e) {
                if ($db->inTransaction()) {
                    $db->rollBack();
                }
                $errorMessage = 'Error saving recipe: ' . $e->getMessage();
            }
        }
    }
}

$pageTitle = 'Add Smart Recipe';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="row justify-content-center">
  <div class="col-lg-10">
    <div class="card-box">
      <div class="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
        <div>
          <h2 class="fw-bold mb-1" style="font-size: 18px;">Create New Smart Recipe</h2>
          <span class="text-muted small">Configure recipe instructions, cooking metrics, and map grocery ingredients.</span>
        </div>
        <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-secondary-custom btn-sm">
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

        <div class="row g-3 mb-3">
          <div class="col-md-8">
            <label for="title" class="form-label">Recipe Title <span class="text-danger">*</span></label>
            <input type="text" class="form-control" id="title" name="title" value="<?= e($title) ?>" required placeholder="e.g. Aromatic Tadka Dal & Basmati Rice">
          </div>

          <div class="col-md-4">
            <label for="category_id" class="form-label">Grocery Category</label>
            <select class="form-select" id="category_id" name="category_id">
              <option value="0">Select Category...</option>
              <?php foreach ($categories as $cat): ?>
                <option value="<?= $cat['id'] ?>" <?= $categoryId === (int)$cat['id'] ? 'selected' : '' ?>>
                  <?= e($cat['name']) ?>
                </option>
              <?php endforeach; ?>
            </select>
          </div>
        </div>

        <div class="mb-3">
          <label for="description" class="form-label">Description & Summary</label>
          <textarea class="form-control" id="description" name="description" rows="2" placeholder="Appetizing summary of this recipe..."><?= e($description) ?></textarea>
        </div>

        <div class="row g-3 mb-3">
          <div class="col-md-4">
            <label for="prep_time" class="form-label">Cooking / Prep Time</label>
            <input type="text" class="form-control" id="prep_time" name="prep_time" value="<?= e($prepTime) ?>" placeholder="e.g. 15 mins">
          </div>

          <div class="col-md-4">
            <label for="difficulty" class="form-label">Difficulty</label>
            <select class="form-select" id="difficulty" name="difficulty">
              <option value="Easy" <?= $difficulty === 'Easy' ? 'selected' : '' ?>>Easy</option>
              <option value="Medium" <?= $difficulty === 'Medium' ? 'selected' : '' ?>>Medium</option>
              <option value="Hard" <?= $difficulty === 'Hard' ? 'selected' : '' ?>>Hard</option>
            </select>
          </div>

          <div class="col-md-4">
            <label for="calories" class="form-label">Calories (kcal)</label>
            <input type="number" class="form-control" id="calories" name="calories" value="<?= $calories ?>" min="0" placeholder="e.g. 340">
          </div>
        </div>

        <div class="row g-3 mb-3">
          <div class="col-md-6">
            <label for="image_url" class="form-label">Photo / Image URL</label>
            <input type="url" class="form-control" id="image_url" name="image_url" value="<?= e($imageUrl) ?>" placeholder="https://images.unsplash.com/...">
          </div>

          <div class="col-md-6">
            <label for="youtube_url" class="form-label">YouTube Video Tutorial URL</label>
            <input type="url" class="form-control" id="youtube_url" name="youtube_url" value="<?= e($youtubeUrl) ?>" placeholder="https://www.youtube.com/watch?v=...">
          </div>
        </div>

        <div class="mb-4">
          <label for="instructions" class="form-label">Cooking Instructions</label>
          <textarea class="form-control" id="instructions" name="instructions" rows="4" placeholder="1. Rinse ingredients under water.&#10;2. Heat oil in a pan..."><?= e($instructions) ?></textarea>
        </div>

        <!-- Dynamic Ingredients Section -->
        <div class="card-box bg-light border p-3 mb-4">
          <div class="d-flex align-items-center justify-content-between mb-3">
            <div>
              <h4 class="fw-bold mb-0 text-dark" style="font-size: 15px;">Mapped Grocery Ingredients</h4>
              <span class="text-muted small">Required for calculating pantry match percentage and "Use It First" suggestions.</span>
            </div>
            <button type="button" class="btn btn-sm btn-outline-success d-inline-flex align-items-center gap-1" id="btnAddIngredientRow">
              <span class="material-symbols-rounded fs-6">add</span>
              <span>Add Ingredient</span>
            </button>
          </div>

          <div id="ingredientsContainer">
            <!-- Initial Ingredient Row 1 -->
            <div class="row g-2 mb-2 align-items-center ingredient-row">
              <div class="col-md-5">
                <input type="text" name="ingredients[0][name]" class="form-control" placeholder="Ingredient Name (e.g. Basmati Rice)">
              </div>
              <div class="col-md-2">
                <input type="text" name="ingredients[0][quantity]" class="form-control" placeholder="Qty (e.g. 1)">
              </div>
              <div class="col-md-2">
                <input type="text" name="ingredients[0][unit]" class="form-control" placeholder="Unit (e.g. cup)">
              </div>
              <div class="col-md-2">
                <select name="ingredients[0][is_required]" class="form-select">
                  <option value="1">Required</option>
                  <option value="0">Optional</option>
                </select>
              </div>
              <div class="col-md-1 text-center">
                <button type="button" class="btn btn-sm btn-outline-danger btn-remove-row" title="Remove ingredient">
                  <span class="material-symbols-rounded" style="font-size: 18px;">delete</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <div class="row g-3 mb-4 align-items-center">
          <div class="col-md-6">
            <label for="status" class="form-label">Publication Status</label>
            <select class="form-select" id="status" name="status">
              <option value="published" <?= $status === 'published' ? 'selected' : '' ?>>Published (Visible to Mobile Users)</option>
              <option value="draft" <?= $status === 'draft' ? 'selected' : '' ?>>Draft (Admin only)</option>
            </select>
          </div>
        </div>

        <div class="d-flex align-items-center justify-content-end gap-2 pt-3 border-top">
          <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
          <button type="submit" class="btn btn-primary-custom">
            <span class="material-symbols-rounded fs-6">save</span>
            <span>Save Recipe</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
