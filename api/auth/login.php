<?php
// api/auth/login.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$body  = get_request_body();
$email = trim($body['email'] ?? '');
$pass  = $body['password'] ?? '';

if (!$email || !$pass) json_error('Email and password required');

$stmt = $pdo->prepare("SELECT * FROM customers WHERE email = ?");
$stmt->execute([$email]);
$customer = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$customer || !password_verify($pass, $customer['password'])) {
    json_error('Invalid email or password', 401);
}

// Update FCM token if sent
if (!empty($body['fcm_token'])) {
    $upd = $pdo->prepare("UPDATE customers SET fcm_token = ? WHERE id = ?");
    $upd->execute([$body['fcm_token'], $customer['id']]);
}

// Update last login
$pdo->prepare("UPDATE customers SET last_login = NOW() WHERE id = ?")->execute([$customer['id']]);

$token = create_jwt(['customer_id' => $customer['id'], 'email' => $customer['email']]);

json_response([
    'success'  => true,
    'customer' => [
        'id'            => $customer['id'],
        'name'          => $customer['name'],
        'email'         => $customer['email'],
        'phone'         => $customer['phone'],
        'referral_code' => $customer['referral_code'],
        'token'         => $token,
    ],
]);
