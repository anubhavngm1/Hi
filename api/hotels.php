<?php
// api/hotels.php
require_once __DIR__ . '/base.php';

$id     = $_GET['id']     ?? null;
$city   = $_GET['city']   ?? null;
$action = $_GET['action'] ?? null;

// Rooms list for a hotel
if ($action === 'rooms') {
    $hotel_id = $_GET['hotel_id'] ?? null;
    if (!$hotel_id) json_error('hotel_id required');

    $stmt = $pdo->prepare("SELECT * FROM hotel_rooms WHERE hotel_id = ? AND is_active = 1 ORDER BY price_per_night ASC");
    $stmt->execute([$hotel_id]);
    $rooms = $stmt->fetchAll(PDO::FETCH_ASSOC);
    json_response(['success' => true, 'rooms' => $rooms]);
}

// Check availability via POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $body     = get_request_body();
    $act      = $body['action'] ?? '';
    $room_id  = $body['room_id']  ?? null;
    $check_in  = $body['check_in']  ?? null;
    $check_out = $body['check_out'] ?? null;

    if ($act === 'check_availability') {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) FROM hotel_room_availability
            WHERE room_id = ? AND date BETWEEN ? AND ?
            AND is_available = 0
        ");
        $stmt->execute([$room_id, $check_in, $check_out]);
        $blocked = $stmt->fetchColumn();
        json_response(['success' => true, 'available' => $blocked == 0]);
    }
}

// Single hotel
if ($id) {
    $stmt = $pdo->prepare("SELECT * FROM hotels WHERE id = ? AND is_active = 1");
    $stmt->execute([$id]);
    $hotel = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$hotel) json_error('Hotel not found', 404);

    // Get images
    $img_stmt = $pdo->prepare("SELECT image_path FROM hotel_images WHERE hotel_id = ? ORDER BY sort_order ASC");
    $img_stmt->execute([$id]);
    $hotel['images'] = $img_stmt->fetchAll(PDO::FETCH_COLUMN);

    json_response(['success' => true, 'hotel' => $hotel]);
}

// List hotels
$sql    = "SELECT * FROM hotels WHERE is_active = 1";
$params = [];

if ($city) {
    $sql    .= " AND (city LIKE ? OR location LIKE ?)";
    $params[] = "%$city%";
    $params[] = "%$city%";
}

$sql .= " ORDER BY star_rating DESC, name ASC";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$hotels = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'hotels' => $hotels]);
