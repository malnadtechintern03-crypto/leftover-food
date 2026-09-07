<?php
/**
 * Announcement Management - List Announcements
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

$db = Database::getConnection();

$stmt = $db->query('
    SELECT * FROM announcements 
    ORDER BY id DESC
');
$announcements = $stmt->fetchAll();

$today = date('Y-m-d');

$pageTitle = 'Announcement Management';
require_once __DIR__ . '/../includes/header.php';
?>

<div class="d-flex flex-column flex-md-row align-items-md-center justify-content-between gap-3 mb-4">
  <div>
    <h2 class="fw-bold mb-1" style="font-size: 20px;">App Announcements</h2>
    <p class="text-muted small mb-0">Publish notices, tips, and inventory reminders to be displayed on mobile devices.</p>
  </div>
  <a href="<?= base_url('announcements/create.php') ?>" class="btn btn-primary-custom align-self-start align-self-md-center">
    <span class="material-symbols-rounded fs-5">add_circle</span>
    <span>Add Announcement</span>
  </a>
</div>

<div class="card-box">
  <?php if (empty($announcements)): ?>
    <div class="empty-state py-5">
      <div class="empty-icon"><span class="material-symbols-rounded">campaign</span></div>
      <div class="empty-title">No data available.</div>
      <p class="empty-text">No announcements have been created yet. Announcements scheduled here can be fetched via API by the Flutter app.</p>
      <a href="<?= base_url('announcements/create.php') ?>" class="btn btn-primary-custom">Add First Announcement</a>
    </div>
  <?php else: ?>
    <div class="table-responsive">
      <table class="custom-table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Message</th>
            <th>Date Window</th>
            <th>Live Status</th>
            <th>Publication</th>
            <th class="text-end" style="width: 120px;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($announcements as $a): 
            $isActive = ($a['status'] === 'published' && $today >= $a['start_date'] && $today <= $a['end_date']);
            $isScheduled = ($a['status'] === 'published' && $today < $a['start_date']);
            $isExpired = ($today > $a['end_date']);
          ?>
            <tr>
              <td>
                <div class="fw-bold text-dark"><?= e($a['title']) ?></div>
                <div class="text-muted" style="font-size: 11px;">Created <?= format_date($a['created_at']) ?></div>
              </td>
              <td>
                <div class="text-muted small" style="max-width: 320px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">
                  <?= e($a['message']) ?>
                </div>
              </td>
              <td class="small">
                <div><strong>Start:</strong> <?= format_date($a['start_date']) ?></div>
                <div><strong>End:</strong> <?= format_date($a['end_date']) ?></div>
              </td>
              <td>
                <?php if ($isActive): ?>
                  <span class="badge bg-success-subtle text-success px-2.5 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                    Active Now
                  </span>
                <?php elseif ($isScheduled): ?>
                  <span class="badge bg-info-subtle text-info px-2.5 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                    Scheduled
                  </span>
                <?php else: ?>
                  <span class="badge bg-secondary-subtle text-muted px-2.5 py-1 rounded-pill fw-bold" style="font-size: 11px;">
                    Expired
                  </span>
                <?php endif; ?>
              </td>
              <td>
                <span class="badge-status <?= e($a['status']) ?>">
                  <?= ucfirst(e($a['status'])) ?>
                </span>
              </td>
              <td class="text-end">
                <div class="d-inline-flex gap-1">
                  <a href="<?= base_url('announcements/edit.php?id=' . $a['id']) ?>" class="btn-action-icon" title="Edit Announcement">
                    <span class="material-symbols-rounded" style="font-size: 16px;">edit</span>
                  </a>
                  <form method="POST" action="<?= base_url('announcements/delete.php') ?>" onsubmit="return confirmDelete('Delete announcement \'<?= e(addslashes($a['title'])) ?>\'?');" class="d-inline">
                    <?= csrf_field() ?>
                    <input type="hidden" name="id" value="<?= $a['id'] ?>">
                    <button type="submit" class="btn-action-icon danger" title="Delete Announcement">
                      <span class="material-symbols-rounded" style="font-size: 16px;">delete</span>
                    </button>
                  </form>
                </div>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
</div>

<?php require_once __DIR__ . '/../includes/footer.php'; ?>
