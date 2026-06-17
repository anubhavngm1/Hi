<?php
// api/base.php - Include this in every API file

// CORS Headers
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Load config
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/database.php';

// JWT Secret (change this to a random string)
define('JWT_SECRET', 'ebostay_jwt_secret_change_this_2024');

function json_response($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data);
    exit();
}

function json_error($message, $code = 400) {
    json_response(['success' => false, 'message' => $message], $code);
}

function get_request_body() {
    return json_decode(file_get_contents('php://input'), true) ?? [];
}

// Simple JWT
function create_jwt($payload) {
    $header  = base64_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = base64_encode(json_encode($payload));
    $sig     = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    return "$header.$payload.$sig";
}

function verify_jwt($token) {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return false;
    [$header, $payload, $sig] = $parts;
    $expected = base64_encode(hash_hmac('sha256', "$header.$payload", JWT_SECRET, true));
    if (!hash_equals($expected, $sig)) return false;
    return json_decode(base64_decode($payload), true);
}

function get_auth_customer() {
    $headers = getallheaders();
    $auth    = $headers['Authorization'] ?? '';
    if (!$auth || !str_starts_with($auth, 'Bearer ')) {
        json_error('Unauthorized', 401);
    }
    $token = substr($auth, 7);
    $data  = verify_jwt($token);
    if (!$data || !isset($data['customer_id'])) {
        json_error('Invalid token', 401);
    }
    return $data;
}

// FCM Push Notification
function send_fcm_notification($fcm_token, $title, $body, $data = []) {
    $server_key = defined('FCM_SERVER_KEY') ? FCM_SERVER_KEY : '';
    if (!$server_key || !$fcm_token) return;

    $payload = json_encode([
        'to'           => $fcm_token,
        'notification' => ['title' => $title, 'body' => $body, 'sound' => 'default'],
        'data'         => $data,
    ]);

    $ch = curl_init('https://fcm.googleapis.com/fcm/send');
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => $payload,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => [
            'Authorization: key=' . $server_key,
            'Content-Type: application/json',
        ],
    ]);
    curl_exec($ch);
    curl_close($ch);
}
