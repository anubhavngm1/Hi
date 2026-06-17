<?php
// api/bookings/verify-hotel-payment.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$auth = get_auth_customer();
$body = get_request_body();

$order_id   = $body['razorpay_order_id']  ?? '';
$payment_id = $body['razorpay_payment_id'] ?? '';
$signature  = $body['razorpay_signature']  ?? '';
$booking_id = (int)($body['booking_id']   ?? 0);

if (!$order_id || !$payment_id || !$signature || !$booking_id) json_error('Missing payment data');

$razorpay_key_secret = defined('RAZORPAY_KEY_SECRET') ? RAZORPAY_KEY_SECRET : '';
$expected = hash_hmac('sha256', $order_id . '|' . $payment_id, $razorpay_key_secret);
if (!hash_equals($expected, $signature)) json_error('Invalid signature', 400);

$pdo->prepare("
    UPDATE hotel_bookings
    SET payment_status = 'paid', booking_status = 'confirmed',
        razorpay_payment_id = ?, updated_at = NOW()
    WHERE id = ? AND customer_id = ?
")->execute([$payment_id, $booking_id, $auth['customer_id']]);

// Get booking + FCM
$stmt = $pdo->prepare("
    SELECT hb.*, h.name AS hotel_name, c.fcm_token, c.name AS cust_name
    FROM hotel_bookings hb
    JOIN hotels h ON h.id = hb.hotel_id
    JOIN customers c ON c.id = hb.customer_id
    WHERE hb.id = ?
");
$stmt->execute([$booking_id]);
$booking = $stmt->fetch(PDO::FETCH_ASSOC);

// Push to customer
if (!empty($booking['fcm_token'])) {
    send_fcm_notification(
        $booking['fcm_token'],
        '🏨 Hotel Booking Confirmed!',
        "{$booking['hotel_name']} — Check-in: {$booking['check_in']}. Ref: {$booking['booking_ref']}",
        ['type' => 'hotel_confirmed', 'booking_id' => (string)$booking_id]
    );
}

// Push to admin
$admin_fcm = $pdo->query("SELECT value FROM site_settings WHERE key_name = 'admin_fcm_token'")->fetchColumn();
if ($admin_fcm) {
    send_fcm_notification(
        $admin_fcm,
        '🏨 New Hotel Booking!',
        "{$booking['cust_name']} booked {$booking['hotel_name']} — ₹{$booking['total_amount']}",
        ['type' => 'new_hotel_booking', 'booking_id' => (string)$booking_id]
    );
}

json_response(['success' => true, 'booking_ref' => $booking['booking_ref']]);
