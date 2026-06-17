<?php
// api/packages.php
require_once __DIR__ . '/base.php';

$id          = $_GET['id']          ?? null;
$destination = $_GET['destination'] ?? null;

if ($id) {
    // Single package detail
    $stmt = $pdo->prepare("
        SELECT p.*, d.name AS destination
        FROM packages p
        LEFT JOIN destinations d ON d.id = p.destination_id
        WHERE p.id = ? AND p.is_active = 1
    ");
    $stmt->execute([$id]);
    $package = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$package) json_error('Package not found', 404);
    json_response(['success' => true, 'package' => $package]);
}

// List packages
$sql    = "SELECT p.*, d.name AS destination FROM packages p LEFT JOIN destinations d ON d.id = p.destination_id WHERE p.is_active = 1";
$params = [];

if ($destination) {
    $sql    .= " AND d.name = ?";
    $params[] = $destination;
}

$sql .= " ORDER BY p.created_at DESC";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$packages = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'packages' => $packages]);
