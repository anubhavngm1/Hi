<?php
// api/bookings/verify-activity-payment.php
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
    UPDATE activity_bookings
    SET payment_status = 'paid', booking_status = 'confirmed',
        razorpay_payment_id = ?, updated_at = NOW()
    WHERE id = ? AND customer_id = ?
")->execute([$payment_id, $booking_id, $auth['customer_id']]);

$stmt = $pdo->prepare("
    SELECT ab.*, a.title AS activity_title, c.fcm_token, c.name AS cust_name
    FROM activity_bookings ab
    JOIN activities a ON a.id = ab.activity_id
    JOIN customers c ON c.id = ab.customer_id
    WHERE ab.id = ?
");
$stmt->execute([$booking_id]);
$booking = $stmt->fetch(PDO::FETCH_ASSOC);

if (!empty($booking['fcm_token'])) {
    send_fcm_notification(
        $booking['fcm_token'],
        '🏄 Activity Confirmed!',
        "\"{$booking['activity_title']}\" on {$booking['activity_date']} is confirmed! Ref: {$booking['booking_ref']}",
        ['type' => 'activity_confirmed', 'booking_id' => (string)$booking_id]
    );
}

$admin_fcm = $pdo->query("SELECT value FROM site_settings WHERE key_name = 'admin_fcm_token'")->fetchColumn();
if ($admin_fcm) {
    send_fcm_notification(
        $admin_fcm,
        '🏄 New Activity Booking!',
        "{$booking['cust_name']} booked {$booking['activity_title']} — ₹{$booking['total_amount']}",
        ['type' => 'new_activity_booking', 'booking_id' => (string)$booking_id]
    );
}

json_response(['success' => true, 'booking_ref' => $booking['booking_ref']]);
