<?php
// api/bookings/my-hotel-bookings.php
require_once __DIR__ . '/../base.php';

$auth = get_auth_customer();

$stmt = $pdo->prepare("
    SELECT hb.id, hb.booking_ref, hb.check_in, hb.check_out,
           hb.num_rooms, hb.total_amount, hb.payment_status, hb.booking_status,
           h.name AS hotel_name
    FROM hotel_bookings hb
    JOIN hotels h ON h.id = hb.hotel_id
    WHERE hb.customer_id = ?
    ORDER BY hb.created_at DESC
");
$stmt->execute([$auth['customer_id']]);
$bookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'bookings' => $bookings]);
