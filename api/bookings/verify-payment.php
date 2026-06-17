<?php
// api/bookings/verify-payment.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth = get_auth_customer();
$body = get_request_body();

$order_id   = $body['razorpay_order_id']  ?? '';
$payment_id = $body['razorpay_payment_id'] ?? '';
$signature  = $body['razorpay_signature']  ?? '';
$booking_id = (int)($body['booking_id']   ?? 0);

if (!$order_id || !$payment_id || !$signature || !$booking_id) json_error('Missing payment data');

// Verify signature
$razorpay_key_secret = defined('RAZORPAY_KEY_SECRET') ? RAZORPAY_KEY_SECRET : '';
$expected_sig = hash_hmac('sha256', $order_id . '|' . $payment_id, $razorpay_key_secret);

if (!hash_equals($expected_sig, $signature)) json_error('Invalid payment signature', 400);

// Update booking
$stmt = $pdo->prepare("
    UPDATE bookings
    SET payment_status = 'paid', booking_status = 'confirmed',
        razorpay_payment_id = ?, updated_at = NOW()
    WHERE id = ? AND customer_id = ?
");
$stmt->execute([$payment_id, $booking_id, $auth['customer_id']]);

// Get booking details for notification
$stmt = $pdo->prepare("
    SELECT b.*, p.title AS package_title, c.name, c.email, c.fcm_token
    FROM bookings b
    JOIN packages p ON p.id = b.package_id
    JOIN customers c ON c.id = b.customer_id
    WHERE b.id = ?
");
$stmt->execute([$booking_id]);
$booking = $stmt->fetch(PDO::FETCH_ASSOC);

// Send push notification to customer
if (!empty($booking['fcm_token'])) {
    send_fcm_notification(
        $booking['fcm_token'],
        '✅ Booking Confirmed!',
        "Your tour \"{$booking['package_title']}\" is confirmed. Ref: {$booking['booking_ref']}",
        ['type' => 'booking_confirmed', 'booking_id' => (string)$booking_id]
    );
}

// Send notification to admin (optional - store admin FCM token in site_settings)
$admin_fcm = $pdo->query("SELECT value FROM site_settings WHERE key_name = 'admin_fcm_token'")->fetchColumn();
if ($admin_fcm) {
    send_fcm_notification(
        $admin_fcm,
        '🎉 New Booking!',
        "{$booking['name']} booked {$booking['package_title']} - ₹{$booking['final_amount']}",
        ['type' => 'new_booking', 'booking_id' => (string)$booking_id]
    );
}

// TODO: Send confirmation email (use existing email logic)

json_response([
    'success'     => true,
    'booking_ref' => $booking['booking_ref'],
    'message'     => 'Payment verified and booking confirmed',
]);
