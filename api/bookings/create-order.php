<?php
// api/bookings/create-order.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth = get_auth_customer();
$body = get_request_body();

$package_id  = (int)($body['package_id']  ?? 0);
$num_adults  = (int)($body['num_adults']  ?? 1);
$num_children = (int)($body['num_children'] ?? 0);
$travel_date = $body['travel_date']  ?? '';
$coupon_code = trim($body['coupon_code'] ?? '');
$amount      = (float)($body['amount']   ?? 0);

if (!$package_id || !$travel_date || $amount <= 0) json_error('Missing required fields');

// Get package
$stmt = $pdo->prepare("SELECT * FROM packages WHERE id = ? AND is_active = 1");
$stmt->execute([$package_id]);
$package = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$package) json_error('Package not found');

// Handle coupon
$coupon_id       = null;
$discount_amount = 0;
if ($coupon_code) {
    $cs = $pdo->prepare("SELECT * FROM coupons WHERE code = ? AND is_active = 1 AND (valid_until IS NULL OR valid_until >= CURDATE())");
    $cs->execute([$coupon_code]);
    $coupon = $cs->fetch(PDO::FETCH_ASSOC);
    if ($coupon) {
        $coupon_id = $coupon['id'];
        $discount_amount = $coupon['discount_type'] === 'percent'
            ? round($amount * $coupon['discount_value'] / 100, 2)
            : min($coupon['discount_value'], $amount);
    }
}

$final_amount = max(0, $amount - $discount_amount);
$booking_ref  = 'EBO' . date('Ymd') . strtoupper(substr(uniqid(), -4));

// Create Razorpay Order
$razorpay_key_id     = defined('RAZORPAY_KEY_ID')     ? RAZORPAY_KEY_ID     : '';
$razorpay_key_secret = defined('RAZORPAY_KEY_SECRET') ? RAZORPAY_KEY_SECRET : '';

$rz_payload = json_encode([
    'amount'   => (int)($final_amount * 100),
    'currency' => 'INR',
    'receipt'  => $booking_ref,
]);

$ch = curl_init('https://api.razorpay.com/v1/orders');
curl_setopt_array($ch, [
    CURLOPT_USERPWD        => "$razorpay_key_id:$razorpay_key_secret",
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => $rz_payload,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
]);
$rz_response = json_decode(curl_exec($ch), true);
curl_close($ch);

if (!isset($rz_response['id'])) json_error('Failed to create payment order');

$razorpay_order_id = $rz_response['id'];

// Insert booking (pending)
$stmt = $pdo->prepare("
    INSERT INTO bookings
    (customer_id, booking_ref, package_id, customer_name, customer_email, customer_phone,
     travel_date, num_adults, num_children, base_amount, coupon_id, discount_amount,
     final_amount, payment_status, booking_status, razorpay_order_id, created_at)
    SELECT ?, ?, ?, c.name, c.email, COALESCE(c.phone,''),
           ?, ?, ?, ?, ?, ?, ?, 'pending', 'pending', ?, NOW()
    FROM customers c WHERE c.id = ?
");
$stmt->execute([
    $auth['customer_id'], $booking_ref, $package_id,
    $travel_date, $num_adults, $num_children,
    $amount, $coupon_id, $discount_amount, $final_amount,
    $razorpay_order_id, $auth['customer_id'],
]);

$booking_id = $pdo->lastInsertId();

json_response([
    'success'           => true,
    'booking_id'        => (int)$booking_id,
    'booking_ref'       => $booking_ref,
    'razorpay_order_id' => $razorpay_order_id,
    'amount'            => $final_amount,
]);
