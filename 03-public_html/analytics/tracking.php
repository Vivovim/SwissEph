<?php
declare(strict_types=1);

// Configuration: use a dedicated MySQL account with INSERT permission only.
// Keep this file private in source control once real credentials are entered.
$config = [
    'mysql' => [
        'host' => 'localhost',
        'port' => 3306,
        'database' => '__DATABASE__',
        'username' => '__USERNAME__',
        'password' => '__PASSWORD__',
    ],
    // Exact origins: scheme + hostname + optional port, with no trailing slash.
    'allowed_origins' => [
        'https://www.example.com',
    ],
    'max_body_bytes' => 32768,
];

// Never expose SQL, credentials, or submitted values in HTTP error responses.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
error_reporting(E_ALL);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('Vary: Origin');

function respond(int $status, ?string $error = null): never
{
    http_response_code($status);
    if ($error !== null) {
        echo json_encode(['error' => $error], JSON_THROW_ON_ERROR);
    }
    exit;
}

function textField(array $data, string $key, int $maxBytes, bool $allowEmpty = false): string
{
    $value = $data[$key];
    if (!is_string($value) || strlen($value) > $maxBytes
        || (!$allowEmpty && $value === '')
        || preg_match('/[\x00-\x1F\x7F]/u', $value)) {
        respond(422, 'Invalid field: ' . $key);
    }
    return $value;
}

function integerField(array $data, string $key, int $min, int $max): int
{
    $value = $data[$key];
    if (!is_int($value) || $value < $min || $value > $max) {
        respond(422, 'Invalid field: ' . $key);
    }
    return $value;
}

function httpUrlParts(string $value, string $key): array
{
    $parts = parse_url($value);
    if (filter_var($value, FILTER_VALIDATE_URL) === false || $parts === false
        || !isset($parts['scheme'], $parts['host'])
        || !in_array(strtolower($parts['scheme']), ['http', 'https'], true)
        || isset($parts['user']) || isset($parts['pass'])
        || str_contains($value, '\\')) {
        respond(422, 'Invalid field: ' . $key);
    }
    return $parts;
}

try {
    $method = $_SERVER['REQUEST_METHOD'] ?? '';
    if (!in_array($method, ['POST', 'OPTIONS'], true)) {
        header('Allow: POST, OPTIONS');
        respond(405, 'Only POST and OPTIONS are supported.');
    }

    // Origin checking limits browser submissions. It is not authentication:
    // non-browser clients can forge this header. Apply rate limits at the server.
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    if (!in_array($origin, $config['allowed_origins'], true)) {
        respond(403, 'Origin is not allowed.');
    }
    header('Access-Control-Allow-Origin: ' . $origin);

    if ($method === 'OPTIONS') {
        if (($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD'] ?? '') !== 'POST') {
            respond(403, 'Requested method is not allowed.');
        }
        $requestedHeaders = strtolower($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'] ?? '');
        foreach (explode(',', $requestedHeaders) as $requestedHeader) {
            if (!in_array(trim($requestedHeader), ['', 'content-type'], true)) {
                respond(403, 'Requested header is not allowed.');
            }
        }
        header('Access-Control-Allow-Methods: POST');
        header('Access-Control-Allow-Headers: Content-Type');
        header('Access-Control-Max-Age: 600');
        respond(204);
    }

    $contentType = strtolower(trim(explode(';', $_SERVER['CONTENT_TYPE'] ?? '', 2)[0]));
    if ($contentType !== 'application/json') {
        respond(415, 'Content-Type must be application/json.');
    }
    if (isset($_SERVER['HTTP_CONTENT_ENCODING'])
        && strtolower(trim($_SERVER['HTTP_CONTENT_ENCODING'])) !== 'identity') {
        respond(415, 'Encoded request bodies are not supported.');
    }

    // Bound the actual read, even when Content-Length is absent or misleading.
    if (isset($_SERVER['CONTENT_LENGTH'])
        && (float) $_SERVER['CONTENT_LENGTH'] > $config['max_body_bytes']) {
        respond(413, 'Request body is too large.');
    }
    $raw = file_get_contents('php://input', false, null, 0, $config['max_body_bytes'] + 1);
    if ($raw === false) {
        respond(400, 'Could not read request body.');
    }
    if (strlen($raw) > $config['max_body_bytes']) {
        respond(413, 'Request body is too large.');
    }
    try {
        $decoded = json_decode($raw, false, 8, JSON_THROW_ON_ERROR);
    } catch (JsonException $exception) {
        respond(400, 'Invalid JSON object.');
    }
    if (!$decoded instanceof stdClass) {
        respond(400, 'Request body must be a JSON object.');
    }
    $data = get_object_vars($decoded);
    $fields = [
        'url', 'path', 'title', 'referrer', 'screen_width', 'screen_height',
        'viewport_width', 'viewport_height', 'pixel_ratio', 'language', 'ts',
    ];
    if (array_diff($fields, array_keys($data)) || array_diff(array_keys($data), $fields)) {
        respond(422, 'Request must contain exactly the supported analytics fields.');
    }

    $url = textField($data, 'url', 8192);
    $path = textField($data, 'path', 4096);
    $title = textField($data, 'title', 1024, true);
    $referrer = textField($data, 'referrer', 8192, true);
    $language = textField($data, 'language', 64, true);
    $parts = httpUrlParts($url, 'url');
    $scheme = strtolower($parts['scheme']);
    $urlOrigin = $scheme . '://' . strtolower($parts['host']);
    $port = $parts['port'] ?? ($scheme === 'https' ? 443 : 80);
    if ($port !== ($scheme === 'https' ? 443 : 80)) {
        $urlOrigin .= ':' . $port;
    }
    if ($urlOrigin !== $origin) {
        respond(422, 'URL must belong to the requesting origin.');
    }
    if ($path !== ($parts['path'] ?? '/')) {
        respond(422, 'Path must match the URL pathname.');
    }
    if ($referrer !== '') {
        httpUrlParts($referrer, 'referrer');
    }
    if ($language !== '' && !preg_match('/\A[A-Za-z]{1,8}(?:-[A-Za-z0-9]{1,8})*\z/', $language)) {
        respond(422, 'Invalid field: language');
    }

    $screenWidth = integerField($data, 'screen_width', 0, 65535);
    $screenHeight = integerField($data, 'screen_height', 0, 65535);
    $viewportWidth = integerField($data, 'viewport_width', 0, 65535);
    $viewportHeight = integerField($data, 'viewport_height', 0, 65535);
    $pixelRatio = $data['pixel_ratio'];
    if ((!is_int($pixelRatio) && !is_float($pixelRatio))
        || !is_finite((float) $pixelRatio) || $pixelRatio <= 0 || $pixelRatio > 100) {
        respond(422, 'Invalid field: pixel_ratio');
    }
    // JavaScript milliseconds; require 64-bit PHP. Server receipt time is separate.
    $timestamp = integerField($data, 'ts', 0, 8640000000000000);

    if ($config['mysql']['password'] === 'CHANGE_ME') {
        respond(503, 'Analytics storage is not configured.');
    }

    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    $db = mysqli_init();
    $db->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
    $db->real_connect(
        $config['mysql']['host'],
        $config['mysql']['username'],
        $config['mysql']['password'],
        $config['mysql']['database'],
        $config['mysql']['port']
    );
    $db->set_charset('utf8mb4');

    // No submitted values or configurable identifiers are interpolated into SQL.
    $statement = $db->prepare(
        'INSERT INTO analytics_pageviews
            (site_origin, url, path, title, referrer, screen_width, screen_height,
             viewport_width, viewport_height, pixel_ratio, language, client_ts_ms, received_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(3))'
    );
    $statement->bind_param(
        'sssssiiiidsi',
        $origin, $url, $path, $title, $referrer,
        $screenWidth, $screenHeight, $viewportWidth, $viewportHeight,
        $pixelRatio, $language, $timestamp
    );
    $statement->execute();
    $statement->close();
    $db->close();
    respond(204);
} catch (Throwable $exception) {
    // Do not log exception messages: they may contain credentials or visitor data.
    error_log('[Analytics] Request failed (' . get_class($exception) . ', code '
        . (int) $exception->getCode() . ').');
    respond(503, 'Analytics storage is temporarily unavailable.');
}
