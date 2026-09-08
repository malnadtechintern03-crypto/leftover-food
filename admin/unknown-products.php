<?php
/**
 * ScanSmart Unknown Products Triage Queue
 * Approve unrecognized barcode scans to expand universal catalog
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

// Handle Approval / Catalog Promotion
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action']) && $_POST['action'] === 'approve_product') {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } elseif (!can_edit_products()) {
        set_flash('error', 'Permission denied.');
    } else {
        $unknownId = (int)($_POST['unknown_id'] ?? 0);
        $barcode = trim($_POST['barcode'] ?? '');
        $name = trim($_POST['product_name'] ?? '');
        $brand = trim($_POST['brand'] ?? '');
        $category = trim($_POST['category'] ?? 'Other');
        $subcategory = trim($_POST['subcategory'] ?? '');
        $price = trim($_POST['purchase_price'] ?? '');
        $unit = trim($_POST['unit'] ?? 'pieces');

        if ($name === '' || $barcode === '') {
            set_flash('error', 'Product name and barcode are required for catalog approval.');
        } else {
            // Handle uploaded image if present
            $imagePath = null;
            if (!empty($_FILES['image_file']['name'])) {
                $uploadResult = upload_product_image($_FILES['image_file']);
                if ($uploadResult['success']) {
                    $imagePath = $uploadResult['url'];
                }
            } elseif (!empty($_POST['image_url'])) {
                $imagePath = trim($_POST['image_url']);
            }

            // Check if product with this barcode already exists in products table
            $check = $db->prepare('SELECT id FROM products WHERE barcode = ? LIMIT 1');
            $check->execute([$barcode]);
            $existing = $check->fetch();

            $priceVal = $price !== '' && is_numeric($price) ? (float)$price : null;

            if ($existing) {
                // Update existing
                $upd = $db->prepare("UPDATE products SET name = ?, brand = ?, category = ?, subcategory = ?, image_path = COALESCE(?, image_path), status = 'Active', review_status = 'Approved' WHERE id = ?");
                $upd->execute([$name, $brand ?: null, $category, $subcategory ?: null, $imagePath, $existing['id']]);
            } else {
                // Insert into products
                $newId = 'prod-' . bin2hex(random_bytes(10));
                $ins = $db->prepare("
                    INSERT INTO products (id, barcode, name, brand, category, subcategory, unit, purchase_price, image_path, source, status, review_status)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Barcode Scanner', 'Active', 'Approved')
                ");
                $ins->execute([$newId, $barcode, $name, $brand ?: null, $category, $subcategory ?: null, $unit, $priceVal, $imagePath]);
            }

            // Update unknown_products review status
            $db->prepare("UPDATE unknown_products SET review_status = 'Approved', product_name = ?, admin_notes = 'Approved and added to master catalog' WHERE id = ?")->execute([$name, $unknownId]);

            log_admin_activity('Approve Unknown Product', "Approved barcode '{$barcode}' as '{$name}' into universal catalog");
            set_flash('success', "Product '{$name}' approved and added to catalog. It is now searchable by barcode!");
        }
    }
    header('Location: ' . base_url('unknown-products.php'));
    exit;
}

// Handle Rejection
if (isset($_GET['reject']) && can_edit_products()) {
    if (!verify_csrf()) {
        set_flash('error', 'Security token expired.');
    } else {
        $uId = (int)$_GET['reject'];
        $db->prepare("UPDATE unknown_products SET review_status = 'Rejected' WHERE id = ?")->execute([$uId]);
        log_admin_activity('Reject Unknown Product', "Rejected unknown product submission #{$uId}");
        set_flash('success', 'Product submission marked as rejected.');
    }
    header('Location: ' . base_url('unknown-products.php'));
    exit;
}

// Filter
$statusFilter = trim((string)($_GET['status'] ?? 'Pending Review'));
$where = [];
$params = [];

if ($statusFilter !== 'all') {
    $where[] = "review_status = ?";
    $params[] = $statusFilter;
}

$whereSql = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';

$stmt = $db->prepare("SELECT * FROM unknown_products {$whereSql} ORDER BY created_at DESC");
$stmt->execute($params);
$items = $stmt->fetchAll();

$categories = $db->query("SELECT name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll(PDO::FETCH_COLUMN);

$countPending = (int)$db->query("SELECT COUNT(*) FROM unknown_products WHERE review_status = 'Pending Review'")->fetchColumn();
$countApproved = (int)$db->query("SELECT COUNT(*) FROM unknown_products WHERE review_status = 'Approved'")->fetchColumn();
$countRejected = (int)$db->query("SELECT COUNT(*) FROM unknown_products WHERE review_status = 'Rejected'")->fetchColumn();

$pageTitle = 'Unknown Products Triage';
require_once __DIR__ . '/includes/header.php';
?>

<div class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3 mb-4">
  <div>
    <h2 class="h4 fw-bold mb-1">Unknown Products Review Queue</h2>
    <p class="text-muted small mb-0">When users scan barcodes or OCR text not yet in the catalog, review and promote them to master inventory.</p>
  </div>
</div>

<!-- Tabs -->
<div class="d-flex flex-wrap gap-2 mb-4">
  <a href="<?= base_url('unknown-products.php?status=Pending+Review') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'Pending Review' ? 'btn-warning text-dark' : 'btn-light border text-warning' ?>">
    Pending Review (<?= $countPending ?>)
  </a>
  <a href="<?= base_url('unknown-products.php?status=Approved') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'Approved' ? 'btn-success text-white' : 'btn-light border text-success' ?>">
    Approved (<?= $countApproved ?>)
  </a>
  <a href="<?= base_url('unknown-products.php?status=Rejected') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'Rejected' ? 'btn-danger text-white' : 'btn-light border text-danger' ?>">
    Rejected (<?= $countRejected ?>)
  </a>
  <a href="<?= base_url('unknown-products.php?status=all') ?>" class="btn btn-sm rounded-pill px-3 py-1.5 fw-semibold <?= $statusFilter === 'all' ? 'btn-dark' : 'btn-light border text-dark' ?>">
    All Submissions
  </a>
</div>

<!-- Items Table -->
<div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0" style="font-size: 13.5px;">
      <thead class="table-light">
        <tr>
          <th>Barcode</th>
          <th>Suggested Title / OCR Text</th>
          <th>Scan Mode</th>
          <th>User</th>
          <th>Submitted Date</th>
          <th>Status</th>
          <th width="140" class="text-end">Triage Action</th>
        </tr>
      </thead>
      <tbody>
        <?php if (empty($items)): ?>
          <tr><td colspan="7" class="text-center py-5 text-muted">No unknown product submissions in this queue.</td></tr>
        <?php else: ?>
          <?php foreach ($items as $item): ?>
            <tr>
              <td><span class="barcode-pill"><?= e($item['barcode']) ?></span></td>
              <td>
                <div class="fw-bold text-dark"><?= e($item['product_name'] ?: 'Unlabeled Scanned Item') ?></div>
                <?php if (!empty($item['ocr_text'])): ?>
                  <div class="text-muted small text-truncate" style="max-width: 260px;" title="<?= e($item['ocr_text']) ?>">
                    OCR: <?= e($item['ocr_text']) ?>
                  </div>
                <?php endif; ?>
              </td>
              <td><span class="badge bg-light text-dark rounded-pill border"><?= e($item['scan_type']) ?></span></td>
              <td><code><?= e($item['user_id']) ?></code></td>
              <td class="text-muted"><?= format_date($item['created_at'], 'M d, Y H:i') ?></td>
              <td>
                <span class="badge-status <?= strtolower(str_replace(' ', '-', $item['review_status'])) ?>">
                  <?= e($item['review_status']) ?>
                </span>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <?php if ($item['review_status'] === 'Pending Review' && can_edit_products()): ?>
                    <button type="button" class="btn btn-sm btn-primary rounded-pill px-2.5 py-1 small d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;" data-bs-toggle="modal" data-bs-target="#modalApprove<?= $item['id'] ?>">
                      <span class="material-symbols-rounded" style="font-size: 15px;">check</span>
                      <span>Catalog</span>
                    </button>
                    <a href="<?= base_url('unknown-products.php?reject=' . (int)$item['id'] . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-sm btn-light border text-danger py-1 px-2 rounded-pill" title="Reject Submission" onclick="return confirm('Reject this unknown product?');">
                      <span class="material-symbols-rounded" style="font-size: 15px;">close</span>
                    </a>
                  <?php else: ?>
                    <span class="text-muted small">Processed</span>
                  <?php endif; ?>
                </div>
              </td>
            </tr>

            <!-- Modal: Approve & Catalog -->
            <div class="modal fade" id="modalApprove<?= $item['id'] ?>" tabindex="-1" aria-hidden="true">
              <div class="modal-dialog modal-dialog-centered modal-lg">
                <div class="modal-content rounded-4 border-0 shadow">
                  <div class="modal-header border-bottom">
                    <h5 class="modal-title fw-bold">Approve Barcode & Add to Catalog</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                  </div>
                  <form method="POST" action="" enctype="multipart/form-data">
                    <?= csrf_field() ?>
                    <input type="hidden" name="action" value="approve_product">
                    <input type="hidden" name="unknown_id" value="<?= $item['id'] ?>">
                    <input type="hidden" name="barcode" value="<?= e($item['barcode']) ?>">

                    <div class="modal-body p-4">
                      <div class="alert alert-info py-2 px-3 small rounded-3 mb-3">
                        Approving this item will insert it directly into the universal catalog so that future scans of barcode <strong><?= e($item['barcode']) ?></strong> will be instantly recognized by the mobile app.
                      </div>

                      <div class="row g-3">
                        <div class="col-md-8">
                          <label class="form-label small fw-bold">Product Name <span class="text-danger">*</span></label>
                          <input type="text" name="product_name" class="form-control" value="<?= e($item['product_name'] ?: '') ?>" placeholder="e.g. Tomato Ketchup 500g" required>
                        </div>
                        <div class="col-md-4">
                          <label class="form-label small fw-bold">Brand</label>
                          <input type="text" name="brand" class="form-control" placeholder="e.g. Heinz">
                        </div>
                        <div class="col-md-6">
                          <label class="form-label small fw-bold">Primary Category <span class="text-danger">*</span></label>
                          <select name="category" class="form-select" required>
                            <?php foreach ($categories as $c): ?>
                              <option value="<?= e($c) ?>"><?= e($c) ?></option>
                            <?php endforeach; ?>
                          </select>
                        </div>
                        <div class="col-md-6">
                          <label class="form-label small fw-bold">Subcategory</label>
                          <input type="text" name="subcategory" class="form-control" placeholder="e.g. Condiments">
                        </div>
                        <div class="col-md-6">
                          <label class="form-label small fw-bold">Approx Price</label>
                          <input type="number" step="0.01" name="purchase_price" class="form-control" placeholder="120.00">
                        </div>
                        <div class="col-md-6">
                          <label class="form-label small fw-bold">Unit</label>
                          <input type="text" name="unit" class="form-control" value="pieces">
                        </div>
                        <div class="col-12">
                          <label class="form-label small fw-bold">Product Image (Upload File)</label>
                          <input type="file" name="image_file" class="form-control" accept="image/jpeg,image/png,image/webp">
                        </div>
                      </div>
                    </div>
                    <div class="modal-footer border-top">
                      <button type="button" class="btn btn-light rounded-pill px-4" data-bs-dismiss="modal">Cancel</button>
                      <button type="submit" class="btn btn-primary rounded-pill px-4" style="background-color: #10B981; border-color: #10B981;">Approve & Catalog</button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
