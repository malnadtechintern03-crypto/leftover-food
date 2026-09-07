<?php
/**
 * REST API - Update Reminder Endpoint
 * POST / PUT /api/update-reminder.php
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';

$method = $_SERVER['REQUEST_METHOD'];
if ($method !== 'POST' && $method !== 'PUT') {
    json_response(['status' => 'error', 'message' => 'Method not allowed. Use POST or PUT.'], 405);
}

$raw = file_get_contents('php://input');
$input = !empty($raw) ? json_decode($raw, true) : $_POST;

if (!is_array($input) || empty($input['id'])) {
    json_response(['status' => 'error', 'message' => 'Reminder id is required.'], 400);
}

$id = (int)$input['id'];

try {
    $db = Database::getConnection();

    $stmt = $db->prepare("SELECT * FROM product_reminders WHERE id = ?");
    $stmt->execute([$id]);
    $current = $stmt->fetch();

    if (!$current) {
        json_response(['status' => 'error', 'message' => 'Reminder not found.'], 404);
    }

    $reminderDate = !empty($input['reminder_date']) ? date('Y-m-d H:i:s', strtotime((string)$input['reminder_date'])) : $current['reminder_date'];
    $isSent = isset($input['is_sent']) ? (int)(bool)$input['is_sent'] : (int)$current['is_sent'];
    $isEnabled = isset($input['is_enabled']) ? (int)(bool)$input['is_enabled'] : (int)$current['is_enabled'];

    $upd = $db->prepare("UPDATE product_reminders SET reminder_date = ?, is_sent = ?, is_enabled = ? WHERE id = ?");
    $upd->execute([$reminderDate, $isSent, $isEnabled, $id]);

    json_response([
        'status' => 'success',
        'message' => 'Reminder updated successfully.',
        'data' => [
            'id' => $id,
            'is_sent' => (bool)$isSent,
            'is_enabled' => (bool)$isEnabled,
        ],
    ]);

} catch (Throwable $e) {
    json_response([
        'status' => 'error',
        'message' => 'Failed to update reminder: ' . $e->getMessage(),
    ], 500);
}
