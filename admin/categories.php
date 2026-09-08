<?php
/**
 * ScanSmart Category & Subcategory Management
 * Includes Automatic Categorization Engine (Keywords & AI Rules)
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Handle New Subcategory Creation (Quick POST)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add_subcategory') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_categories()) {
        set_flash('error', 'You do not have permission to add subcategories.');
    } else {
        $catId = (int)($_POST['category_id'] ?? 0);
        $name = trim($_POST['name'] ?? '');
        $desc = trim($_POST['description'] ?? '');

        if ($catId <= 0 || $name === '') {
            set_flash('error', 'Category ID and Subcategory Name are required.');
        } else {
            $stmt = $db->prepare('INSERT INTO subcategories (category_id, name, description) VALUES (?, ?, ?)');
            $stmt->execute([$catId, $name, $desc ?: null]);
            log_admin_activity('Add Subcategory', "Added subcategory '{$name}' to Category #{$catId}");
            set_flash('success', "Subcategory '{$name}' added successfully.");
        }
    }
    header('Location: ' . base_url('categories.php'));
    exit;
}

// Handle Keyword Rule Creation (Quick POST)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'add_keyword') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_categories()) {
        set_flash('error', 'Permission denied.');
    } else {
        $catId = (int)($_POST['category_id'] ?? 0);
        $keyword = strtolower(trim($_POST['keyword'] ?? ''));
        $subcatName = trim($_POST['subcategory_name'] ?? '');
        $score = max(50, min(100, (int)($_POST['confidence_score'] ?? 90)));

        if ($catId <= 0 || $keyword === '') {
            set_flash('error', 'Category and Keyword are required.');
        } else {
            $stmt = $db->prepare('INSERT INTO category_keywords (category_id, keyword, subcategory_name, confidence_score) VALUES (?, ?, ?, ?)');
            $stmt->execute([$catId, $keyword, $subcatName ?: null, $score]);
            log_admin_activity('Add Classification Keyword', "Added keyword rule '{$keyword}' with confidence {$score}%");
            set_flash('success', "Keyword '{$keyword}' added to classification engine.");
        }
    }
    header('Location: ' . base_url('categories.php?tab=keywords'));
    exit;
}

// Delete Keyword Rule
if (isset($_GET['del_keyword']) && can_edit_categories()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token invalid.');
    } else {
        $kwId = (int)$_GET['del_keyword'];
        $db->prepare('DELETE FROM category_keywords WHERE id = ?')->execute([$kwId]);
        set_flash('success', 'Classification keyword removed.');
    }
    header('Location: ' . base_url('categories.php?tab=keywords'));
    exit;
}

// Fetch all categories with product counts and subcategories
$catStmt = $db->query("
    SELECT c.*, COUNT(p.id) AS product_count
    FROM categories c
    LEFT JOIN products p ON (p.category_id = c.id OR p.category = c.name) AND p.status != 'Archived'
    GROUP BY c.id
    ORDER BY c.sort_order ASC, c.name ASC
");
$categories = $catStmt->fetchAll();

// Fetch all subcategories grouped by category_id
$subStmt = $db->query("SELECT * FROM subcategories ORDER BY name ASC");
$allSubcats = $subStmt->fetchAll();
$subcatsByCat = [];
foreach ($allSubcats as $sc) {
    $subcatsByCat[$sc['category_id']][] = $sc;
}

// Fetch category keywords
$kwStmt = $db->query("
    SELECT k.*, c.name AS category_name, c.color AS category_color
    FROM category_keywords k
    JOIN categories c ON c.id = k.category_id
    ORDER BY c.name ASC, k.confidence_score DESC
");
$keywords = $kwStmt->fetchAll();

$activeTab = trim((string)($_GET['tab'] ?? 'categories'));

$pageTitle = 'Category Management & Auto-Categorization';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Categories & Smart Classification</h2>
    <p class="text-muted small mb-0">Manage universal catalog categories, subcategories, and keyword auto-tagging rules.</p>
  </div>
  <div class="d-flex gap-2">
    <?php if (can_edit_categories()): ?>
      <a href="<?= base_url('category-add.php') ?>" class="btn btn-primary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
        <span class="material-symbols-rounded fs-5">add</span>
        <span>Add Category</span>
      </a>
      <button type="button" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" data-bs-toggle="modal" data-bs-target="#modalAddKeyword">
        <span class="material-symbols-rounded fs-5">psychology</span>
        <span>Add Keyword Rule</span>
      </button>
    <?php endif; ?>
  </div>
</div>

<!-- Navigation Tabs -->
<ul class="nav nav-pills mb-4 gap-2">
  <li class="nav-item">
    <a class="nav-link rounded-pill px-4 py-2 fw-semibold <?= $activeTab === 'categories' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('categories.php?tab=categories') ?>" style="<?= $activeTab === 'categories' ? 'background-color: #10B981;' : '' ?>">
      <span class="d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">category</span>
        <span>Categories & Subcategories (<?= count($categories) ?>)</span>
      </span>
    </a>
  </li>
  <li class="nav-item">
    <a class="nav-link rounded-pill px-4 py-2 fw-semibold <?= $activeTab === 'keywords' ? 'active' : 'bg-white border text-dark' ?>" href="<?= base_url('categories.php?tab=keywords') ?>" style="<?= $activeTab === 'keywords' ? 'background-color: #10B981;' : '' ?>">
      <span class="d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">smart_toy</span>
        <span>Smart Auto-Classification Engine (<?= count($keywords) ?>)</span>
      </span>
    </a>
  </li>
</ul>

<?php if ($activeTab === 'keywords'): ?>
  <!-- =======================================================================
       TAB 2: SMART CATEGORIZATION ENGINE & KEYWORD MATCHING
       ======================================================================= -->
  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
    <div class="p-3 px-4 border-bottom d-flex justify-content-between align-items-center">
      <div>
        <h5 class="fw-bold mb-0">Automatic Keyword Rules</h5>
        <div class="text-muted small">When a product or barcode is scanned, OCR and product titles are matched against these rules to infer categories.</div>
      </div>
      <button type="button" class="btn btn-sm btn-primary rounded-pill px-3" style="background-color: #10B981; border-color: #10B981;" data-bs-toggle="modal" data-bs-target="#modalAddKeyword">
        + New Keyword Rule
      </button>
    </div>
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
        <thead class="table-light">
          <tr>
            <th>Keyword / Pattern</th>
            <th>Mapped Category</th>
            <th>Mapped Subcategory</th>
            <th>Confidence Score</th>
            <th>Date Added</th>
            <th width="80" class="text-end">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($keywords)): ?>
            <tr>
              <td colspan="6" class="text-center py-4 text-muted">No keyword classification rules defined yet.</td>
            </tr>
          <?php else: ?>
            <?php foreach ($keywords as $kw): ?>
              <tr>
                <td><code class="fw-bold text-dark fs-6"><?= e($kw['keyword']) ?></code></td>
                <td>
                  <span class="badge rounded-pill px-2.5 py-1" style="background-color: <?= e($kw['category_color'] ?: '#10B981') ?>1A; color: <?= e($kw['category_color'] ?: '#10B981') ?>; border: 1px solid <?= e($kw['category_color'] ?: '#10B981') ?>40;">
                    <?= e($kw['category_name']) ?>
                  </span>
                </td>
                <td><?= e($kw['subcategory_name'] ?: '—') ?></td>
                <td>
                  <div class="d-flex align-items-center gap-2">
                    <div class="progress flex-grow-1" style="height: 6px; width: 60px;">
                      <div class="progress-bar bg-success" role="progressbar" style="width: <?= (int)$kw['confidence_score'] ?>%;"></div>
                    </div>
                    <span class="fw-bold small"><?= (int)$kw['confidence_score'] ?>%</span>
                  </div>
                </td>
                <td class="text-muted small"><?= format_date($kw['created_at']) ?></td>
                <td class="text-end">
                  <?php if (can_edit_categories()): ?>
                    <a href="<?= base_url('categories.php?tab=keywords&del_keyword=' . (int)$kw['id'] . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border text-danger py-1 px-2 rounded-2" title="Remove Keyword" onclick="return confirm('Remove keyword rule?');">
                      <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                    </a>
                  <?php endif; ?>
                </td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>
  </div>

<?php else: ?>
  <!-- =======================================================================
       TAB 1: MAIN CATEGORIES & SUBCATEGORIES
       ======================================================================= -->
  <div class="row g-4">
    <?php foreach ($categories as $cat): 
      $subs = $subcatsByCat[$cat['id']] ?? [];
    ?>
      <div class="col-md-6 col-xl-4">
        <div class="card border-0 shadow-sm rounded-4 h-100 bg-white p-4 position-relative">
          <div class="d-flex justify-content-between align-items-start mb-3">
            <div class="d-flex align-items-center gap-3">
              <div class="rounded-3 d-flex align-items-center justify-content-center shadow-xs" style="width: 46px; height: 46px; background-color: <?= e($cat['color'] ?: '#10B981') ?>20; color: <?= e($cat['color'] ?: '#10B981') ?>;">
                <span class="material-symbols-rounded fs-4"><?= e($cat['icon'] ?: 'category') ?></span>
              </div>
              <div>
                <h5 class="fw-bold mb-0 text-dark"><?= e($cat['name']) ?></h5>
                <span class="badge bg-light text-muted border rounded-pill" style="font-size: 11px;">
                  <?= number_format((int)$cat['product_count']) ?> products cataloged
                </span>
              </div>
            </div>

            <div class="dropdown">
              <button class="btn btn-sm btn-light border rounded-pill px-2 py-1" type="button" data-bs-toggle="dropdown" aria-expanded="false">
                <span class="material-symbols-rounded" style="font-size: 18px;">more_vert</span>
              </button>
              <ul class="dropdown-menu dropdown-menu-end shadow-sm border-0 rounded-4">
                <?php if (can_edit_categories()): ?>
                  <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="<?= base_url('category-edit.php?id=' . (int)$cat['id']) ?>"><span class="material-symbols-rounded fs-6">edit</span>Edit Category</a></li>
                  <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="#" data-bs-toggle="modal" data-bs-target="#modalAddSubcat<?= $cat['id'] ?>"><span class="material-symbols-rounded fs-6">add</span>Add Subcategory</a></li>
                <?php endif; ?>
                <li><a class="dropdown-item py-2 d-flex align-items-center gap-2" href="<?= base_url('products.php?category=' . urlencode($cat['name'])) ?>"><span class="material-symbols-rounded fs-6">list</span>View Products</a></li>
                <?php if (can_edit_categories()): ?>
                  <li><hr class="dropdown-divider"></li>
                  <li>
                    <a class="dropdown-item py-2 text-danger d-flex align-items-center gap-2" href="<?= base_url('category-delete.php?id=' . (int)$cat['id'] . '&csrf_token=' . e(csrf_token())) ?>" onclick="return confirm('Delete category <?= addslashes(htmlspecialchars($cat['name'])) ?>?');">
                      <span class="material-symbols-rounded fs-6">delete</span>Delete Category
                    </a>
                  </li>
                <?php endif; ?>
              </ul>
            </div>
          </div>

          <p class="text-muted small mb-3 flex-grow-1"><?= e($cat['description'] ?: 'No category description provided.') ?></p>

          <!-- Subcategories Pills -->
          <div class="border-top pt-3 mt-auto">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <span class="text-muted fw-bold" style="font-size: 11.5px; text-transform: uppercase;">Subcategories (<?= count($subs) ?>)</span>
              <?php if (can_edit_categories()): ?>
                <button type="button" class="btn btn-sm btn-link text-decoration-none p-0 text-primary small fw-semibold" data-bs-toggle="modal" data-bs-target="#modalAddSubcat<?= $cat['id'] ?>">
                  + Add
                </button>
              <?php endif; ?>
            </div>

            <div class="d-flex flex-wrap gap-1.5">
              <?php if (empty($subs)): ?>
                <span class="text-muted small">No subcategories defined.</span>
              <?php else: ?>
                <?php foreach ($subs as $sub): ?>
                  <span class="badge bg-light text-dark border rounded-pill" style="font-size: 11px;"><?= e($sub['name']) ?></span>
                <?php endforeach; ?>
              <?php endif; ?>
            </div>
          </div>
        </div>
      </div>

      <!-- Modal Add Subcategory for this Category -->
      <div class="modal fade" id="modalAddSubcat<?= $cat['id'] ?>" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
          <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-bottom">
              <h5 class="modal-title fw-bold">Add Subcategory to <?= e($cat['name']) ?></h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form method="POST" action="">
              <?= csrf_field() ?>
              <input type="hidden" name="action" value="add_subcategory">
              <input type="hidden" name="category_id" value="<?= $cat['id'] ?>">

              <div class="modal-body p-4">
                <div class="mb-3">
                  <label for="subcat_name_<?= $cat['id'] ?>" class="form-label small fw-bold">Subcategory Name <span class="text-danger">*</span></label>
                  <input type="text" name="name" id="subcat_name_<?= $cat['id'] ?>" class="form-control" placeholder="e.g. Organic Dairy" required>
                </div>
                <div class="mb-0">
                  <label for="subcat_desc_<?= $cat['id'] ?>" class="form-label small fw-bold">Description</label>
                  <textarea name="description" id="subcat_desc_<?= $cat['id'] ?>" rows="2" class="form-control" placeholder="Brief notes..."></textarea>
                </div>
              </div>
              <div class="modal-footer border-top">
                <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
                <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Save Subcategory</button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <?php endforeach; ?>
  </div>
<?php endif; ?>

<!-- Modal: Add Keyword Rule -->
<div class="modal fade" id="modalAddKeyword" tabindex="-1" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content rounded-4 border-0 shadow">
      <div class="modal-header border-bottom">
        <h5 class="modal-title fw-bold">Add Auto-Categorization Keyword Rule</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form method="POST" action="">
        <?= csrf_field() ?>
        <input type="hidden" name="action" value="add_keyword">

        <div class="modal-body p-4">
          <p class="text-muted small">When a product name or OCR matches this keyword, ScanSmart will automatically suggest this category.</p>

          <div class="mb-3">
            <label for="kw_word" class="form-label small fw-bold">Keyword / Pattern <span class="text-danger">*</span></label>
            <input type="text" name="keyword" id="kw_word" class="form-control" placeholder="e.g. moisturizer, paracetamol, biscuit" required>
          </div>

          <div class="mb-3">
            <label for="kw_cat" class="form-label small fw-bold">Target Category <span class="text-danger">*</span></label>
            <select name="category_id" id="kw_cat" class="form-select" required>
              <?php foreach ($categories as $cat): ?>
                <option value="<?= $cat['id'] ?>"><?= e($cat['name']) ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="mb-3">
            <label for="kw_subcat" class="form-label small fw-bold">Target Subcategory (Optional)</label>
            <input type="text" name="subcategory_name" id="kw_subcat" class="form-control" placeholder="e.g. Skincare">
          </div>

          <div class="mb-0">
            <label for="kw_score" class="form-label small fw-bold">Confidence Score (50 - 100%)</label>
            <input type="number" min="50" max="100" name="confidence_score" id="kw_score" class="form-control" value="95" required>
          </div>
        </div>
        <div class="modal-footer border-top">
          <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Add Keyword Rule</button>
        </div>
      </form>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
