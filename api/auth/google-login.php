<?php
// api/auth/google-login.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$body      = get_request_body();
$google_id = trim($body['google_id'] ?? '');
$email     = trim($body['email']     ?? '');
$name      = trim($body['name']      ?? '');

if (!$google_id || !$email) json_error('Google ID and email required');

// Check if customer exists by google_id or email
$stmt = $pdo->prepare("SELECT * FROM customers WHERE google_id = ? OR email = ? LIMIT 1");
$stmt->execute([$google_id, $email]);
$customer = $stmt->fetch(PDO::FETCH_ASSOC);

if ($customer) {
    // Update google_id if missing
    if (!$customer['google_id']) {
        $pdo->prepare("UPDATE customers SET google_id = ?, last_login = NOW() WHERE id = ?")
            ->execute([$google_id, $customer['id']]);
    } else {
        $pdo->prepare("UPDATE customers SET last_login = NOW() WHERE id = ?")->execute([$customer['id']]);
    }
} else {
    // New customer
    $ref_code = 'EBO' . strtoupper(substr(md5($email . time()), 0, 6));
    $stmt = $pdo->prepare("INSERT INTO customers (name, email, google_id, referral_code, created_at) VALUES (?, ?, ?, ?, NOW())");
    $stmt->execute([$name, $email, $google_id, $ref_code]);
    $customer = [
        'id'            => (int)$pdo->lastInsertId(),
        'name'          => $name,
        'email'         => $email,
        'phone'         => null,
        'referral_code' => $ref_code,
    ];
}

$token = create_jwt(['customer_id' => $customer['id'], 'email' => $customer['email']]);

json_response([
    'success'  => true,
    'customer' => [
        'id'            => (int)$customer['id'],
        'name'          => $customer['name'],
        'email'         => $customer['email'],
        'phone'         => $customer['phone'] ?? null,
        'referral_code' => $customer['referral_code'] ?? null,
        'token'         => $token,
    ],
]);
