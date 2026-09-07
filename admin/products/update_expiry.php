<?php
/**
 * Admin Panel - Quick Update Expiration Date Action
 */

declare(strict_types=1);

require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/functions.php';

require_admin();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ' . base_url('products/index.php'));
    exit;
}

if (!verify_csrf()) {
    set_flash('error', 'Security token invalid or expired. Please try again.');
    header('Location: ' . base_url('products/index.php'));
    exit;
}

$id = trim($_POST['id'] ?? '');
$expiryDateRaw = trim($_POST['expiry_date'] ?? '');

if ($id === '') {
    set_flash('error', 'Invalid product identifier.');
    header('Location: ' . base_url('products/index.php'));
    exit;
}

$db = Database::getConnection();

try {
    $expiryDate = $expiryDateRaw !== '' ? date('Y-m-d', strtotime($expiryDateRaw)) : null;

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

    $stmt = $db->prepare('UPDATE products SET expiry_date = ?, expiry_status = ? WHERE id = ?');
    $stmt->execute([$expiryDate, $expiryStatus, $id]);

    // Reschedule reminders for this product
    $db->prepare('DELETE FROM product_reminders WHERE product_id = ?')->execute([$id]);

    if ($expiryDate !== null) {
        $prodStmt = $db->prepare('SELECT * FROM products WHERE id = ?');
        $prodStmt->execute([$id]);
        $prod = $prodStmt->fetch();

        if ($prod && $prod['reminder_enabled']) {
            $notificationId = (int)$prod['notification_id'];
            $userId = $prod['user_id'];
            $daysList = array_filter(array_map('trim', explode(',', $prod['reminder_days_before'] ?? '7')), fn($v) => is_numeric($v));

            $insRem = $db->prepare("INSERT INTO product_reminders (
                user_id, product_id, reminder_date, days_before_expiry, notification_id, is_sent, is_enabled
            ) VALUES (?, ?, ?, ?, ?, 0, 1)");

            foreach ($daysList as $d) {
                $daysInt = (int)$d;
                $remTime = date('Y-m-d 09:00:00', strtotime("{$expiryDate} -{$daysInt} days"));
                $notifSubId = abs(($notificationId * 31 + $daysInt) % 100000000);
                $insRem->execute([$userId, $id, $remTime, $daysInt, $notifSubId]);
            }
        }
    }

    set_flash('success', 'Expiration date updated successfully.');
} catch (Throwable $e) {
    set_flash('error', 'Failed to update expiration date: ' . $e->getMessage());
}

header('Location: ' . base_url('products/index.php'));
exit;
