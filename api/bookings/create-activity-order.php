<?php
// api/bookings/create-activity-order.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth = get_auth_customer();
$body = get_request_body();

$activity_id   = (int)($body['activity_id']   ?? 0);
$num_persons   = (int)($body['num_persons']   ?? 1);
$activity_date = $body['activity_date'] ?? '';
$amount        = (float)($body['amount'] ?? 0);

if (!$activity_id || !$activity_date || $amount <= 0) json_error('Missing required fields');

$stmt = $pdo->prepare("SELECT * FROM activities WHERE id = ? AND is_active = 1");
$stmt->execute([$activity_id]);
$activity = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$activity) json_error('Activity not found');

$booking_ref = 'ACT' . date('Ymd') . strtoupper(substr(uniqid(), -4));

$razorpay_key_id     = defined('RAZORPAY_KEY_ID')     ? RAZORPAY_KEY_ID     : '';
$razorpay_key_secret = defined('RAZORPAY_KEY_SECRET') ? RAZORPAY_KEY_SECRET : '';

$ch = curl_init('https://api.razorpay.com/v1/orders');
curl_setopt_array($ch, [
    CURLOPT_USERPWD        => "$razorpay_key_id:$razorpay_key_secret",
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode(['amount' => (int)($amount * 100), 'currency' => 'INR', 'receipt' => $booking_ref]),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
]);
$rz = json_decode(curl_exec($ch), true);
curl_close($ch);
if (!isset($rz['id'])) json_error('Failed to create payment order');

$cust = $pdo->prepare("SELECT name, email, phone FROM customers WHERE id = ?");
$cust->execute([$auth['customer_id']]);
$customer = $cust->fetch(PDO::FETCH_ASSOC);

// Insert activity booking
$stmt = $pdo->prepare("
    INSERT INTO activity_bookings
    (customer_id, booking_ref, activity_id, customer_name, customer_email, customer_phone,
     activity_date, num_persons, total_amount, payment_status, booking_status, razorpay_order_id, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending', ?, NOW())
");
$stmt->execute([
    $auth['customer_id'], $booking_ref, $activity_id,
    $customer['name'], $customer['email'], $customer['phone'] ?? '',
    $activity_date, $num_persons, $amount, $rz['id'],
]);

json_response([
    'success'           => true,
    'booking_id'        => (int)$pdo->lastInsertId(),
    'booking_ref'       => $booking_ref,
    'razorpay_order_id' => $rz['id'],
    'amount'            => $amount,
]);
