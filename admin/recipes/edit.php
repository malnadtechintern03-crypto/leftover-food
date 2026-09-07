<?php
/**
 * Recipe Management - Edit Recipe
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    set_flash('danger', 'Invalid recipe ID.');
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

$db = Database::getConnection();
$stmt = $db->prepare('SELECT * FROM recipes WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$recipe = $stmt->fetch();

if (!$recipe) {
    set_flash('danger', 'Recipe not found.');
    header('Location: ' . base_url('recipes/index.php'));
    exit;
}

// Fetch categories
$categories = $db->query("SELECT id, name FROM categories ORDER BY name ASC")->fetchAll();

$errorMessage = '';
$title = $recipe['title'];
$categoryId = (int)($recipe['category_id'] ?? 0);
$description = $recipe['description'] ?? '';
$imageUrl = $recipe['image_url'] ?? '';
$youtubeUrl = $recipe['youtube_url'] ?? '';
$prepTime = $recipe['prep_time'] ?? '15 mins';
$difficulty = $recipe['difficulty'] ?? 'Easy';
$calories = (int)($recipe['calories'] ?? 0);
$instructions = $recipe['instructions'] ?? '';
$status = $recipe['status'] ?? 'published';

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

        $youtubeId = null;
        if (!empty($youtubeUrl)) {
            if (preg_match('/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i', $youtubeUrl, $match)) {
                $youtubeId = $match[1];
            }
        }

        if ($title === '') {
            $errorMessage = 'Recipe title is required.';
        } else {
            $updateStmt = $db->prepare('
                UPDATE recipes 
                SET title = ?, category_id = ?, description = ?, image_url = ?, youtube_id = ?, youtube_url = ?, 
                    prep_time = ?, difficulty = ?, calories = ?, instructions = ?, status = ?
                WHERE id = ?
            ');
            $updateStmt->execute([
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
                $status,
                $id
            ]);

            set_flash('success', "Recipe '{$title}' updated successfully.");
            header('Location: ' . base_url('recipes/index.php'));
            exit;
        }
    }
}

$pageTitle = 'Edit Recipe — ' . $recipe['title'];
require_once __DIR__ . '/../includes/header.php';
?>

<div class="row justify-content-center">
  <div class="col-lg-10">
    <div class="card-box">
      <div class="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
        <div>
          <h2 class="fw-bold mb-1" style="font-size: 18px;">Edit Recipe</h2>
          <span class="text-muted small">Update cooking details, media, and publishing status.</span>
        </div>
        <div class="d-flex gap-2">
          <a href="<?= base_url('recipes/ingredients.php?recipe_id=' . $id) ?>" class="btn btn-outline-success btn-sm d-inline-flex align-items-center gap-1">
            <span class="material-symbols-rounded fs-6">grocery</span>
            <span>Manage Ingredients</span>
          </a>
          <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-secondary-custom btn-sm">
            <span class="material-symbols-rounded fs-6">arrow_back</span>
            <span>Back</span>
          </a>
        </div>
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
            <input type="text" class="form-control" id="title" name="title" value="<?= e($title) ?>" required>
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
          <textarea class="form-control" id="description" name="description" rows="2"><?= e($description) ?></textarea>
        </div>

        <div class="row g-3 mb-3">
          <div class="col-md-4">
            <label for="prep_time" class="form-label">Cooking / Prep Time</label>
            <input type="text" class="form-control" id="prep_time" name="prep_time" value="<?= e($prepTime) ?>">
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
            <input type="number" class="form-control" id="calories" name="calories" value="<?= $calories ?>" min="0">
          </div>
        </div>

        <div class="row g-3 mb-3">
          <div class="col-md-6">
            <label for="image_url" class="form-label">Photo / Image URL</label>
            <input type="url" class="form-control" id="image_url" name="image_url" value="<?= e($imageUrl) ?>">
          </div>

          <div class="col-md-6">
            <label for="youtube_url" class="form-label">YouTube Video Tutorial URL</label>
            <input type="url" class="form-control" id="youtube_url" name="youtube_url" value="<?= e($youtubeUrl) ?>">
          </div>
        </div>

        <div class="mb-4">
          <label for="instructions" class="form-label">Cooking Instructions</label>
          <textarea class="form-control" id="instructions" name="instructions" rows="5"><?= e($instructions) ?></textarea>
        </div>

        <div class="row g-3 mb-4">
          <div class="col-md-6">
            <label for="status" class="form-label">Publication Status</label>
            <select class="form-select" id="status" name="status">
              <option value="published" <?= $status === 'published' ? 'selected' : '' ?>>Published (Visible in App)</option>
              <option value="draft" <?= $status === 'draft' ? 'selected' : '' ?>>Draft (Hidden)</option>
            </select>
          </div>
        </div>

        <div class="d-flex align-items-center justify-content-end gap-2 pt-3 border-top">
          <a href="<?= base_url('recipes/index.php') ?>" class="btn btn-secondary-custom">Cancel</a>
          <button type="submit" class="btn btn-primary-custom">
            <span class="material-symbols-rounded fs-6">save</span>
            <span>Update Recipe</span>
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
