<?php
// api/auth/register.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$body  = get_request_body();
$name  = trim($body['name']  ?? '');
$email = trim($body['email'] ?? '');
$pass  = $body['password']   ?? '';
$phone = trim($body['phone'] ?? '');

if (!$name || !$email || !$pass) json_error('Name, email, and password required');
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('Invalid email');
if (strlen($pass) < 6) json_error('Password must be at least 6 characters');

// Check existing
$stmt = $pdo->prepare("SELECT id FROM customers WHERE email = ?");
$stmt->execute([$email]);
if ($stmt->fetch()) json_error('Email already registered');

// Generate referral code
$ref_code = 'EBO' . strtoupper(substr(md5($email . time()), 0, 6));

$stmt = $pdo->prepare("INSERT INTO customers (name, email, password, phone, referral_code, created_at) VALUES (?, ?, ?, ?, ?, NOW())");
$stmt->execute([$name, $email, password_hash($pass, PASSWORD_DEFAULT), $phone ?: null, $ref_code]);
$customer_id = $pdo->lastInsertId();

$token = create_jwt(['customer_id' => $customer_id, 'email' => $email]);

json_response([
    'success'  => true,
    'customer' => [
        'id'            => (int)$customer_id,
        'name'          => $name,
        'email'         => $email,
        'phone'         => $phone ?: null,
        'referral_code' => $ref_code,
        'token'         => $token,
    ],
], 201);
