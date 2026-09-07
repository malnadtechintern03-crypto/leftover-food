<?php
/**
 * Admin Panel - Edit Product Form
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$id = trim($_GET['id'] ?? '');

if ($id === '') {
    header('Location: ' . base_url('products/index.php'));
    exit;
}

$db = Database::getConnection();

$stmt = $db->prepare('SELECT * FROM products WHERE id = ? LIMIT 1');
$stmt->execute([$id]);
$product = $stmt->fetch();

if (!$product) {
    set_flash('error', 'Product not found.');
    header('Location: ' . base_url('products/index.php'));
    exit;
}

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

            $sql = "UPDATE products SET
                name = ?, brand = ?, barcode = ?, image_path = ?, category = ?, subcategory = ?,
                quantity = ?, unit = ?, purchase_price = ?, purchase_date = ?, manufacturing_date = ?,
                expiry_date = ?, reminder_date = ?, reminder_enabled = ?, reminder_days_before = ?,
                expiry_status = ?, storage_location = ?, notes = ?
                WHERE id = ?";

            $stmt = $db->prepare($sql);
            $stmt->execute([
                $name, $brand, $barcode, $imagePath, $category, $subcategory,
                $quantity, $unit, $purchasePrice, $purchaseDate, $manufacturingDate,
                $expiryDate, $reminderDate, $reminderEnabled, $reminderDaysBefore,
                $expiryStatus, $storageLocation, $notes, $id
            ]);

            // Reschedule reminders
            $db->prepare('DELETE FROM product_reminders WHERE product_id = ?')->execute([$id]);

            if ($reminderEnabled && $expiryDate !== null) {
                $notificationId = (int)$product['notification_id'];
                $userId = $product['user_id'];
                $insRem = $db->prepare("INSERT INTO product_reminders (
                    user_id, product_id, reminder_date, days_before_expiry, notification_id, is_sent, is_enabled
                ) VALUES (?, ?, ?, ?, ?, 0, 1)");

                foreach ($selectedDays as $d) {
                    $daysInt = (int)$d;
                    $remTime = date('Y-m-d 09:00:00', strtotime("{$expiryDate} -{$daysInt} days"));
                    $notifSubId = abs(($notificationId * 31 + $daysInt) % 100000000);
                    $insRem->execute([$userId, $id, $remTime, $daysInt, $notifSubId]);
                }

                if ($reminderDate !== null) {
                    $insRem->execute([$userId, $id, $reminderDate, 0, abs(($notificationId * 31 + 999) % 100000000)]);
                }
            }

            set_flash('success', 'Product "' . $name . '" updated successfully.');
            header('Location: ' . base_url('products/index.php'));
            exit;
        } catch (Throwable $e) {
            $errors[] = 'Failed to update product: ' . $e->getMessage();
        }
    }
}

// Current active reminder periods
$activeDays = array_map('trim', explode(',', $product['reminder_days_before'] ?? ''));

$pageTitle = 'Edit Product: ' . $product['name'];
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex align-items-center justify-content-between mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Edit Product Details</h2>
    <p class="text-muted small mb-0">Update item specifications, expiration tracking, and automated reminder alerts.</p>
  </div>
  <a href="<?= base_url('products/index.php') ?>" class="btn btn-secondary-custom">
    <span class="material-symbols-rounded fs-5">arrow_back</span>
    <span>Back to Products</span>
  </a>
</div>

<?php if (!empty($errors)): ?>
  <div class="alert alert-danger d-flex align-items-center mb-4" role="alert">
    <span class="material-symbols-rounded me-2 fs-5">error</span>
    <div>
      <ul class="mb-0 ps-3">
        <?php foreach ($errors as $error): ?>
          <li><?= e($error) ?></li>
        <?php endforeach; ?>
      </ul>
    </div>
  </div>
<?php endif; ?>

<form method="POST" action="">
  <?= csrf_field() ?>

  <div class="row g-4">
    <!-- Left Column: Core Product Info -->
    <div class="col-lg-8">
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Product Information</h3>

        <div class="row g-3">
          <div class="col-md-8">
            <label class="form-label fw-semibold small">Product Name <span class="text-danger">*</span></label>
            <input type="text" name="name" class="form-control" value="<?= e($product['name']) ?>" required>
          </div>

          <div class="col-md-4">
            <label class="form-label fw-semibold small">Brand</label>
            <input type="text" name="brand" class="form-control" value="<?= e($product['brand'] ?? '') ?>" placeholder="e.g. Sony, Amul">
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Barcode / SKU</label>
            <input type="text" name="barcode" class="form-control" value="<?= e($product['barcode'] ?? '') ?>" placeholder="e.g. 8901262010054">
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Product Image URL</label>
            <input type="url" name="image_path" class="form-control" value="<?= e($product['image_path'] ?? '') ?>" placeholder="https://...">
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Category <span class="text-danger">*</span></label>
            <select name="category" class="form-select" required>
              <?php foreach ($categoriesList as $cat): ?>
                <option value="<?= e($cat) ?>" <?= $product['category'] === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Subcategory</label>
            <input type="text" name="subcategory" class="form-control" value="<?= e($product['subcategory'] ?? '') ?>" placeholder="e.g. Fresh Milk, Analgesics">
          </div>

          <div class="col-md-4">
            <label class="form-label fw-semibold small">Quantity</label>
            <input type="number" step="0.01" min="0" name="quantity" class="form-control" value="<?= (float)$product['quantity'] ?>" required>
          </div>

          <div class="col-md-4">
            <label class="form-label fw-semibold small">Unit</label>
            <input type="text" name="unit" class="form-control" value="<?= e($product['unit']) ?>" placeholder="pieces, kg, litres">
          </div>

          <div class="col-md-4">
            <label class="form-label fw-semibold small">Purchase Price</label>
            <div class="input-group">
              <span class="input-group-text">$</span>
              <input type="number" step="0.01" min="0" name="purchase_price" class="form-control" value="<?= $product['purchase_price'] !== null ? number_format((float)$product['purchase_price'], 2) : '' ?>">
            </div>
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Purchase Date</label>
            <input type="date" name="purchase_date" class="form-control" value="<?= e($product['purchase_date'] ?? date('Y-m-d')) ?>">
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Manufacturing Date</label>
            <input type="date" name="manufacturing_date" class="form-control" value="<?= e($product['manufacturing_date'] ?? '') ?>">
          </div>

          <div class="col-md-6">
            <label class="form-label fw-semibold small">Storage Location</label>
            <select name="storage_location" class="form-select">
              <?php foreach ($storageLocations as $key => $label): ?>
                <option value="<?= e($key) ?>" <?= $product['storage_location'] === $key ? 'selected' : '' ?>><?= e($label) ?></option>
              <?php endforeach; ?>
            </select>
          </div>

          <div class="col-12">
            <label class="form-label fw-semibold small">Notes & Storage Instructions</label>
            <textarea name="notes" class="form-control" rows="3"><?= e($product['notes'] ?? '') ?></textarea>
          </div>
        </div>
      </div>
    </div>

    <!-- Right Column: Expiration & Reminder Settings -->
    <div class="col-lg-4">
      <!-- Expiration Date Box -->
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Expiration Settings</h3>
        
        <div class="form-check form-switch mb-3">
          <input class="form-check-input" type="checkbox" name="has_expiry" id="hasExpirySwitch" value="1" <?= $product['expiry_date'] !== null ? 'checked' : '' ?> onchange="toggleExpiryField(this.checked)">
          <label class="form-check-label fw-semibold small" for="hasExpirySwitch">This product has an expiration date</label>
        </div>

        <div id="expiryDateField" style="<?= $product['expiry_date'] === null ? 'display:none;' : '' ?>">
          <label class="form-label fw-semibold small">Expiration Date <span class="text-danger">*</span></label>
          <input type="date" name="expiry_date" id="expiryDateInput" class="form-control" value="<?= e($product['expiry_date'] ?? '') ?>">
          <div class="form-text small">Leave unchecked for electronics, clothes, tools, and non-perishables.</div>
        </div>
      </div>

      <!-- Reminder Schedule Box -->
      <div class="card-box mb-4">
        <h3 class="fw-bold mb-3" style="font-size: 16px;">Reminder Schedule</h3>

        <div class="form-check form-switch mb-3">
          <input class="form-check-input" type="checkbox" name="reminder_enabled" id="reminderEnabledSwitch" value="1" <?= $product['reminder_enabled'] ? 'checked' : '' ?>>
          <label class="form-check-label fw-semibold small" for="reminderEnabledSwitch">Enable expiration reminder alerts</label>
        </div>

        <label class="form-label fw-semibold small mb-2">Alert Timing (Multiple selections):</label>
        <div class="d-flex flex-wrap gap-2 mb-3">
          <?php foreach ([1, 3, 7, 14, 30] as $day): ?>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" name="reminder_days[]" value="<?= $day ?>" id="remDay_<?= $day ?>" <?= in_array((string)$day, $activeDays, true) ? 'checked' : '' ?>>
              <label class="form-check-label small" for="remDay_<?= $day ?>"><?= $day ?>d before</label>
            </div>
          <?php endforeach; ?>
        </div>

        <label class="form-label fw-semibold small">Custom Reminder Date & Time</label>
        <input type="datetime-local" name="reminder_date" class="form-control" value="<?= !empty($product['reminder_date']) ? date('Y-m-d\TH:i', strtotime($product['reminder_date'])) : '' ?>">
      </div>

      <!-- Action Buttons -->
      <div class="d-grid gap-2">
        <button type="submit" class="btn btn-primary-custom py-2">
          <span class="material-symbols-rounded fs-5">save</span>
          <span>Save Changes</span>
        </button>
        <a href="<?= base_url('products/index.php') ?>" class="btn btn-outline-secondary">Cancel</a>
      </div>
    </div>
  </div>
</form>

<script>
function toggleExpiryField(hasExpiry) {
  const field = document.getElementById('expiryDateField');
  const input = document.getElementById('expiryDateInput');
  if (hasExpiry) {
    field.style.display = 'block';
  } else {
    field.style.display = 'none';
    input.value = '';
  }
}
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
