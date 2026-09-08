<?php
/**
 * Admin Panel - Add New Product
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

$categoriesList = [
    'Dairy',
    'Grains & Pulses',
    'Produce & Fresh Herbs',
    'Meats & Seafood',
    'Bakery & Pastries',
    'Snacks & Treats',
    'Condiments & Sauces',
    'Beverages',
    'Frozen Foods',
    'Canned & Packaged',
    'Personal Care & Beauty',
    'Medicines & First Aid',
    'Cleaning & Household',
    'Electronics & Batteries',
    'Other Products',
];

$storageLocations = [
    'pantry' => 'Pantry Cabinet',
    'fridge' => 'Refrigerator',
    'freezer' => 'Deep Freezer',
    'counter' => 'Kitchen Countertop',
    'medicineChest' => 'Medicine Chest / Box',
    'bathroom' => 'Bathroom Vanity',
    'closet' => 'Wardrobe / Closet',
    'kitchenCabinet' => 'Kitchen Cabinet',
];

$errors = [];
$name = '';
$brand = '';
$barcode = '';
$imagePath = '';
$category = 'Dairy';
$subcategory = '';
$quantity = '1.0';
$unit = 'pieces';
$purchasePrice = '';
$purchaseDate = date('Y-m-d');
$manufacturingDate = '';
$hasExpiry = true;
$expiryDate = date('Y-m-d', strtotime('+7 days'));
$reminderEnabled = 1;
$selectedDays = ['7', '1'];
$storageLocation = 'pantry';
$notes = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verify_csrf()) {
        $errors[] = 'Security token invalid or expired. Please reload and try again.';
    }

    $name = trim($_POST['name'] ?? '');
    $brand = trim($_POST['brand'] ?? '') ?: null;
    $barcode = trim($_POST['barcode'] ?? '') ?: null;
    $imagePath = trim($_POST['image_path'] ?? '') ?: null;
    $category = trim($_POST['category'] ?? 'Other Products');
    $subcategory = trim($_POST['subcategory'] ?? '') ?: null;
    $quantity = max(0.01, (float)($_POST['quantity'] ?? 1.0));
    $unit = trim($_POST['unit'] ?? 'pieces');
    $purchasePrice = isset($_POST['purchase_price']) && $_POST['purchase_price'] !== '' ? (float)$_POST['purchase_price'] : null;
    $purchaseDate = !empty($_POST['purchase_date']) ? date('Y-m-d', strtotime($_POST['purchase_date'])) : date('Y-m-d');
    $manufacturingDate = !empty($_POST['manufacturing_date']) ? date('Y-m-d', strtotime($_POST['manufacturing_date'])) : null;
    
    $hasExpiry = isset($_POST['has_expiry']) && $_POST['has_expiry'] === '1';
    $expiryDate = $hasExpiry && !empty($_POST['expiry_date']) ? date('Y-m-d', strtotime($_POST['expiry_date'])) : null;
    
    $reminderEnabled = isset($_POST['reminder_enabled']) && $_POST['reminder_enabled'] === '1' ? 1 : 0;
    $selectedDays = isset($_POST['reminder_days']) && is_array($_POST['reminder_days']) ? array_filter($_POST['reminder_days'], fn($v) => is_numeric($v)) : [];
    $reminderDaysBefore = implode(',', $selectedDays);
    $reminderDate = !empty($_POST['reminder_date']) ? date('Y-m-d H:i:s', strtotime($_POST['reminder_date'])) : null;

    $storageLocation = trim($_POST['storage_location'] ?? 'pantry');
    $notes = trim($_POST['notes'] ?? '') ?: null;

    if ($name === '') {
        $errors[] = 'Product name is required.';
    }

    if ($hasExpiry && $expiryDate === null) {
        $errors[] = 'Please select a valid expiration date or uncheck expiration requirement.';
    }

    if (empty($errors)) {
        try {
            $id = 'prod-' . bin2hex(random_bytes(6));
            $userId = 'default_user';

            // Calculate expiry status
            $expiryStatus = 'No Expiry Date';
            if ($expiryDate !== null) {
                $today = new DateTime('today');
                $exp = new DateTime($expiryDate);
                $diff = (int)$today->diff($exp)->format('%r%a');
                if ($diff < 0) {
                    $expiryStatus = 'Expired';
                } elseif ($diff <= 2) {
                    $expiryStatus = 'Expiring Soon';
                } else {
                    $expiryStatus = 'Safe';
                }
            }

            $sql = "INSERT INTO products (
                id, user_id, name, brand, barcode, image_path, category, subcategory,
                quantity, unit, purchase_price, purchase_date, manufacturing_date,
                expiry_date, reminder_date, reminder_enabled, reminder_days_before,
                expiry_status, storage_location, notes, is_consumed, is_favorite
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?,
                ?, ?, ?, ?,
                ?, ?, ?, 0, 0
            )";

            $stmt = $db->prepare($sql);
            $stmt->execute([
                $id, $userId, $name, $brand, $barcode, $imagePath, $category, $subcategory,
                $quantity, $unit, $purchasePrice, $purchaseDate, $manufacturingDate,
                $expiryDate, $reminderDate, $reminderEnabled, $reminderDaysBefore,
                $expiryStatus, $storageLocation, $notes
            ]);

            // Insert initial reminders if enabled
            if ($reminderEnabled && $expiryDate !== null) {
                $insRem = $db->prepare("INSERT INTO product_reminders (
                    user_id, product_id, reminder_date, days_before_expiry, notification_id, is_sent, is_enabled
                ) VALUES (?, ?, ?, ?, ?, 0, 1)");

                foreach ($selectedDays as $days) {
                    $remDays = (int)$days;
                    $rDate = date('Y-m-d 09:00:00', strtotime("{$expiryDate} -{$remDays} days"));
                    $notifId = abs(crc32($id . '_' . $remDays)) % 2147483647;
                    $insRem->execute([$userId, $id, $rDate, $remDays, $notifId]);
                }
            }

            set_flash('success', "Product '{$name}' created successfully!");
            header('Location: ' . base_url('products/index.php'));
            exit;

        } catch (Throwable $e) {
            $errors[] = 'Database error: ' . $e->getMessage();
        }
    }
}

$pageTitle = 'Add New Product';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex align-items-center justify-content-between mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Add New Product</h2>
    <p class="text-muted small mb-0">Record a new grocery or household product into inventory with expiry tracking.</p>
  </div>
  <a href="<?= base_url('products/index.php') ?>" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
    <span class="material-symbols-rounded fs-5">arrow_back</span>
    <span>Back to List</span>
  </a>
</div>

<?php if (!empty($errors)): ?>
  <div class="alert alert-danger alert-dismissible fade show rounded-3" role="alert">
    <strong>Please fix the following:</strong>
    <ul class="mb-0 mt-1 ps-3">
      <?php foreach ($errors as $err): ?>
        <li><?= e($err) ?></li>
      <?php endforeach; ?>
    </ul>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
<?php endif; ?>

<form method="POST" action="">
  <?= csrf_field() ?>

  <div class="row g-4">
    <!-- Left Column: Core Product Details -->
    <div class="col-lg-8">
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Product Information</h3>
        
        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label required">Product Name</label>
            <input type="text" name="name" value="<?= e($name) ?>" class="form-control" required placeholder="e.g. Whole Milk, Brown Bread, Face Cream">
          </div>

          <div class="col-md-4">
            <label class="form-label">Brand / Manufacturer</label>
            <input type="text" name="brand" value="<?= e((string)$brand) ?>" class="form-control" placeholder="e.g. Amul, Nestle, Britannia">
          </div>

          <div class="col-md-6">
            <label class="form-label required">Category</label>
            <select name="category" class="form-select" required>
              <?php foreach ($categoriesList as $cat): ?>
                <option value="<?= e($cat) ?>" <?= $category === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="col-md-6">
            <label class="form-label">Subcategory</label>
            <input type="text" name="subcategory" value="<?= e((string)$subcategory) ?>" class="form-control" placeholder="e.g. Dairy Milk, Biscuits, Herbs">
          </div>

          <div class="col-md-6">
            <label class="form-label">Barcode (EAN / UPC)</label>
            <input type="text" name="barcode" value="<?= e((string)$barcode) ?>" class="form-control" placeholder="e.g. 8901262010054">
          </div>

          <div class="col-md-6">
            <label class="form-label">Image URL</label>
            <input type="url" name="image_path" value="<?= e((string)$imagePath) ?>" class="form-control" placeholder="https://example.com/product.jpg">
          </div>
        </div>
      </div>

      <!-- Inventory Quantity & Price -->
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Quantity & Purchasing Details</h3>
        
        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label required">Quantity</label>
            <input type="number" step="0.01" min="0.01" name="quantity" value="<?= e((string)$quantity) ?>" class="form-control" required>
          </div>

          <div class="col-md-4">
            <label class="form-label required">Unit</label>
            <select name="unit" class="form-select">
              <?php foreach (['pieces', 'kg', 'grams', 'litre', 'ml', 'pack', 'box', 'can', 'bottle'] as $u): ?>
                <option value="<?= $u ?>" <?= $unit === $u ? 'selected' : '' ?>><?= ucfirst($u) ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="col-md-4">
            <label class="form-label">Purchase Price (₹)</label>
            <input type="number" step="0.01" min="0" name="purchase_price" value="<?= e((string)$purchasePrice) ?>" class="form-control" placeholder="0.00">
          </div>

          <div class="col-md-6">
            <label class="form-label">Purchase Date</label>
            <input type="date" name="purchase_date" value="<?= e($purchaseDate) ?>" class="form-control">
          </div>

          <div class="col-md-6">
            <label class="form-label">Manufacturing / Production Date</label>
            <input type="date" name="manufacturing_date" value="<?= e((string)$manufacturingDate) ?>" class="form-control">
          </div>
        </div>
      </div>

      <!-- Notes -->
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Notes & Storage Advice</h3>
        <div class="mb-3">
          <label class="form-label">Storage Location</label>
          <select name="storage_location" class="form-select">
            <?php foreach ($storageLocations as $key => $lbl): ?>
              <option value="<?= $key ?>" <?= $storageLocation === $key ? 'selected' : '' ?>><?= e($lbl) ?></option>
            <?php endforeach; ?>
          </select>
        </div>
        <div>
          <label class="form-label">Custom Notes</label>
          <textarea name="notes" rows="3" class="form-control" placeholder="e.g. Keep in sealed container after opening. Consume within 3 days."><?= e($notes) ?></textarea>
        </div>
      </div>
    </div>

    <!-- Right Column: Expiration & Reminders -->
    <div class="col-lg-4">
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Shelf Life & Expiry</h3>

        <div class="form-check form-switch mb-3">
          <input class="form-check-input" type="checkbox" name="has_expiry" value="1" id="hasExpirySwitch" <?= $hasExpiry ? 'checked' : '' ?>>
          <label class="form-check-label fw-semibold" for="hasExpirySwitch">This product has an expiration date</label>
        </div>

        <div id="expiryDateContainer" style="<?= $hasExpiry ? '' : 'display: none;' ?>">
          <div class="mb-3">
            <label class="form-label fw-bold">Expiration Date</label>
            <input type="date" name="expiry_date" value="<?= e((string)$expiryDate) ?>" class="form-control">
          </div>
        </div>

        <hr class="my-3">

        <h4 class="fw-bold mb-2" style="font-size: 14px;">Automated Expiry Reminders</h4>
        <div class="form-check form-switch mb-3">
          <input class="form-check-input" type="checkbox" name="reminder_enabled" value="1" id="reminderEnabledSwitch" <?= $reminderEnabled ? 'checked' : '' ?>>
          <label class="form-check-label fw-semibold" for="reminderEnabledSwitch">Enable reminders</label>
        </div>

        <div id="reminderOptionsContainer" style="<?= $reminderEnabled ? '' : 'display: none;' ?>">
          <label class="form-label small text-muted">Notify me before expiry:</label>
          <div class="d-flex flex-wrap gap-2 mb-3">
            <?php foreach ([1, 2, 3, 7, 14, 30] as $d): ?>
              <?php $isChecked = in_array((string)$d, $selectedDays, true); ?>
              <div class="form-check form-check-inline m-0">
                <input class="btn-check" type="checkbox" name="reminder_days[]" value="<?= $d ?>" id="day_<?= $d ?>" <?= $isChecked ? 'checked' : '' ?>>
                <label class="btn btn-sm btn-outline-primary px-2.5 py-1 rounded-pill" for="day_<?= $d ?>"><?= $d ?> day<?= $d > 1 ? 's' : '' ?></label>
              </div>
            <?php endforeach; ?>
          </div>
        </div>
      </div>

      <!-- Action Box -->
      <div class="card-box">
        <button type="submit" class="btn btn-primary-custom w-100 justify-content-center py-2.5 mb-2">
          <span class="material-symbols-rounded">save</span>
          <span>Save Product</span>
        </button>
        <a href="<?= base_url('products/index.php') ?>" class="btn btn-secondary-custom w-100 justify-content-center py-2">
          <span>Cancel</span>
        </a>
      </div>
    </div>
  </div>
</form>

<script>
document.addEventListener('DOMContentLoaded', () => {
  const expirySwitch = document.getElementById('hasExpirySwitch');
  const expiryContainer = document.getElementById('expiryDateContainer');
  const reminderSwitch = document.getElementById('reminderEnabledSwitch');
  const reminderContainer = document.getElementById('reminderOptionsContainer');

  if (expirySwitch && expiryContainer) {
    expirySwitch.addEventListener('change', () => {
      expiryContainer.style.display = expirySwitch.checked ? '' : 'none';
    });
  }

  if (reminderSwitch && reminderContainer) {
    reminderSwitch.addEventListener('change', () => {
      reminderContainer.style.display = reminderSwitch.checked ? '' : 'none';
    });
  }
});
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
