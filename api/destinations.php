<?php
// api/destinations.php
require_once __DIR__ . '/base.php';

$stmt = $pdo->query("SELECT id, name, image FROM destinations WHERE is_active = 1 ORDER BY name ASC");
$destinations = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'destinations' => $destinations]);
