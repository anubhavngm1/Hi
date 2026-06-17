<?php
// api/bookings/my-bookings.php
require_once __DIR__ . '/../base.php';

$auth = get_auth_customer();

$stmt = $pdo->prepare("
    SELECT b.id, b.booking_ref, b.travel_date, b.num_adults, b.num_children,
           b.final_amount, b.payment_status, b.booking_status, b.created_at,
           p.title AS package_title
    FROM bookings b
    JOIN packages p ON p.id = b.package_id
    WHERE b.customer_id = ?
    ORDER BY b.created_at DESC
");
$stmt->execute([$auth['customer_id']]);
$bookings = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'bookings' => $bookings]);
