<?php
/**
 * ScanSmart Product Management - Edit Existing Product
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin', 'editor');

$db = Database::getConnection();

$id = trim((string)($_GET['id'] ?? ''));
if ($id === '') {
    set_flash('error', 'Product ID is missing.');
    header('Location: ' . base_url('products.php'));
    exit;
}

$stmt = $db->prepare('SELECT * FROM products WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$product = $stmt->fetch();

if (!$product) {
    set_flash('error', 'Product not found.');
    header('Location: ' . base_url('products.php'));
    exit;
}

$categories = $db->query("SELECT id, name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll();
$subcategories = $db->query("SELECT id, category_id, name FROM subcategories WHERE status = 'active' ORDER BY name ASC")->fetchAll();

$errors = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security token expired. Please resubmit.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $brand = trim($_POST['brand'] ?? '');
        $barcode = trim($_POST['barcode'] ?? '');
        $qrCode = trim($_POST['qr_code'] ?? '');
        $category = trim($_POST['category'] ?? 'Other');
        $subcategory = trim($_POST['subcategory'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $quantity = max(0.01, (float)($_POST['quantity'] ?? 1.0));
        $unit = trim($_POST['unit'] ?? 'pieces');
        $price = trim($_POST['price'] ?? '');
        $currency = trim($_POST['currency'] ?? '₹');
        $mfgDate = trim($_POST['manufacturing_date'] ?? '');
        $expiryDate = trim($_POST['expiry_date'] ?? '');
        $reminderEnabled = isset($_POST['reminder_enabled']) ? 1 : 0;
        $reminderDays = trim($_POST['reminder_days_before'] ?? '7');
        $storageLocation = trim($_POST['storage_location'] ?? 'pantry');
        $manufacturer = trim($_POST['manufacturer'] ?? '');
        $origin = trim($_POST['country_of_origin'] ?? '');
        $ingredients = trim($_POST['ingredients'] ?? '');
        $instructions = trim($_POST['usage_instructions'] ?? '');
        $warranty = trim($_POST['warranty_information'] ?? '');
        $website = trim($_POST['product_url'] ?? '');
        $source = trim($_POST['source'] ?? 'Manual Entry');
        $confidence = max(0, min(100, (int)($_POST['category_confidence'] ?? 100)));
        $status = trim($_POST['status'] ?? 'Active');
        $reviewStatus = trim($_POST['review_status'] ?? 'Approved');

        if ($name === '') {
            $errors[] = 'Product name is required.';
        }

        // Check barcode uniqueness against OTHER products
        if ($barcode !== '') {
            $checkStmt = $db->prepare('SELECT id FROM products WHERE barcode = ? AND id != ? LIMIT 1');
            $checkStmt->execute([$barcode, $id]);
            if ($checkStmt->fetch()) {
                $errors[] = "Barcode '{$barcode}' is already in use by another product.";
            }
        }

        // Handle Image Upload or replacement
        $imagePath = $product['image_path'];
        if (!empty($_FILES['image_file']['name'])) {
            $uploadResult = upload_product_image($_FILES['image_file']);
            if ($uploadResult['success']) {
                $imagePath = $uploadResult['url'];
            } else {
                $errors[] = $uploadResult['error'];
            }
        } elseif (isset($_POST['remove_image']) && $_POST['remove_image'] === '1') {
            $imagePath = null;
        } elseif (!empty($_POST['image_url'])) {
            $imagePath = trim($_POST['image_url']);
        }

        if (empty($errors)) {
            $mfg = $mfgDate !== '' ? $mfgDate : null;
            $exp = $expiryDate !== '' ? $expiryDate : null;
            $priceVal = $price !== '' && is_numeric($price) ? (float)$price : null;

            // Calculate expiry status
            $expiryStatus = 'No Expiry Date';
            if ($exp !== null) {
                $today = new DateTime('today');
                $expDt = new DateTime($exp);
                $diff = (int)$today->diff($expDt)->format('%r%a');
                if ($diff < 0) {
                    $expiryStatus = 'Expired';
                } elseif ($diff <= 7) {
                    $expiryStatus = 'Expiring Soon';
                } else {
                    $expiryStatus = 'Safe';
                }
            }

            // Calculate reminder date
            $reminderDate = null;
            if ($exp !== null && $reminderEnabled) {
                $days = (int)$reminderDays;
                $remDt = new DateTime($exp);
                $remDt->modify("-{$days} days");
                $reminderDate = $remDt->format('Y-m-d 09:00:00');
            }

            $updateStmt = $db->prepare("
                UPDATE products SET
                    name = ?, brand = ?, barcode = ?, qr_code = ?, image_path = ?, category = ?,
                    subcategory = ?, description = ?, quantity = ?, unit = ?, purchase_price = ?,
                    currency = ?, manufacturing_date = ?, expiry_date = ?, reminder_date = ?,
                    reminder_enabled = ?, reminder_days_before = ?, expiry_status = ?, storage_location = ?,
                    manufacturer = ?, country_of_origin = ?, ingredients = ?, usage_instructions = ?,
                    warranty_information = ?, product_url = ?, source = ?, category_confidence = ?,
                    review_status = ?, status = ?
                WHERE id = ?
            ");

            $updateStmt->execute([
                $name, $brand ?: null, $barcode ?: null, $qrCode ?: null, $imagePath, $category,
                $subcategory ?: null, $description ?: null, $quantity, $unit, $priceVal,
                $currency, $mfg, $exp, $reminderDate,
                $reminderEnabled, $reminderDays, $expiryStatus, $storageLocation,
                $manufacturer ?: null, $origin ?: null, $ingredients ?: null, $instructions ?: null,
                $warranty ?: null, $website ?: null, $source, $confidence,
                $reviewStatus, $status, $id
            ]);

            // Synchronize product_reminders table
            if ($exp !== null && $reminderEnabled && $reminderDate !== null) {
                $notifId = abs(crc32($id));
                $remStmt = $db->prepare("
                    INSERT INTO product_reminders (user_id, product_id, reminder_date, days_before_expiry, notification_id, is_enabled)
                    VALUES ('default_user', ?, ?, ?, ?, 1)
                    ON DUPLICATE KEY UPDATE reminder_date = VALUES(reminder_date), days_before_expiry = VALUES(days_before_expiry), is_enabled = 1
                ");
                $remStmt->execute([$id, $reminderDate, (int)$reminderDays, $notifId]);
            } else {
                $db->prepare("UPDATE product_reminders SET is_enabled = 0 WHERE product_id = ?")->execute([$id]);
            }

            log_admin_activity('Edit Product', "Updated specifications for '{$name}' (ID: {$id})");
            set_flash('success', "Product '{$name}' was successfully updated.");
            header('Location: ' . base_url('products.php'));
            exit;
        }
    }
} else {
    // Fill from database
    $name = $product['name'];
    $brand = $product['brand'] ?? '';
    $barcode = $product['barcode'] ?? '';
    $qrCode = $product['qr_code'] ?? '';
    $category = $product['category'];
    $subcategory = $product['subcategory'] ?? '';
    $description = $product['description'] ?? '';
    $quantity = (float)$product['quantity'];
    $unit = $product['unit'] ?? 'pieces';
    $price = $product['purchase_price'] !== null ? (string)$product['purchase_price'] : '';
    $currency = $product['currency'] ?? '₹';
    $mfgDate = $product['manufacturing_date'] ?? '';
    $expiryDate = $product['expiry_date'] ?? '';
    $reminderEnabled = (int)($product['reminder_enabled'] ?? 1);
    $reminderDays = (string)($product['reminder_days_before'] ?? '7');
    $storageLocation = $product['storage_location'] ?? 'pantry';
    $manufacturer = $product['manufacturer'] ?? '';
    $origin = $product['country_of_origin'] ?? '';
    $ingredients = $product['ingredients'] ?? '';
    $instructions = $product['usage_instructions'] ?? '';
    $warranty = $product['warranty_information'] ?? '';
    $website = $product['product_url'] ?? '';
    $source = $product['source'] ?? 'Manual Entry';
    $confidence = (int)($product['category_confidence'] ?? 100);
    $status = $product['status'] ?? 'Active';
    $reviewStatus = $product['review_status'] ?? 'Approved';
}

$pageTitle = 'Edit Product — ' . $product['name'];
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-4xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h2 class="h4 fw-bold mb-1">Edit Product: <?= e($product['name']) ?></h2>
      <div class="text-muted small">Product ID: <code class="text-dark"><?= e($product['id']) ?></code></div>
    </div>
    <div class="d-flex gap-2">
      <a href="<?= base_url('product-view.php?id=' . urlencode($product['id'])) ?>" class="btn btn-outline-primary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">visibility</span>
        <span>View Details</span>
      </a>
      <a href="<?= base_url('products.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
        <span class="material-symbols-rounded fs-6">arrow_back</span>
        <span>Back to Products</span>
      </a>
    </div>
  </div>

  <?php if (!empty($errors)): ?>
    <div class="alert alert-danger rounded-4 mb-4">
      <div class="fw-bold mb-1">Please correct the following errors:</div>
      <ul class="mb-0 ps-3">
        <?php foreach ($errors as $err): ?>
          <li><?= e($err) ?></li>
        <?php endforeach; ?>
      </ul>
    </div>
  <?php endif; ?>

  <form method="POST" action="" enctype="multipart/form-data">
    <?= csrf_field() ?>

    <div class="row g-4">
      <!-- Left Column: Specifications -->
      <div class="col-lg-8">
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-primary">badge</span>
            <span>Product Identification</span>
          </h5>

          <div class="row g-3">
            <div class="col-md-8">
              <label for="name" class="form-label small fw-bold">Product Name <span class="text-danger">*</span></label>
              <input type="text" name="name" id="name" class="form-control" value="<?= e($name) ?>" required>
            </div>

            <div class="col-md-4">
              <label for="brand" class="form-label small fw-bold">Brand / Maker</label>
              <input type="text" name="brand" id="brand" class="form-control" value="<?= e($brand) ?>">
            </div>

            <div class="col-md-6">
              <label for="barcode" class="form-label small fw-bold">Barcode (UPC / EAN / GTIN)</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><span class="material-symbols-rounded fs-6">barcode</span></span>
                <input type="text" name="barcode" id="barcode" class="form-control" value="<?= e($barcode) ?>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="qr_code" class="form-label small fw-bold">QR Code Payload</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><span class="material-symbols-rounded fs-6">qr_code</span></span>
                <input type="text" name="qr_code" id="qr_code" class="form-control" value="<?= e($qrCode) ?>">
              </div>
            </div>

            <div class="col-md-6">
              <label for="category" class="form-label small fw-bold">Primary Category <span class="text-danger">*</span></label>
              <select name="category" id="category" class="form-select" required>
                <?php foreach ($categories as $cat): ?>
                  <option value="<?= e($cat['name']) ?>" <?= $category === $cat['name'] ? 'selected' : '' ?>><?= e($cat['name']) ?></option>
                <?php endforeach; ?>
              </select>
            </div>

            <div class="col-md-6">
              <label for="subcategory" class="form-label small fw-bold">Subcategory</label>
              <input type="text" name="subcategory" id="subcategory" class="form-control" value="<?= e($subcategory) ?>" list="subcatList">
              <datalist id="subcatList">
                <?php foreach ($subcategories as $sc): ?>
                  <option value="<?= e($sc['name']) ?>">
                <?php endforeach; ?>
              </datalist>
            </div>

            <div class="col-12">
              <label for="description" class="form-label small fw-bold">Product Description & Notes</label>
              <textarea name="description" id="description" rows="3" class="form-control"><?= e($description) ?></textarea>
            </div>
          </div>
        </div>

        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-success">payments</span>
            <span>Quantity & Pricing</span>
          </h5>

          <div class="row g-3">
            <div class="col-6 col-md-3">
              <label for="quantity" class="form-label small fw-bold">Quantity</label>
              <input type="number" step="0.01" name="quantity" id="quantity" class="form-control" value="<?= e((string)$quantity) ?>" required>
            </div>

            <div class="col-6 col-md-3">
              <label for="unit" class="form-label small fw-bold">Unit</label>
              <select name="unit" id="unit" class="form-select">
                <option value="pieces" <?= $unit === 'pieces' ? 'selected' : '' ?>>pieces</option>
                <option value="kg" <?= $unit === 'kg' ? 'selected' : '' ?>>kg</option>
                <option value="grams" <?= $unit === 'grams' ? 'selected' : '' ?>>grams</option>
                <option value="litre" <?= $unit === 'litre' ? 'selected' : '' ?>>litre</option>
                <option value="ml" <?= $unit === 'ml' ? 'selected' : '' ?>>ml</option>
                <option value="pack" <?= $unit === 'pack' ? 'selected' : '' ?>>pack</option>
                <option value="box" <?= $unit === 'box' ? 'selected' : '' ?>>box</option>
                <option value="bottles" <?= $unit === 'bottles' ? 'selected' : '' ?>>bottles</option>
              </select>
            </div>

            <div class="col-6 col-md-3">
              <label for="price" class="form-label small fw-bold">Purchase Price</label>
              <input type="number" step="0.01" name="price" id="price" class="form-control" value="<?= e($price) ?>">
            </div>

            <div class="col-6 col-md-3">
              <label for="currency" class="form-label small fw-bold">Currency</label>
              <select name="currency" id="currency" class="form-select">
                <option value="₹" <?= $currency === '₹' ? 'selected' : '' ?>>₹ (INR)</option>
                <option value="$" <?= $currency === '$' ? 'selected' : '' ?>>$ (USD)</option>
                <option value="€" <?= $currency === '€' ? 'selected' : '' ?>>€ (EUR)</option>
                <option value="£" <?= $currency === '£' ? 'selected' : '' ?>>£ (GBP)</option>
              </select>
            </div>

            <div class="col-md-6">
              <label for="storage_location" class="form-label small fw-bold">Storage Location</label>
              <select name="storage_location" id="storage_location" class="form-select">
                <option value="pantry" <?= $storageLocation === 'pantry' ? 'selected' : '' ?>>Pantry</option>
                <option value="fridge" <?= $storageLocation === 'fridge' ? 'selected' : '' ?>>Refrigerator</option>
                <option value="freezer" <?= $storageLocation === 'freezer' ? 'selected' : '' ?>>Freezer</option>
                <option value="kitchenCabinet" <?= $storageLocation === 'kitchenCabinet' ? 'selected' : '' ?>>Kitchen Cabinet</option>
                <option value="bathroom" <?= $storageLocation === 'bathroom' ? 'selected' : '' ?>>Bathroom</option>
                <option value="closet" <?= $storageLocation === 'closet' ? 'selected' : '' ?>>Closet / Wardrobe</option>
                <option value="medicineChest" <?= $storageLocation === 'medicineChest' ? 'selected' : '' ?>>Medicine Chest</option>
              </select>
            </div>
          </div>
        </div>

        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-info">info</span>
            <span>Extended Specifications</span>
          </h5>

          <div class="row g-3">
            <div class="col-md-6">
              <label for="manufacturer" class="form-label small fw-bold">Manufacturer / Company</label>
              <input type="text" name="manufacturer" id="manufacturer" class="form-control" value="<?= e($manufacturer) ?>">
            </div>

            <div class="col-md-6">
              <label for="country_of_origin" class="form-label small fw-bold">Country of Origin</label>
              <input type="text" name="country_of_origin" id="country_of_origin" class="form-control" value="<?= e($origin) ?>">
            </div>

            <div class="col-md-6">
              <label for="warranty_information" class="form-label small fw-bold">Warranty Information</label>
              <input type="text" name="warranty_information" id="warranty_information" class="form-control" value="<?= e($warranty) ?>">
            </div>

            <div class="col-md-6">
              <label for="product_url" class="form-label small fw-bold">Official Product Website</label>
              <input type="url" name="product_url" id="product_url" class="form-control" value="<?= e($website) ?>">
            </div>

            <div class="col-12">
              <label for="ingredients" class="form-label small fw-bold">Ingredients / Composition</label>
              <textarea name="ingredients" id="ingredients" rows="2" class="form-control"><?= e($ingredients) ?></textarea>
            </div>

            <div class="col-12">
              <label for="usage_instructions" class="form-label small fw-bold">Usage / Storage Instructions</label>
              <textarea name="usage_instructions" id="usage_instructions" rows="2" class="form-control"><?= e($instructions) ?></textarea>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Expiry & Status -->
      <div class="col-lg-4">
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-warning">event_available</span>
            <span>Expiry & Reminders</span>
          </h5>

          <div class="mb-3">
            <label for="manufacturing_date" class="form-label small fw-bold">Manufacturing Date</label>
            <input type="date" name="manufacturing_date" id="manufacturing_date" class="form-control" value="<?= e($mfgDate) ?>">
          </div>

          <div class="mb-3">
            <label for="expiry_date" class="form-label small fw-bold">Expiration Date</label>
            <input type="date" name="expiry_date" id="expiry_date" class="form-control" value="<?= e($expiryDate) ?>">
          </div>

          <div class="form-check form-switch mb-3">
            <input class="form-check-input" type="checkbox" role="switch" name="reminder_enabled" id="reminder_enabled" <?= $reminderEnabled ? 'checked' : '' ?>>
            <label class="form-check-label small fw-bold" for="reminder_enabled">Enable Expiry Reminder</label>
          </div>

          <div class="mb-2">
            <label for="reminder_days_before" class="form-label small fw-bold">Notify Days Before Expiry</label>
            <select name="reminder_days_before" id="reminder_days_before" class="form-select">
              <option value="1" <?= $reminderDays === '1' ? 'selected' : '' ?>>1 Day Before</option>
              <option value="3" <?= $reminderDays === '3' ? 'selected' : '' ?>>3 Days Before</option>
              <option value="7" <?= $reminderDays === '7' ? 'selected' : '' ?>>7 Days Before</option>
              <option value="14" <?= $reminderDays === '14' ? 'selected' : '' ?>>14 Days Before</option>
              <option value="30" <?= $reminderDays === '30' ? 'selected' : '' ?>>30 Days Before</option>
            </select>
          </div>
        </div>

        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-primary">add_a_photo</span>
            <span>Product Image</span>
          </h5>

          <div class="text-center mb-3">
            <?php if (!empty($product['image_path'])): ?>
              <img id="imagePreview" src="<?= e($product['image_path']) ?>" class="img-fluid rounded-4 border mb-2" style="max-height: 180px; object-fit: cover;">
              <div class="form-check d-flex justify-content-center gap-2">
                <input class="form-check-input" type="checkbox" name="remove_image" value="1" id="remove_image">
                <label class="form-check-label small text-danger" for="remove_image">Remove current image</label>
              </div>
            <?php else: ?>
              <img id="imagePreview" src="" class="img-fluid rounded-4 border d-none mb-2" style="max-height: 180px; object-fit: cover;">
              <div id="imagePlaceholder" class="p-4 bg-light rounded-4 border border-dashed text-muted">
                <span class="material-symbols-rounded fs-1 d-block mb-1">image</span>
                <span class="small">Upload JPG, PNG, or WEBP (&le; 5MB)</span>
              </div>
            <?php endif; ?>
          </div>

          <div class="mb-3">
            <label for="image_file" class="form-label small fw-bold">Replace Image File</label>
            <input type="file" name="image_file" id="image_file" class="form-control" accept="image/jpeg,image/png,image/webp">
          </div>

          <div>
            <label for="image_url" class="form-label small fw-bold">Or External Image URL</label>
            <input type="url" name="image_url" id="image_url" class="form-control" value="<?= e($product['image_path'] ?? '') ?>">
          </div>
        </div>

        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-secondary">tune</span>
            <span>Status & Classification</span>
          </h5>

          <div class="mb-3">
            <label for="status" class="form-label small fw-bold">Catalog Status</label>
            <select name="status" id="status" class="form-select">
              <option value="Active" <?= $status === 'Active' ? 'selected' : '' ?>>Active</option>
              <option value="Inactive" <?= $status === 'Inactive' ? 'selected' : '' ?>>Inactive</option>
              <option value="Pending Review" <?= $status === 'Pending Review' ? 'selected' : '' ?>>Pending Review</option>
              <option value="Needs Review" <?= $status === 'Needs Review' ? 'selected' : '' ?>>Needs Review</option>
              <option value="Archived" <?= $status === 'Archived' ? 'selected' : '' ?>>Archived</option>
            </select>
          </div>

          <div class="mb-3">
            <label for="review_status" class="form-label small fw-bold">Review Status</label>
            <select name="review_status" id="review_status" class="form-select">
              <option value="Approved" <?= $reviewStatus === 'Approved' ? 'selected' : '' ?>>Approved</option>
              <option value="Pending Review" <?= $reviewStatus === 'Pending Review' ? 'selected' : '' ?>>Pending Review</option>
              <option value="Needs Correction" <?= $reviewStatus === 'Needs Correction' ? 'selected' : '' ?>>Needs Correction</option>
              <option value="Rejected" <?= $reviewStatus === 'Rejected' ? 'selected' : '' ?>>Rejected</option>
            </select>
          </div>

          <div class="mb-3">
            <label for="source" class="form-label small fw-bold">Origin Source</label>
            <select name="source" id="source" class="form-select">
              <option value="Manual Entry" <?= $source === 'Manual Entry' ? 'selected' : '' ?>>Manual Entry</option>
              <option value="Barcode Scanner" <?= $source === 'Barcode Scanner' ? 'selected' : '' ?>>Barcode Scanner</option>
              <option value="OCR" <?= $source === 'OCR' ? 'selected' : '' ?>>OCR Text Extraction</option>
              <option value="AI" <?= $source === 'AI' ? 'selected' : '' ?>>AI Classification</option>
              <option value="API" <?= $source === 'API' ? 'selected' : '' ?>>External REST API</option>
            </select>
          </div>

          <div class="mb-4">
            <label for="category_confidence" class="form-label small fw-bold">Category Confidence (%)</label>
            <input type="number" min="0" max="100" name="category_confidence" id="category_confidence" class="form-control" value="<?= e((string)$confidence) ?>">
          </div>

          <button type="submit" class="btn btn-primary w-100 py-2.5 rounded-3 fw-bold d-flex align-items-center justify-content-center gap-2" style="background-color: #10B981; border-color: #10B981;">
            <span class="material-symbols-rounded">save</span>
            <span>Update Product</span>
          </button>
        </div>
      </div>
    </div>
  </form>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
