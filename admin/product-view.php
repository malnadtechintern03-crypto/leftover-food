<?php
/**
 * ScanSmart Product Management - View Product Details
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_admin();

$db = Database::getConnection();

$id = trim((string)($_GET['id'] ?? ''));
if ($id === '') {
    set_flash('error', 'Product ID is required.');
    header('Location: ' . base_url('products.php'));
    exit;
}

$stmt = $db->prepare('SELECT * FROM products WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$product = $stmt->fetch();

if (!$product) {
    set_flash('error', 'Product record not found.');
    header('Location: ' . base_url('products.php'));
    exit;
}

// Fetch active reminders for this product
$remStmt = $db->prepare('SELECT * FROM product_reminders WHERE product_id = ? ORDER BY reminder_date ASC');
$remStmt->execute([$id]);
$reminders = $remStmt->fetchAll();

// Fetch inventory stock entries across users
$invStmt = $db->prepare('SELECT * FROM inventory WHERE product_id = ? ORDER BY created_at DESC');
$invStmt->execute([$id]);
$inventory = $invStmt->fetchAll();

$pageTitle = $product['name'] . ' — Product Details';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-4xl mx-auto mb-5">
  <div class="d-flex flex-column flex-sm-row justify-content-between align-items-start align-items-sm-center gap-3 mb-4">
    <div>
      <div class="d-flex align-items-center gap-2 mb-1">
        <h2 class="h4 fw-bold mb-0"><?= e($product['name']) ?></h2>
        <span class="badge-status <?= strtolower(str_replace(' ', '-', $product['status'])) ?>"><?= e($product['status']) ?></span>
      </div>
      <div class="text-muted small">Brand: <strong><?= e($product['brand'] ?: 'Generic') ?></strong> &bull; Catalog ID: <code><?= e($product['id']) ?></code></div>
    </div>
    <div class="d-flex gap-2">
      <?php if (can_edit_products()): ?>
        <a href="<?= base_url('product-edit.php?id=' . urlencode($product['id'])) ?>" class="btn btn-primary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1" style="background-color: #10B981; border-color: #10B981;">
          <span class="material-symbols-rounded fs-6">edit</span>
          <span>Edit Product</span>
        </a>
      <?php endif; ?>
      <?php if (can_delete_products()): ?>
        <a href="<?= base_url('product-delete.php?id=' . urlencode($product['id']) . '&csrf_token=' . e(csrf_token())) ?>" class="btn btn-outline-danger rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1" onclick="return confirm('Delete this product?');">
          <span class="material-symbols-rounded fs-6">delete</span>
          <span>Delete</span>
        </a>
      <?php endif; ?>
      <a href="<?= base_url('products.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">arrow_back</span>
        <span>Back</span>
      </a>
    </div>
  </div>

  <div class="row g-4">
    <!-- Left Column -->
    <div class="col-lg-8">
      <!-- Core Info Card -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <div class="d-flex flex-column flex-sm-row gap-4 mb-4">
          <!-- Product Image -->
          <div class="text-center">
            <?php if (!empty($product['image_path'])): ?>
              <img src="<?= e($product['image_path']) ?>" class="img-fluid rounded-4 border shadow-sm" style="width: 140px; height: 140px; object-fit: cover;">
            <?php else: ?>
              <div class="bg-light rounded-4 border d-flex align-items-center justify-content-center text-muted" style="width: 140px; height: 140px;">
                <span class="material-symbols-rounded" style="font-size: 48px;">image</span>
              </div>
            <?php endif; ?>
          </div>

          <!-- Quick Metadata -->
          <div class="flex-grow-1">
            <span class="badge bg-light text-dark rounded-pill border px-3 py-1 fw-bold mb-2"><?= e($product['category']) ?></span>
            <?php if (!empty($product['subcategory'])): ?>
              <span class="badge bg-secondary-subtle text-secondary rounded-pill px-3 py-1 ms-1"><?= e($product['subcategory']) ?></span>
            <?php endif; ?>

            <div class="d-flex flex-wrap gap-3 mt-3">
              <div>
                <div class="text-muted" style="font-size: 11px;">BARCODE</div>
                <div class="fw-bold"><?= !empty($product['barcode']) ? '<span class="barcode-pill">' . e($product['barcode']) . '</span>' : 'None' ?></div>
              </div>

              <div>
                <div class="text-muted" style="font-size: 11px;">PRICE</div>
                <div class="fw-bold fs-5 text-dark"><?= e($product['currency'] ?? '₹') ?><?= number_format((float)($product['purchase_price'] ?? 0), 2) ?></div>
              </div>

              <div>
                <div class="text-muted" style="font-size: 11px;">STOCK LEVEL</div>
                <div class="fw-bold fs-5 text-success"><?= (float)$product['quantity'] ?> <?= e($product['unit']) ?></div>
              </div>
            </div>

            <?php if (!empty($product['description'])): ?>
              <p class="text-muted small mt-3 mb-0"><?= nl2br(e($product['description'])) ?></p>
            <?php endif; ?>
          </div>
        </div>

        <hr>

        <!-- Specifications Grid -->
        <h6 class="fw-bold text-dark mb-3">Specifications & Metadata</h6>
        <div class="row g-3" style="font-size: 13.5px;">
          <div class="col-sm-6">
            <span class="text-muted d-block small">Manufacturer:</span>
            <strong><?= e($product['manufacturer'] ?: 'Not Specified') ?></strong>
          </div>
          <div class="col-sm-6">
            <span class="text-muted d-block small">Country of Origin:</span>
            <strong><?= e($product['country_of_origin'] ?: 'Not Specified') ?></strong>
          </div>
          <div class="col-sm-6">
            <span class="text-muted d-block small">Storage Location:</span>
            <strong><?= e(ucfirst($product['storage_location'] ?? 'pantry')) ?></strong>
          </div>
          <div class="col-sm-6">
            <span class="text-muted d-block small">Warranty:</span>
            <strong><?= e($product['warranty_information'] ?: 'None') ?></strong>
          </div>
          <div class="col-sm-6">
            <span class="text-muted d-block small">Manufacturing Date:</span>
            <strong><?= format_date($product['manufacturing_date']) ?></strong>
          </div>
          <div class="col-sm-6">
            <span class="text-muted d-block small">Expiration Date:</span>
            <strong class="<?= !empty($product['expiry_date']) ? 'text-danger' : '' ?>"><?= format_date($product['expiry_date']) ?></strong>
          </div>
          <?php if (!empty($product['product_url'])): ?>
            <div class="col-12">
              <span class="text-muted d-block small">Product Website:</span>
              <a href="<?= e($product['product_url']) ?>" target="_blank" class="text-primary text-break"><?= e($product['product_url']) ?></a>
            </div>
          <?php endif; ?>
          <?php if (!empty($product['ingredients'])): ?>
            <div class="col-12">
              <span class="text-muted d-block small">Ingredients:</span>
              <p class="mb-0 text-dark"><?= nl2br(e($product['ingredients'])) ?></p>
            </div>
          <?php endif; ?>
          <?php if (!empty($product['usage_instructions'])): ?>
            <div class="col-12">
              <span class="text-muted d-block small">Usage & Storage Instructions:</span>
              <p class="mb-0 text-dark"><?= nl2br(e($product['usage_instructions'])) ?></p>
            </div>
          <?php endif; ?>
        </div>
      </div>

      <!-- Inventory Records -->
      <div class="card border-0 shadow-sm rounded-4 bg-white overflow-hidden mb-4">
        <div class="p-3 px-4 border-bottom">
          <h6 class="fw-bold mb-0">Active Stock across Users</h6>
        </div>
        <div class="table-responsive">
          <table class="table table-hover align-middle mb-0" style="font-size: 13px;">
            <thead class="table-light">
              <tr>
                <th>User</th>
                <th>Quantity</th>
                <th>Location</th>
                <th>Status</th>
                <th>Date Added</th>
              </tr>
            </thead>
            <tbody>
              <?php if (empty($inventory)): ?>
                <tr>
                  <td colspan="5" class="text-center py-3 text-muted">No individual inventory stock records mapped yet.</td>
                </tr>
              <?php else: ?>
                <?php foreach ($inventory as $inv): ?>
                  <tr>
                    <td><strong><?= e($inv['user_id']) ?></strong></td>
                    <td><?= (float)$inv['quantity'] ?> <?= e($inv['unit']) ?></td>
                    <td><span class="badge bg-light text-dark rounded-pill"><?= e($inv['storage_location']) ?></span></td>
                    <td><span class="badge bg-success-subtle text-success rounded-pill"><?= e($inv['status']) ?></span></td>
                    <td class="text-muted"><?= format_date($inv['created_at']) ?></td>
                  </tr>
                <?php endforeach; ?>
              <?php endif; ?>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Right Column: Expiry & Audit -->
    <div class="col-lg-4">
      <!-- Expiry Status Badge Card -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <h6 class="fw-bold mb-3 d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-warning">timer</span>
          <span>Expiration & Reminders</span>
        </h6>

        <div class="p-3 rounded-3 mb-3 text-center" style="background: #F8FAFC; border: 1px solid #E2E8F0;">
          <div class="text-muted small">Current Expiry Status:</div>
          <div class="mt-1">
            <span class="badge-status <?= strtolower(str_replace(' ', '-', $product['expiry_status'])) ?> fs-6 px-3 py-1">
              <?= e($product['expiry_status']) ?>
            </span>
          </div>
          <?php if (!empty($product['expiry_date'])): 
            $expDt = new DateTime($product['expiry_date']);
            $today = new DateTime('today');
            $diff = (int)$today->diff($expDt)->format('%r%a');
          ?>
            <div class="small mt-2 fw-semibold <?= $diff < 0 ? 'text-danger' : ($diff <= 7 ? 'text-warning' : 'text-success') ?>">
              <?= $diff < 0 ? abs($diff) . ' days overdue' : ($diff === 0 ? 'Expires today!' : "{$diff} days remaining") ?>
            </div>
          <?php endif; ?>
        </div>

        <div class="small">
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Reminder Enabled:</span>
            <strong><?= (int)$product['reminder_enabled'] === 1 ? 'Yes (Active)' : 'Disabled' ?></strong>
          </div>
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Days Prior:</span>
            <strong><?= e($product['reminder_days_before']) ?> days</strong>
          </div>
          <div class="d-flex justify-content-between py-1">
            <span class="text-muted">Scheduled For:</span>
            <strong><?= format_date($product['reminder_date'], 'M d, Y H:i') ?></strong>
          </div>
        </div>
      </div>

      <!-- Classification & Audit -->
      <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
        <h6 class="fw-bold mb-3 d-flex align-items-center gap-2">
          <span class="material-symbols-rounded text-secondary">psychology</span>
          <span>Classification & Source</span>
        </h6>

        <div class="small">
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Origin Source:</span>
            <strong><?= e($product['source']) ?></strong>
          </div>
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Category Confidence:</span>
            <strong class="text-success"><?= (int)$product['category_confidence'] ?>%</strong>
          </div>
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Review Status:</span>
            <span class="badge-status <?= strtolower(str_replace(' ', '-', $product['review_status'])) ?>"><?= e($product['review_status']) ?></span>
          </div>
          <div class="d-flex justify-content-between py-1 border-bottom">
            <span class="text-muted">Created:</span>
            <span><?= format_date($product['created_at'], 'M d, Y H:i') ?></span>
          </div>
          <div class="d-flex justify-content-between py-1">
            <span class="text-muted">Last Modified:</span>
            <span><?= format_date($product['updated_at'], 'M d, Y H:i') ?></span>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
