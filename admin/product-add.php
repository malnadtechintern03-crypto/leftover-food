<?php
/**
 * ScanSmart Product Management - Add New Product Form
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/includes/functions.php';

require_role('super_admin', 'admin', 'editor');

$db = Database::getConnection();

$categories = $db->query("SELECT id, name FROM categories WHERE status = 'active' ORDER BY name ASC")->fetchAll();
$subcategories = $db->query("SELECT id, category_id, name FROM subcategories WHERE status = 'active' ORDER BY name ASC")->fetchAll();

$errors = [];
$name = '';
$brand = '';
$barcode = '';
$qrCode = '';
$category = 'Food & Beverages';
$subcategory = '';
$description = '';
$quantity = 1.0;
$unit = 'pieces';
$price = '';
$currency = '₹';
$mfgDate = '';
$expiryDate = '';
$reminderEnabled = 1;
$reminderDays = '7';
$storageLocation = 'pantry';
$manufacturer = '';
$origin = '';
$ingredients = '';
$instructions = '';
$warranty = '';
$website = '';
$source = 'Manual Entry';
$confidence = 100;
$status = 'Active';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security token expired. Please resubmit the form.';
    } else {
        $name = trim($_POST['name'] ?? '');
        $brand = trim($_POST['brand'] ?? '');
        $barcode = trim($_POST['barcode'] ?? '');
        $qrCode = trim($_POST['qr_code'] ?? '');
        $category = trim($_POST['category'] ?? 'Food & Beverages');
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

        if ($name === '') {
            $errors[] = 'Product name is required.';
        }

        // Check duplicate barcode if barcode is provided
        if ($barcode !== '') {
            $checkStmt = $db->prepare('SELECT id FROM products WHERE barcode = ? LIMIT 1');
            $checkStmt->execute([$barcode]);
            if ($checkStmt->fetch()) {
                $errors[] = "A product with barcode '{$barcode}' already exists in the catalog.";
            }
        }

        // Handle Image Upload
        $imagePath = null;
        if (!empty($_FILES['image_file']['name'])) {
            $uploadResult = upload_product_image($_FILES['image_file']);
            if ($uploadResult['success']) {
                $imagePath = $uploadResult['url'];
            } else {
                $errors[] = $uploadResult['error'];
            }
        } elseif (!empty($_POST['image_url'])) {
            $imagePath = trim($_POST['image_url']);
        }

        if (empty($errors)) {
            $id = 'prod-' . bin2hex(random_bytes(10));
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

            $insertStmt = $db->prepare("
                INSERT INTO products (
                    id, user_id, name, brand, barcode, qr_code, image_path, category, subcategory,
                    description, quantity, unit, purchase_price, currency, manufacturing_date,
                    expiry_date, reminder_date, reminder_enabled, reminder_days_before, expiry_status,
                    storage_location, manufacturer, country_of_origin, ingredients, usage_instructions,
                    warranty_information, product_url, source, category_confidence, status
                ) VALUES (
                    ?, 'default_user', ?, ?, ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?
                )
            ");

            $insertStmt->execute([
                $id, $name, $brand ?: null, $barcode ?: null, $qrCode ?: null, $imagePath, $category, $subcategory ?: null,
                $description ?: null, $quantity, $unit, $priceVal, $currency, $mfg,
                $exp, $reminderDate, $reminderEnabled, $reminderDays, $expiryStatus,
                $storageLocation, $manufacturer ?: null, $origin ?: null, $ingredients ?: null, $instructions ?: null,
                $warranty ?: null, $website ?: null, $source, $confidence, $status
            ]);

            // If reminder enabled, add record to product_reminders
            if ($exp !== null && $reminderEnabled && $reminderDate !== null) {
                $notifId = abs(crc32($id));
                $insRem = $db->prepare("
                    INSERT INTO product_reminders (user_id, product_id, reminder_date, days_before_expiry, notification_id)
                    VALUES ('default_user', ?, ?, ?, ?)
                ");
                $insRem->execute([$id, $reminderDate, (int)$reminderDays, $notifId]);
            }

            log_admin_activity('Add Product', "Created product '{$name}' (Barcode: " . ($barcode ?: 'None') . ")");
            set_flash('success', "Product '{$name}' was successfully cataloged.");
            header('Location: ' . base_url('products.php'));
            exit;
        }
    }
}

$pageTitle = 'Add New Product';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-4xl mx-auto mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h2 class="h4 fw-bold mb-1">Catalog New Universal Product</h2>
      <p class="text-muted small mb-0">Enter full specifications, barcodes, images, and expiry schedules.</p>
    </div>
    <a href="<?= base_url('products.php') ?>" class="btn btn-outline-secondary rounded-pill px-3 py-1.5 small d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-6">arrow_back</span>
      <span>Back to Products</span>
    </a>
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
      <!-- Left Column: Core Details -->
      <div class="col-lg-8">
        <!-- 1. Identification -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-primary">badge</span>
            <span>Product Identification</span>
          </h5>

          <div class="row g-3">
            <div class="col-md-8">
              <label for="name" class="form-label small fw-bold">Product Name <span class="text-danger">*</span></label>
              <input type="text" name="name" id="name" class="form-control" value="<?= e($name) ?>" placeholder="e.g. Organic Almond Milk" required>
            </div>

            <div class="col-md-4">
              <label for="brand" class="form-label small fw-bold">Brand / Maker</label>
              <input type="text" name="brand" id="brand" class="form-control" value="<?= e($brand) ?>" placeholder="e.g. Silk">
            </div>

            <div class="col-md-6">
              <label for="barcode" class="form-label small fw-bold">Barcode (UPC / EAN / GTIN)</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><span class="material-symbols-rounded fs-6">barcode</span></span>
                <input type="text" name="barcode" id="barcode" class="form-control" value="<?= e($barcode) ?>" placeholder="e.g. 8901262010054">
              </div>
            </div>

            <div class="col-md-6">
              <label for="qr_code" class="form-label small fw-bold">QR Code Payload / Serial</label>
              <div class="input-group">
                <span class="input-group-text bg-light"><span class="material-symbols-rounded fs-6">qr_code</span></span>
                <input type="text" name="qr_code" id="qr_code" class="form-control" value="<?= e($qrCode) ?>" placeholder="e.g. QR7849302">
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
              <input type="text" name="subcategory" id="subcategory" class="form-control" value="<?= e($subcategory) ?>" placeholder="e.g. Plant-based Milks" list="subcatList">
              <datalist id="subcatList">
                <?php foreach ($subcategories as $sc): ?>
                  <option value="<?= e($sc['name']) ?>">
                <?php endforeach; ?>
              </datalist>
            </div>

            <div class="col-12">
              <label for="description" class="form-label small fw-bold">Product Description & Notes</label>
              <textarea name="description" id="description" rows="3" class="form-control" placeholder="Detailed product specifications, nutritional highlights, or storage precautions..."><?= e($description) ?></textarea>
            </div>
          </div>
        </div>

        <!-- 2. Quantity & Pricing -->
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
              <input type="number" step="0.01" name="price" id="price" class="form-control" value="<?= e($price) ?>" placeholder="0.00">
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

        <!-- 3. Extended Metadata -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-info">info</span>
            <span>Extended Specifications & Origin</span>
          </h5>

          <div class="row g-3">
            <div class="col-md-6">
              <label for="manufacturer" class="form-label small fw-bold">Manufacturer / Company</label>
              <input type="text" name="manufacturer" id="manufacturer" class="form-control" value="<?= e($manufacturer) ?>" placeholder="e.g. Danone North America">
            </div>

            <div class="col-md-6">
              <label for="country_of_origin" class="form-label small fw-bold">Country of Origin</label>
              <input type="text" name="country_of_origin" id="country_of_origin" class="form-control" value="<?= e($origin) ?>" placeholder="e.g. India, USA, Japan">
            </div>

            <div class="col-md-6">
              <label for="warranty_information" class="form-label small fw-bold">Warranty Information</label>
              <input type="text" name="warranty_information" id="warranty_information" class="form-control" value="<?= e($warranty) ?>" placeholder="e.g. 1 Year Limited Warranty">
            </div>

            <div class="col-md-6">
              <label for="product_url" class="form-label small fw-bold">Official Product Website</label>
              <input type="url" name="product_url" id="product_url" class="form-control" value="<?= e($website) ?>" placeholder="https://example.com/product">
            </div>

            <div class="col-12">
              <label for="ingredients" class="form-label small fw-bold">Ingredients / Composition</label>
              <textarea name="ingredients" id="ingredients" rows="2" class="form-control" placeholder="Almondmilk, Cane Sugar, Calcium Carbonate, Sea Salt, Vitamin D2..."><?= e($ingredients) ?></textarea>
            </div>

            <div class="col-12">
              <label for="usage_instructions" class="form-label small fw-bold">Usage / Storage Instructions</label>
              <textarea name="usage_instructions" id="usage_instructions" rows="2" class="form-control" placeholder="Keep refrigerated. Shake well before serving. Best consumed within 7 days of opening."><?= e($instructions) ?></textarea>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Expiration, Image & Status -->
      <div class="col-lg-4">
        <!-- 4. Expiry & Reminder Schedules -->
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
            <div class="form-text" style="font-size: 11.5px;">Leave blank if item does not expire.</div>
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
              <option value="7" <?= $reminderDays === '7' ? 'selected' : '' ?>>7 Days Before (Recommended)</option>
              <option value="14" <?= $reminderDays === '14' ? 'selected' : '' ?>>14 Days Before</option>
              <option value="30" <?= $reminderDays === '30' ? 'selected' : '' ?>>30 Days Before</option>
            </select>
          </div>
        </div>

        <!-- 5. Product Image Upload & Preview -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-primary">add_a_photo</span>
            <span>Product Image</span>
          </h5>

          <div class="text-center mb-3">
            <img id="imagePreview" src="" class="img-fluid rounded-4 border d-none" style="max-height: 180px; object-fit: cover;">
            <div id="imagePlaceholder" class="p-4 bg-light rounded-4 border border-dashed text-muted">
              <span class="material-symbols-rounded fs-1 d-block mb-1">image</span>
              <span class="small">Upload JPG, PNG, or WEBP (&le; 5MB)</span>
            </div>
          </div>

          <div class="mb-3">
            <label for="image_file" class="form-label small fw-bold">Upload Local Image</label>
            <input type="file" name="image_file" id="image_file" class="form-control" accept="image/jpeg,image/png,image/webp">
          </div>

          <div>
            <label for="image_url" class="form-label small fw-bold">Or Paste Remote Image URL</label>
            <input type="url" name="image_url" id="image_url" class="form-control" placeholder="https://images.unsplash.com/...">
          </div>
        </div>

        <!-- 6. Status & Publishing -->
        <div class="card border-0 shadow-sm rounded-4 p-4 bg-white mb-4">
          <h5 class="fw-bold mb-3 d-flex align-items-center gap-2">
            <span class="material-symbols-rounded text-secondary">tune</span>
            <span>Status & Classification</span>
          </h5>

          <div class="mb-3">
            <label for="status" class="form-label small fw-bold">Catalog Status</label>
            <select name="status" id="status" class="form-select">
              <option value="Active" <?= $status === 'Active' ? 'selected' : '' ?>>Active (Visible to Users)</option>
              <option value="Inactive" <?= $status === 'Inactive' ? 'selected' : '' ?>>Inactive</option>
              <option value="Pending Review" <?= $status === 'Pending Review' ? 'selected' : '' ?>>Pending Review</option>
              <option value="Needs Review" <?= $status === 'Needs Review' ? 'selected' : '' ?>>Needs Review</option>
            </select>
          </div>

          <div class="mb-3">
            <label for="source" class="form-label small fw-bold">Origin Source</label>
            <select name="source" id="source" class="form-select">
              <option value="Manual Entry">Manual Entry</option>
              <option value="Barcode Scanner">Barcode Scanner</option>
              <option value="OCR">OCR Text Extraction</option>
              <option value="AI">AI Classification</option>
              <option value="API">External REST API</option>
            </select>
          </div>

          <div class="mb-4">
            <label for="category_confidence" class="form-label small fw-bold">Category Confidence (%)</label>
            <input type="number" min="0" max="100" name="category_confidence" id="category_confidence" class="form-control" value="<?= e((string)$confidence) ?>">
          </div>

          <button type="submit" class="btn btn-primary w-100 py-2.5 rounded-3 fw-bold d-flex align-items-center justify-content-center gap-2" style="background-color: #10B981; border-color: #10B981;">
            <span class="material-symbols-rounded">save</span>
            <span>Save & Publish Product</span>
          </button>
        </div>
      </div>
    </div>
  </form>
</div>

<!-- Live Image Preview Script -->
<script>
document.addEventListener('DOMContentLoaded', function () {
  const fileInput = document.getElementById('image_file');
  const urlInput = document.getElementById('image_url');
  const preview = document.getElementById('imagePreview');
  const placeholder = document.getElementById('imagePlaceholder');

  fileInput.addEventListener('change', function () {
    const file = this.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = function (e) {
        preview.src = e.target.result;
        preview.classList.remove('d-none');
        placeholder.classList.add('d-none');
      };
      reader.readAsDataURL(file);
    }
  });

  urlInput.addEventListener('input', function () {
    const val = this.value.trim();
    if (val) {
      preview.src = val;
      preview.classList.remove('d-none');
      placeholder.classList.add('d-none');
    }
  });
});
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
