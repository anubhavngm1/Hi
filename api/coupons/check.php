<?php
// api/coupons/check.php
require_once __DIR__ . '/../base.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') json_error('Method not allowed', 405);

$body   = get_request_body();
$code   = strtoupper(trim($body['code']   ?? ''));
$amount = (float)($body['amount'] ?? 0);

if (!$code) json_error('Coupon code required');

$stmt = $pdo->prepare("
    SELECT * FROM coupons
    WHERE code = ? AND is_active = 1
      AND (valid_from IS NULL OR valid_from <= CURDATE())
      AND (valid_until IS NULL OR valid_until >= CURDATE())
      AND (usage_limit IS NULL OR used_count < usage_limit)
");
$stmt->execute([$code]);
$coupon = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$coupon) {
    json_response(['valid' => false, 'message' => 'Invalid or expired coupon']);
}

if ($amount < ($coupon['min_order_amount'] ?? 0)) {
    json_response(['valid' => false, 'message' => 'Minimum order amount not met']);
}

$discount = $coupon['discount_type'] === 'percent'
    ? round($amount * $coupon['discount_value'] / 100, 2)
    : min((float)$coupon['discount_value'], $amount);

json_response([
    'valid'         => true,
    'discount'      => $discount,
    'discount_type' => $coupon['discount_type'],
    'message'       => "Coupon applied! ₹{$discount} discount",
]);
