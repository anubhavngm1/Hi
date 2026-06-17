<?php
// api/bookings/create-hotel-order.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth = get_auth_customer();
$body = get_request_body();

$hotel_id  = (int)($body['hotel_id']  ?? 0);
$room_id   = (int)($body['room_id']   ?? 0);
$check_in  = $body['check_in']  ?? '';
$check_out = $body['check_out'] ?? '';
$num_rooms = (int)($body['num_rooms'] ?? 1);
$amount    = (float)($body['amount']  ?? 0);

if (!$hotel_id || !$room_id || !$check_in || !$check_out || $amount <= 0) json_error('Missing required fields');

// Validate hotel & room
$stmt = $pdo->prepare("SELECT h.*, r.room_type, r.price_per_night FROM hotels h JOIN hotel_rooms r ON r.id = ? WHERE h.id = ?");
$stmt->execute([$room_id, $hotel_id]);
$hotel = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$hotel) json_error('Hotel or room not found');

$booking_ref = 'HBK' . date('Ymd') . strtoupper(substr(uniqid(), -4));

// Razorpay Order
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

// Get customer info
$cust = $pdo->prepare("SELECT name, email, phone FROM customers WHERE id = ?");
$cust->execute([$auth['customer_id']]);
$customer = $cust->fetch(PDO::FETCH_ASSOC);

$nights = (new DateTime($check_in))->diff(new DateTime($check_out))->days;

// Insert hotel booking
$stmt = $pdo->prepare("
    INSERT INTO hotel_bookings
    (customer_id, booking_ref, hotel_id, room_id, customer_name, customer_email, customer_phone,
     check_in, check_out, num_rooms, num_nights, total_amount, payment_status, booking_status,
     razorpay_order_id, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending', ?, NOW())
");
$stmt->execute([
    $auth['customer_id'], $booking_ref, $hotel_id, $room_id,
    $customer['name'], $customer['email'], $customer['phone'] ?? '',
    $check_in, $check_out, $num_rooms, $nights, $amount, $rz['id'],
]);

json_response([
    'success'           => true,
    'booking_id'        => (int)$pdo->lastInsertId(),
    'booking_ref'       => $booking_ref,
    'razorpay_order_id' => $rz['id'],
    'amount'            => $amount,
]);
