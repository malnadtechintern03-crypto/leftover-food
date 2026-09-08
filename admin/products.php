<?php
/**
 * ScanSmart Product Management - Master Catalog
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Handle Bulk Actions (Bulk Delete / Bulk Archive)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['bulk_action'])) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired. Please try again.');
        header('Location: ' . base_url('products.php'));
        exit;
    }

    if (!can_delete_products()) {
        set_flash('error', 'You do not have permission to delete products.');
        header('Location: ' . base_url('products.php'));
        exit;
    }

    $action = $_POST['bulk_action'];
    $selectedIds = $_POST['selected_ids'] ?? [];

    if (is_array($selectedIds) && !empty($selectedIds)) {
        $placeholders = implode(',', array_fill(0, count($selectedIds), '?'));
        if ($action === 'archive') {
            $stmt = $db->prepare("UPDATE products SET status = 'Archived' WHERE id IN ($placeholders)");
            $stmt->execute($selectedIds);
            log_admin_activity('Bulk Archive Products', 'Archived ' . count($selectedIds) . ' products');
            set_flash('success', 'Successfully archived ' . count($selectedIds) . ' products.');
        } elseif ($action === 'delete') {
            // Soft delete or remove associated reminders and products
            $delRem = $db->prepare("DELETE FROM product_reminders WHERE product_id IN ($placeholders)");
            $delRem->execute($selectedIds);

            $stmt = $db->prepare("DELETE FROM products WHERE id IN ($placeholders)");
            $stmt->execute($selectedIds);
            log_admin_activity('Bulk Delete Products', 'Permanently deleted ' . count($selectedIds) . ' products');
            set_flash('success', 'Successfully deleted ' . count($selectedIds) . ' products.');
        }
    }
    header('Location: ' . base_url('products.php'));
    exit;
}

// Handle CSV Export
if (isset($_GET['export']) && $_GET['export'] === 'csv') {
    $exportStmt = $db->query("
        SELECT id, barcode, name, brand, category, subcategory, quantity, unit, purchase_price, currency,
               manufacturing_date, expiry_date, status, review_status, storage_location, created_at
        FROM products
        ORDER BY created_at DESC
    ");
    $rows = $exportStmt->fetchAll();
    $headers = ['ID', 'Barcode', 'Name', 'Brand', 'Category', 'Subcategory', 'Quantity', 'Unit', 'Price', 'Currency', 'Mfg Date', 'Expiry Date', 'Status', 'Review Status', 'Location', 'Created At'];
    log_admin_activity('Export Products CSV', 'Exported product catalog to CSV (' . count($rows) . ' records)');
    export_to_csv('scansmart_products_' . date('Ymd_His') . '.csv', $headers, $rows);
}

// Handle CSV Import
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['csv_file'])) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_products()) {
        set_flash('error', 'You do not have permission to import products.');
    } else {
        $file = $_FILES['csv_file'];
        if ($file['error'] === UPLOAD_ERR_OK && is_uploaded_file($file['tmp_name'])) {
            $handle = fopen($file['tmp_name'], 'r');
            // Check BOM
            $bom = fread($handle, 3);
            if ($bom !== "\xEF\xBB\xBF") {
                rewind($handle);
            }

            $imported = 0;
            $rowNum = 0;
            $insertStmt = $db->prepare("
                INSERT INTO products (id, barcode, name, brand, category, subcategory, quantity, unit, purchase_price, expiry_date, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE name = VALUES(name), brand = VALUES(brand), category = VALUES(category), quantity = VALUES(quantity), purchase_price = VALUES(purchase_price), expiry_date = VALUES(expiry_date)
            ");

            while (($data = fgetcsv($handle, 2000, ',')) !== false) {
                $rowNum++;
                if ($rowNum === 1 && (strtolower($data[0] ?? '') === 'id' || strtolower($data[1] ?? '') === 'barcode' || strtolower($data[2] ?? '') === 'name')) {
                    continue; // Skip header
                }
                $name = trim($data[2] ?? $data[0] ?? '');
                if ($name === '') continue;

                $id = !empty($data[0]) ? trim($data[0]) : bin2hex(random_bytes(16));
                $barcode = !empty($data[1]) ? trim($data[1]) : null;
                $brand = !empty($data[3]) ? trim($data[3]) : null;
                $cat = !empty($data[4]) ? trim($data[4]) : 'Other';
                $subcat = !empty($data[5]) ? trim($data[5]) : null;
                $qty = isset($data[6]) && is_numeric($data[6]) ? (float)$data[6] : 1.0;
                $unit = !empty($data[7]) ? trim($data[7]) : 'pieces';
                $price = isset($data[8]) && is_numeric($data[8]) ? (float)$data[8] : null;
                $expiry = !empty($data[11]) && strtotime($data[11]) ? date('Y-m-d', strtotime($data[11])) : null;
                $status = !empty($data[12]) && in_array(trim($data[12]), ['Active', 'Inactive', 'Pending Review', 'Archived']) ? trim($data[12]) : 'Active';

                try {
                    $insertStmt->execute([$id, $barcode, $name, $brand, $cat, $subcat, $qty, $unit, $price, $expiry, $status]);
                    $imported++;
                } catch (Throwable) {}
            }
            fclose($handle);
            log_admin_activity('Import Products CSV', "Imported {$imported} products from CSV");
            set_flash('success', "Successfully imported/updated {$imported} products from CSV.");
        } else {
            set_flash('error', 'Please upload a valid CSV file.');
        }
        header('Location: ' . base_url('products.php'));
        exit;
    }
}

// Query Filters & Pagination
$search = trim((string)($_GET['q'] ?? ''));
$categoryFilter = trim((string)($_GET['category'] ?? ''));
$statusFilter = trim((string)($_GET['status'] ?? ''));
$sort = trim((string)($_GET['sort'] ?? 'newest'));

$page = max(1, (int)($_GET['page'] ?? 1));
$limit = (int)get_app_setting('pagination_limit', '20');
if ($limit < 5 || $limit > 100) $limit = 20;
$offset = ($page - 1) * $limit;

$where = ["status != 'Archived'"];
$params = [];

if ($search !== '') {
    $where[] = "(name LIKE ? OR brand LIKE ? OR barcode LIKE ? OR subcategory LIKE ? OR description LIKE ?)";
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like, $like, $like]);
}

if ($categoryFilter !== '') {
    $where[] = "category = ?";
    $params[] = $categoryFilter;
}

if ($statusFilter !== '') {
    $where[] = "status = ?";
    $params[] = $statusFilter;
}

$whereSql = implode(' AND ', $where);

// Sorting
$orderBy = match ($sort) {
    'oldest' => 'created_at ASC',
    'name_asc' => 'name ASC',
    'name_desc' => 'name DESC',
    'expiry_asc' => 'expiry_date IS NULL ASC, expiry_date ASC',
    'expiry_desc' => 'expiry_date IS NULL ASC, expiry_date DESC',
    'price_high' => 'purchase_price DESC',
    'price_low' => 'purchase_price ASC',
    default => 'created_at DESC', // newest
};

// Count total
$countStmt = $db->prepare("SELECT COUNT(*) FROM products WHERE {$whereSql}");
$countStmt->execute($params);
$totalRecords = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalRecords / $limit));

// Query rows
$querySql = "SELECT * FROM products WHERE {$whereSql} ORDER BY {$orderBy} LIMIT {$limit} OFFSET {$offset}";
$stmt = $db->prepare($querySql);
$stmt->execute($params);
$products = $stmt->fetchAll();

// Categories for filter dropdown
$catList = $db->query("SELECT name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll(PDO::FETCH_COLUMN);

$pageTitle = 'Products Catalog';
require_once __DIR__ . '/includes/header.php';
?>

<!-- Header Actions -->
<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Universal Products Catalog</h2>
    <p class="text-muted small mb-0">Manage all registered barcodes, descriptions, prices, expiration dates, and classifications.</p>
  </div>
  <div class="d-flex flex-wrap gap-2">
    <?php if (can_edit_products()): ?>
      <a href="<?= base_url('product-add.php') ?>" class="btn btn-primary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
        <span class="material-symbols-rounded fs-5">add</span>
        <span>Add Product</span>
      </a>
      <button type="button" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1" data-bs-toggle="modal" data-bs-target="#modalImportCsv">
        <span class="material-symbols-rounded fs-5">upload_file</span>
        <span>Import CSV</span>
      </button>
    <?php endif; ?>
    <a href="<?= base_url('products.php?export=csv') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-2 fw-semibold d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export CSV</span>
    </a>
  </div>
</div>

<!-- Filters Card -->
<div class="card border-0 shadow-sm rounded-4 mb-4 bg-white p-3 p-md-4">
  <form method="GET" action="" class="row g-2 align-items-end">
    <div class="col-md-4">
      <label for="q" class="form-label small fw-bold text-muted">Search Catalog</label>
      <div class="input-group">
        <span class="input-group-text bg-light border-end-0 text-muted"><span class="material-symbols-rounded fs-5">search</span></span>
        <input type="text" name="q" id="q" value="<?= e($search) ?>" class="form-control bg-light border-start-0" placeholder="Product name, brand, barcode...">
      </div>
    </div>

    <div class="col-6 col-md-3">
      <label for="category" class="form-label small fw-bold text-muted">Category</label>
      <select name="category" id="category" class="form-select bg-light">
        <option value="">All Categories</option>
        <?php foreach ($catList as $cat): ?>
          <option value="<?= e($cat) ?>" <?= $categoryFilter === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="status" class="form-label small fw-bold text-muted">Status</label>
      <select name="status" id="status" class="form-select bg-light">
        <option value="">All Statuses</option>
        <option value="Active" <?= $statusFilter === 'Active' ? 'selected' : '' ?>>Active</option>
        <option value="Inactive" <?= $statusFilter === 'Inactive' ? 'selected' : '' ?>>Inactive</option>
        <option value="Pending Review" <?= $statusFilter === 'Pending Review' ? 'selected' : '' ?>>Pending Review</option>
        <option value="Needs Review" <?= $statusFilter === 'Needs Review' ? 'selected' : '' ?>>Needs Review</option>
      </select>
    </div>

    <div class="col-6 col-md-2">
      <label for="sort" class="form-label small fw-bold text-muted">Sort By</label>
      <select name="sort" id="sort" class="form-select bg-light">
        <option value="newest" <?= $sort === 'newest' ? 'selected' : '' ?>>Newest Added</option>
        <option value="oldest" <?= $sort === 'oldest' ? 'selected' : '' ?>>Oldest Added</option>
        <option value="name_asc" <?= $sort === 'name_asc' ? 'selected' : '' ?>>Name (A-Z)</option>
        <option value="name_desc" <?= $sort === 'name_desc' ? 'selected' : '' ?>>Name (Z-A)</option>
        <option value="expiry_asc" <?= $sort === 'expiry_asc' ? 'selected' : '' ?>>Expiry (Soonest)</option>
        <option value="price_high" <?= $sort === 'price_high' ? 'selected' : '' ?>>Price (High to Low)</option>
      </select>
    </div>

    <div class="col-6 col-md-1 d-flex gap-1">
      <button type="submit" class="btn btn-primary w-100 fw-semibold" style="background-color: #10B981; border-color: #10B981;">Filter</button>
      <?php if ($search !== '' || $categoryFilter !== '' || $statusFilter !== '' || $sort !== 'newest'): ?>
        <a href="<?= base_url('products.php') ?>" class="btn btn-light border" title="Reset Filters"><span class="material-symbols-rounded fs-6">close</span></a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Products Table Form (Enables Bulk Selection) -->
<form method="POST" action="" id="formBulkActions">
  <?= csrf_field() ?>

  <!-- Bulk Action Bar -->
  <?php if (can_delete_products()): ?>
    <div class="d-none align-items-center justify-content-between bg-white p-3 rounded-4 shadow-sm mb-3 border" id="bulkActionBar">
      <div class="d-flex align-items-center gap-2">
        <span class="badge bg-primary rounded-pill px-3 py-1" id="bulkCountBadge">0 selected</span>
        <span class="text-muted small">Choose an action to apply to selected items:</span>
      </div>
      <div class="d-flex gap-2">
        <button type="submit" name="bulk_action" value="archive" class="btn btn-sm btn-outline-warning rounded-pill px-3" onclick="return confirm('Archive selected products?')">
          Archive Selected
        </button>
        <button type="submit" name="bulk_action" value="delete" class="btn btn-sm btn-outline-danger rounded-pill px-3" onclick="return confirm('Permanently delete selected products? This action cannot be undone.')">
          Delete Selected
        </button>
      </div>
    </div>
  <?php endif; ?>

  <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
    <div class="table-responsive">
      <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
        <thead class="table-light">
          <tr>
            <?php if (can_delete_products()): ?>
              <th width="40" class="text-center">
                <input type="checkbox" class="form-check-input" id="selectAll">
              </th>
            <?php endif; ?>
            <th width="70">Image</th>
            <th>Product & Brand</th>
            <th>Barcode / QR</th>
            <th>Category</th>
            <th>Stock & Unit</th>
            <th>Price</th>
            <th>Expiry Date</th>
            <th>Status</th>
            <th width="120" class="text-end">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php if (empty($products)): ?>
            <tr>
              <td colspan="10" class="text-center py-5">
                <div class="text-muted mb-2"><span class="material-symbols-rounded fs-1">inventory_2</span></div>
                <div class="fw-bold">No products found</div>
                <p class="text-muted small mb-0">Try clearing your search query or add a new product.</p>
              </td>
            </tr>
          <?php else: ?>
            <?php foreach ($products as $prod): ?>
              <tr>
                <?php if (can_delete_products()): ?>
                  <td class="text-center">
                    <input type="checkbox" name="selected_ids[]" value="<?= e($prod['id']) ?>" class="form-check-input row-checkbox">
                  </td>
                <?php endif; ?>

                <td>
                  <?php if (!empty($prod['image_path'])): ?>
                    <img src="<?= e($prod['image_path']) ?>" class="rounded-3 shadow-xs" style="width: 44px; height: 44px; object-fit: cover;" onerror="this.style.display='none'">
                  <?php else: ?>
                    <div class="bg-light rounded-3 d-flex align-items-center justify-content-center text-muted border" style="width: 44px; height: 44px;">
                      <span class="material-symbols-rounded" style="font-size: 22px;">image</span>
                    </div>
                  <?php endif; ?>
                </td>

                <td>
                  <div class="fw-bold text-dark"><?= e($prod['name']) ?></div>
                  <div class="text-muted small"><?= e($prod['brand'] ?: 'Generic Brand') ?></div>
                </td>

                <td>
                  <?php if (!empty($prod['barcode'])): ?>
                    <span class="barcode-pill"><span class="material-symbols-rounded" style="font-size: 13px;">barcode</span><?= e($prod['barcode']) ?></span>
                  <?php else: ?>
                    <span class="text-muted small">—</span>
                  <?php endif; ?>
                </td>

                <td>
                  <span class="badge bg-light text-dark rounded-pill border px-2.5 py-1"><?= e($prod['category']) ?></span>
                  <?php if (!empty($prod['subcategory'])): ?>
                    <div class="text-muted" style="font-size: 11px; margin-top: 2px;"><?= e($prod['subcategory']) ?></div>
                  <?php endif; ?>
                </td>

                <td>
                  <div class="fw-semibold"><?= (float)$prod['quantity'] ?> <?= e($prod['unit']) ?></div>
                  <div class="text-muted" style="font-size: 11px;"><?= e(ucfirst($prod['storage_location'] ?? 'pantry')) ?></div>
                </td>

                <td class="fw-bold">
                  <?= e($prod['currency'] ?? '₹') ?><?= number_format((float)($prod['purchase_price'] ?? 0), 2) ?>
                </td>

                <td>
                  <?php if (!empty($prod['expiry_date'])): 
                    $exp = new DateTime($prod['expiry_date']);
                    $today = new DateTime('today');
                    $diff = (int)$today->diff($exp)->format('%r%a');
                  ?>
                    <div class="fw-semibold"><?= format_date($prod['expiry_date']) ?></div>
                    <?php if ($diff < 0): ?>
                      <span class="badge-status expired">Expired (<?= abs($diff) ?>d ago)</span>
                    <?php elseif ($diff <= 7): ?>
                      <span class="badge-status expiring-soon"><?= $diff === 0 ? 'Expires Today' : "{$diff}d left" ?></span>
                    <?php else: ?>
                      <span class="badge-status safe">Safe (<?= $diff ?>d)</span>
                    <?php endif; ?>
                  <?php else: ?>
                    <span class="badge-status no-expiry">No Expiry Date</span>
                  <?php endif; ?>
                </td>

                <td>
                  <span class="badge-status <?= strtolower(str_replace(' ', '-', $prod['status'])) ?>">
                    <?= e($prod['status']) ?>
                  </span>
                </td>

                <td class="text-end">
                  <div class="d-inline-flex gap-1">
                    <a href="<?= base_url('product-view.php?id=' . urlencode($prod['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="View Details">
                      <span class="material-symbols-rounded" style="font-size: 16px;">visibility</span>
                    </a>
                    <?php if (can_edit_products()): ?>
                      <a href="<?= base_url('product-edit.php?id=' . urlencode($prod['id'])) ?>" class="btn btn-sm btn-light border py-1 px-2 rounded-2" title="Edit Product">
                        <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                      </a>
                    <?php endif; ?>
                    <?php if (can_delete_products()): ?>
                      <a href="<?= base_url('product-delete.php?id=' . urlencode($prod['id']) . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border text-danger py-1 px-2 rounded-2" title="Delete Product" onclick="return confirm('Are you sure you want to delete <?= addslashes(htmlspecialchars($prod['name'])) ?>?');">
                        <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                      </a>
                    <?php endif; ?>
                  </div>
                </td>
              </tr>
            <?php endforeach; ?>
          <?php endif; ?>
        </tbody>
      </table>
    </div>

    <!-- Pagination Footer -->
    <?php if ($totalPages > 1): ?>
      <div class="p-3 border-top d-flex flex-column flex-sm-row justify-content-between align-items-center gap-2">
        <div class="text-muted small">
          Showing <strong><?= min($totalRecords, $offset + 1) ?></strong> to <strong><?= min($totalRecords, $offset + $limit) ?></strong> of <strong><?= number_format($totalRecords) ?></strong> products
        </div>
        <nav>
          <ul class="pagination pagination-sm mb-0">
            <li class="page-item <?= $page <= 1 ? 'disabled' : '' ?>">
              <a class="page-link" href="<?= base_url('products.php?' . http_build_query(array_merge($_GET, ['page' => $page - 1]))) ?>">Previous</a>
            </li>
            <?php for ($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++): ?>
              <li class="page-item <?= $i === $page ? 'active' : '' ?>">
                <a class="page-link" href="<?= base_url('products.php?' . http_build_query(array_merge($_GET, ['page' => $i]))) ?>"><?= $i ?></a>
              </li>
            <?php endfor; ?>
            <li class="page-item <?= $page >= $totalPages ? 'disabled' : '' ?>">
              <a class="page-link" href="<?= base_url('products.php?' . http_build_query(array_merge($_GET, ['page' => $page + 1]))) ?>">Next</a>
            </li>
          </ul>
        </nav>
      </div>
    <?php endif; ?>
  </div>
</form>

<!-- Modal: Import CSV -->
<div class="modal fade" id="modalImportCsv" tabindex="-1" aria-labelledby="modalImportCsvLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content rounded-4 border-0 shadow">
      <div class="modal-header border-bottom">
        <h5 class="modal-title fw-bold" id="modalImportCsvLabel">Import Products from CSV</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <form method="POST" action="" enctype="multipart/form-data">
        <?= csrf_field() ?>
        <div class="modal-body p-4">
          <p class="text-muted small">Upload a standard CSV file to bulk import or update products in your catalog.</p>
          <div class="mb-3">
            <label for="csv_file" class="form-label fw-semibold small">Choose CSV File</label>
            <input type="file" name="csv_file" id="csv_file" class="form-control" accept=".csv" required>
          </div>
          <div class="alert alert-light border small text-muted mb-0">
            <strong>Expected Columns:</strong> ID, Barcode, Name, Brand, Category, Subcategory, Quantity, Unit, Price, Currency, Mfg Date, Expiry Date, Status
          </div>
        </div>
        <div class="modal-footer border-top">
          <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Upload & Import</button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- Bulk Selection Script -->
<script>
document.addEventListener('DOMContentLoaded', function () {
  const selectAll = document.getElementById('selectAll');
  const checkboxes = document.querySelectorAll('.row-checkbox');
  const bulkBar = document.getElementById('bulkActionBar');
  const bulkBadge = document.getElementById('bulkCountBadge');

  function updateBulkBar() {
    const checked = document.querySelectorAll('.row-checkbox:checked');
    if (checked.length > 0) {
      bulkBar.classList.remove('d-none');
      bulkBar.classList.add('d-flex');
      bulkBadge.textContent = checked.length + ' selected';
    } else {
      bulkBar.classList.add('d-none');
      bulkBar.classList.remove('d-flex');
    }
  }

  if (selectAll) {
    selectAll.addEventListener('change', function () {
      checkboxes.forEach(cb => cb.checked = selectAll.checked);
      updateBulkBar();
    });
  }

  checkboxes.forEach(cb => {
    cb.addEventListener('change', function () {
      updateBulkBar();
      if (selectAll && !this.checked) selectAll.checked = false;
    });
  });
});
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
