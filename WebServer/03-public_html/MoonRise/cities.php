<?php
declare(strict_types=1);

require_once __DIR__ . '/database.php';
header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    http_response_code(405);
    header('Allow: GET');
    echo json_encode(['error' => 'Use GET to load cities.']);
    exit;
}

$timezone = $_GET['tz'] ?? null;
if (!zones_valid_timezone($timezone)) {
    http_response_code(400);
    echo json_encode(['error' => 'Select a valid timezone.']);
    exit;
}

try {
    $cities = zones_cities(zones_database(), $timezone);
    echo json_encode(['cities' => $cities], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
} catch (Throwable $error) {
    error_log('Zones cities endpoint: ' . $error->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Unable to load cities. Please try again later.']);
}
