<?php
// api/auth/save-fcm-token.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth      = get_auth_customer();
$body      = get_request_body();
$fcm_token = trim($body['fcm_token'] ?? '');

if (!$fcm_token) json_error('FCM token required');

// Add fcm_token column if not exists (run once)
// ALTER TABLE customers ADD COLUMN fcm_token VARCHAR(255) DEFAULT NULL;

$stmt = $pdo->prepare("UPDATE customers SET fcm_token = ? WHERE id = ?");
$stmt->execute([$fcm_token, $auth['customer_id']]);

json_response(['success' => true]);
