<?php
/**
 * Admin Panel - Universal Products Management & Expiration Tracking
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

// Filters & Pagination
$search = trim($_GET['q'] ?? '');
$category = trim($_GET['category'] ?? '');
$status = trim($_GET['status'] ?? '');
$page = max(1, (int)($_GET['page'] ?? 1));
$limit = 15;
$offset = ($page - 1) * $limit;

$where = ['p.is_consumed = 0'];
$params = [];

if ($search !== '') {
    $where[] = '(p.name LIKE ? OR p.brand LIKE ? OR p.barcode LIKE ? OR p.subcategory LIKE ?)';
    $like = "%{$search}%";
    $params = array_merge($params, [$like, $like, $like, $like]);
}

if ($category !== '') {
    $where[] = 'p.category = ?';
    $params[] = $category;
}

if ($status !== '') {
    $today = date('Y-m-d');
    switch (strtolower($status)) {
        case 'expired':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date < ?';
            $params[] = $today;
            break;
        case 'expiring_today':
        case 'expiringtoday':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date = ?';
            $params[] = $today;
            break;
        case 'expiring_soon':
        case 'expiringsoon':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date >= ? AND p.expiry_date <= DATE_ADD(?, INTERVAL 7 DAY)';
            $params[] = $today;
            $params[] = $today;
            break;
        case 'within_30_days':
        case 'within30days':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date > DATE_ADD(?, INTERVAL 7 DAY) AND p.expiry_date <= DATE_ADD(?, INTERVAL 30 DAY)';
            $params[] = $today;
            $params[] = $today;
            break;
        case 'safe':
            $where[] = 'p.expiry_date IS NOT NULL AND p.expiry_date > DATE_ADD(?, INTERVAL 7 DAY)';
            $params[] = $today;
            break;
        case 'no_expiry':
        case 'noexpiry':
            $where[] = 'p.expiry_date IS NULL';
            break;
    }
}

$whereClause = 'WHERE ' . implode(' AND ', $where);

// Count total
$countStmt = $db->prepare("SELECT COUNT(*) FROM products p {$whereClause}");
$countStmt->execute($params);
$totalProducts = (int)$countStmt->fetchColumn();
$totalPages = max(1, (int)ceil($totalProducts / $limit));

// Fetch paginated products
$sql = "SELECT p.*,
        CASE 
            WHEN p.expiry_date IS NULL THEN NULL 
            ELSE DATEDIFF(p.expiry_date, CURDATE()) 
        END AS days_remaining
        FROM products p
        {$whereClause}
        ORDER BY p.expiry_date IS NULL ASC, p.expiry_date ASC, p.name ASC
        LIMIT {$limit} OFFSET {$offset}";

$stmt = $db->prepare($sql);
$stmt->execute($params);
$products = $stmt->fetchAll();

// Categories for dropdown filter
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

$pageTitle = 'Products & Expiration Tracking';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">Product Inventory & Expiration Tracking</h2>
    <p class="text-muted small mb-0">Monitor expiration timelines, manage product reminders, and update shelf-life details.</p>
  </div>
  <div class="d-flex gap-2">
    <a href="<?= base_url('products/export.php?' . http_build_query(['q' => $search, 'category' => $category, 'status' => $status])) ?>" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
      <span class="material-symbols-rounded fs-5">download</span>
      <span>Export CSV</span>
    </a>
  </div>
</div>

<!-- Filters Card -->
<div class="card-box mb-4">
  <form method="GET" action="" class="row g-3 align-items-end">
    <div class="col-md-4">
      <label class="form-label fw-semibold small">Search Product or Barcode</label>
      <div class="position-relative">
        <input type="text" name="q" value="<?= e($search) ?>" class="form-control ps-5" placeholder="Search by name, brand, barcode...">
        <span class="material-symbols-rounded position-absolute top-50 start-0 translate-middle-y ms-3 text-muted" style="font-size: 20px;">search</span>
      </div>
    </div>

    <div class="col-md-3">
      <label class="form-label fw-semibold small">Category</label>
      <select name="category" class="form-select">
        <option value="">All Categories</option>
        <?php foreach ($categoriesList as $cat): ?>
          <option value="<?= e($cat) ?>" <?= $category === $cat ? 'selected' : '' ?>><?= e($cat) ?></option>
        <?php endforeach; ?>
      </select>
    </div>

    <div class="col-md-3">
      <label class="form-label fw-semibold small">Expiration Status</label>
      <select name="status" class="form-select">
        <option value="">All Statuses</option>
        <option value="expired" <?= $status === 'expired' ? 'selected' : '' ?>>Expired</option>
        <option value="expiring_today" <?= $status === 'expiring_today' ? 'selected' : '' ?>>Expiring Today</option>
        <option value="expiring_soon" <?= $status === 'expiring_soon' ? 'selected' : '' ?>>Expiring Soon (Within 7 Days)</option>
        <option value="within_30_days" <?= $status === 'within_30_days' ? 'selected' : '' ?>>Expiring Within 30 Days</option>
        <option value="safe" <?= $status === 'safe' ? 'selected' : '' ?>>Safe (> 7 Days)</option>
        <option value="no_expiry" <?= $status === 'no_expiry' ? 'selected' : '' ?>>No Expiration Date</option>
      </select>
    </div>

    <div class="col-md-2 d-flex gap-2">
      <button type="submit" class="btn btn-primary-custom flex-grow-1">
        <span>Filter</span>
      </button>
      <?php if ($search !== '' || $category !== '' || $status !== ''): ?>
        <a href="<?= base_url('products/index.php') ?>" class="btn btn-outline-secondary" title="Clear Filters">
          <span class="material-symbols-rounded fs-5">clear</span>
        </a>
      <?php endif; ?>
    </div>
  </form>
</div>

<!-- Products Table Card -->
<div class="card-box">
  <div class="d-flex align-items-center justify-content-between mb-3">
    <div class="text-muted small">
      Showing <strong><?= count($products) ?></strong> of <strong><?= $totalProducts ?></strong> items
    </div>
  </div>

  <?php if (empty($products)): ?>
    <div class="empty-state py-5">
      <div class="empty-icon"><span class="material-symbols-rounded">inventory_2</span></div>
      <div class="empty-title">No products found.</div>
      <p class="empty-text">No products match your current search or filter conditions.</p>
      <?php if ($search !== '' || $category !== '' || $status !== ''): ?>
        <a href="<?= base_url('products/index.php') ?>" class="btn btn-secondary-custom">Reset Filters</a>
      <?php endif; ?>
    </div>
  <?php else: ?>
    <div class="table-responsive">
      <table class="custom-table">
        <thead>
          <tr>
            <th>Product & Brand</th>
            <th>Barcode</th>
            <th>Category</th>
            <th>Quantity</th>
            <th>Expiration Date</th>
            <th>Status & Days</th>
            <th>Reminders</th>
            <th class="text-end">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($products as $p): ?>
            <?php
              $days = $p['days_remaining'] !== null ? (int)$p['days_remaining'] : null;
              $isExpired = $days !== null && $days < 0;
              $isExpiringSoon = $days !== null && $days >= 0 && $days <= 7;
              $isNoExpiry = $p['expiry_date'] === null;
              
              $statusBadgeClass = 'bg-success';
              $statusLabel = 'Safe';
              if ($isNoExpiry) {
                  $statusBadgeClass = 'bg-info text-dark';
                  $statusLabel = 'No Expiry';
              } elseif ($isExpired) {
                  $statusBadgeClass = 'bg-danger';
                  $statusLabel = 'Expired';
              } elseif ($days === 0) {
                  $statusBadgeClass = 'bg-warning text-dark';
                  $statusLabel = 'Expires Today';
              } elseif ($isExpiringSoon) {
                  $statusBadgeClass = 'bg-warning text-dark';
                  $statusLabel = 'Expiring Soon';
              }
            ?>
            <tr>
              <td>
                <div class="d-flex align-items-center gap-2">
                  <?php if (!empty($p['image_path'])): ?>
                    <img src="<?= e($p['image_path']) ?>" alt="<?= e($p['name']) ?>" class="rounded-3" style="width: 38px; height: 38px; object-fit: cover;" onerror="this.style.display='none'">
                  <?php endif; ?>
                  <div>
                    <div class="fw-bold text-dark"><?= e($p['name']) ?></div>
                    <?php if (!empty($p['brand'])): ?>
                      <span class="badge bg-light text-secondary border px-1.5 py-0.5" style="font-size: 10px;">
                        <?= e($p['brand']) ?>
                      </span>
                    <?php endif; ?>
                  </div>
                </div>
              </td>
              <td>
                <?php if (!empty($p['barcode'])): ?>
                  <code class="text-muted small"><?= e($p['barcode']) ?></code>
                <?php else: ?>
                  <span class="text-muted small">—</span>
                <?php endif; ?>
              </td>
              <td>
                <div class="small fw-semibold"><?= e($p['category']) ?></div>
                <?php if (!empty($p['subcategory'])): ?>
                  <div class="text-muted" style="font-size: 11px;"><?= e($p['subcategory']) ?></div>
                <?php endif; ?>
              </td>
              <td>
                <span class="fw-semibold small"><?= (float)$p['quantity'] ?> <?= e($p['unit']) ?></span>
              </td>
              <td>
                <?php if ($p['expiry_date'] !== null): ?>
                  <div class="small fw-bold"><?= format_date($p['expiry_date']) ?></div>
                <?php else: ?>
                  <span class="text-muted small fst-italic">Does not expire</span>
                <?php endif; ?>
              </td>
              <td>
                <span class="badge <?= $statusBadgeClass ?> px-2 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                  <?= $statusLabel ?>
                </span>
                <?php if ($days !== null): ?>
                  <div class="text-muted mt-1" style="font-size: 10.5px;">
                    <?= $days < 0 ? abs($days) . ' days ago' : ($days == 0 ? 'Today' : 'In ' . $days . ' days') ?>
                  </div>
                <?php endif; ?>
              </td>
              <td>
                <?php if ($p['reminder_enabled']): ?>
                  <span class="badge bg-primary-subtle text-primary rounded-pill px-2 py-1 small" style="background: rgba(59, 130, 246, 0.12);">
                    <?= !empty($p['reminder_days_before']) ? e($p['reminder_days_before']) . 'd before' : 'Custom' ?>
                  </span>
                <?php else: ?>
                  <span class="text-muted small">Disabled</span>
                <?php endif; ?>
              </td>
              <td class="text-end">
                <div class="d-flex align-items-center justify-content-end gap-1">
                  <!-- Change Expiration Date Modal Trigger -->
                  <button type="button" class="btn-action-icon text-warning" title="Change Expiration Date" onclick="openExpiryModal('<?= e($p['id']) ?>', '<?= e(addslashes($p['name'])) ?>', '<?= e($p['expiry_date'] ?? '') ?>')">
                    <span class="material-symbols-rounded" style="font-size: 18px;">event</span>
                  </button>

                  <!-- Edit -->
                  <a href="<?= base_url('products/edit.php?id=' . $p['id']) ?>" class="btn-action-icon text-primary" title="Edit Product">
                    <span class="material-symbols-rounded" style="font-size: 18px;">edit</span>
                  </a>

                  <!-- Delete -->
                  <form method="POST" action="<?= base_url('products/delete.php') ?>" onsubmit="return confirm('Are you sure you want to delete \'<?= e(addslashes($p['name'])) ?>\'?');" class="d-inline">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= e($p['id']) ?>">
                    <button type="submit" class="btn-action-icon text-danger" title="Delete Product">
                      <span class="material-symbols-rounded" style="font-size: 18px;">delete</span>
                    </button>
                  </form>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>

    <!-- Pagination Controls -->
    <?php if ($totalPages > 1): ?>
      <div class="d-flex justify-content-between align-items-center mt-3 pt-3 border-top">
        <div class="small text-muted">Page <?= $page ?> of <?= $totalPages ?></div>
        <ul class="pagination pagination-sm mb-0">
          <?php if ($page > 1): ?>
            <li class="page-item">
              <a class="page-link" href="?<?= http_build_query(array_merge($_GET, ['page' => $page - 1])) ?>">Previous</a>
            </li>
          <?php endif; ?>
          <?php for ($i = max(1, $page - 2); $i <= min($totalPages, $page + 2); $i++): ?>
            <li class="page-item <?= $i === $page ? 'active' : '' ?>">
              <a class="page-link" href="?<?= http_build_query(array_merge($_GET, ['page' => $i])) ?>"><?= $i ?></a>
            </li>
          <?php endfor; ?>
          <?php if ($page < $totalPages): ?>
            <li class="page-item">
              <a class="page-link" href="?<?= http_build_query(array_merge($_GET, ['page' => $page + 1])) ?>">Next</a>
            </li>
          <?php endif; ?>
        </ul>
      </div>
    <?php endif; ?>
  <?php endif; ?>
</div>

<!-- Change Expiration Date Modal -->
<div class="modal fade" id="changeExpiryModal" tabindex="-1" aria-labelledby="changeExpiryModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="POST" action="<?= base_url('products/update_expiry.php') ?>">
        <?= csrf_field() ?>
        <input type="hidden" name="id" id="modalProductId">

        <div class="modal-header">
          <h5 class="modal-title fw-bold" id="changeExpiryModalLabel">Change Expiration Date</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          <p class="small text-muted mb-3">Updating expiration date for: <strong id="modalProductName" class="text-dark"></strong></p>
          <div class="mb-3">
            <label class="form-label fw-semibold small">New Expiration Date</label>
            <input type="date" name="expiry_date" id="modalExpiryDate" class="form-control" required>
            <div class="form-text small">Alert reminders will automatically recalculate from this date.</div>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Cancel</button>
          <button type="submit" class="btn btn-primary-custom btn-sm">Update Date</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
function openExpiryModal(id, name, expiryDate) {
  document.getElementById('modalProductId').value = id;
  document.getElementById('modalProductName').textContent = name;
  document.getElementById('modalExpiryDate').value = expiryDate;
  const modal = new bootstrap.Modal(document.getElementById('changeExpiryModal'));
  modal.show();
}
</script>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
