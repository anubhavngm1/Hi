<?php
// api/activities.php
require_once __DIR__ . '/base.php';

$id       = $_GET['id']       ?? null;
$category = $_GET['category'] ?? null;

if ($id) {
    $stmt = $pdo->prepare("SELECT * FROM activities WHERE id = ? AND is_active = 1");
    $stmt->execute([$id]);
    $activity = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$activity) json_error('Activity not found', 404);
    json_response(['success' => true, 'activity' => $activity]);
}

$sql    = "SELECT * FROM activities WHERE is_active = 1";
$params = [];

if ($category) {
    $sql    .= " AND category = ?";
    $params[] = $category;
}

$sql .= " ORDER BY created_at DESC";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$activities = $stmt->fetchAll(PDO::FETCH_ASSOC);

json_response(['success' => true, 'activities' => $activities]);
