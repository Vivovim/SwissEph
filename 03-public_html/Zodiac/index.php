<?php
declare(strict_types=1);

require_once __DIR__ . '/chart.php';
require_once __DIR__ . '/locations.php';

use ZodiacChart\ChartError;

ini_set('display_errors', '0');
ini_set('session.use_strict_mode', '1');
ini_set('session.use_only_cookies', '1');
session_name('zodiac_chart_session');
session_set_cookie_params([
    'lifetime' => 0, 'path' => '/',
    'secure' => isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
    'httponly' => true, 'samesite' => 'Strict',
]);
header("Content-Security-Policy: default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; object-src 'none'");
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');
header('Permissions-Policy: geolocation=(), camera=(), microphone=()');
header('Cache-Control: no-store');
if (!session_start()) {
    http_response_code(503);
    exit('Unable to start the chart session.');
}
if (!isset($_SESSION['csrf'])) {
    $_SESSION['csrf'] = bin2hex(random_bytes(32));
}
$csrf = $_SESSION['csrf'];
$config = require __DIR__ . '/config.php';

// City names are read-only public data. This endpoint shares the same page's
// security headers; chart POST requests below still require the session token.
if (($_GET['api'] ?? null) === 'cities') {
    header('Content-Type: application/json; charset=UTF-8');
    session_write_close();
    try {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
            header('Allow: GET');
            throw new ChartError(405, 'method_not_allowed', 'Use GET to load cities.');
        }
        $timezone = ZodiacChart\location_timezone($_GET['tz'] ?? null);
        $connection = ZodiacChart\location_database($config);
        $cities = ZodiacChart\location_cities($connection, $timezone);
        echo json_encode(['timezone' => $timezone, 'cities' => $cities], JSON_THROW_ON_ERROR | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
    } catch (ChartError $error) {
        http_response_code($error->status);
        echo json_encode(['error' => ['code' => $error->errorCode, 'message' => $error->getMessage()]]);
    } catch (Throwable $error) {
        error_log('Zodiac city lookup: ' . get_class($error));
        http_response_code(503);
        echo json_encode(['error' => ['code' => 'location_unavailable', 'message' => 'Unable to load cities. Please try again later.']]);
    }
    exit;
}

if (isset($_GET['api'])) {
    header('Content-Type: application/json; charset=UTF-8');
    $operation = 'input validation';
    try {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            header('Allow: POST');
            throw new ChartError(405, 'method_not_allowed', 'Use POST for chart calculations.');
        }
        $supplied = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? '';
        if (!is_string($supplied) || !hash_equals($csrf, $supplied)) {
            throw new ChartError(403, 'forbidden', 'The chart session has expired. Reload this page.');
        }
        if (!preg_match('/\Aapplication\/json(?:\s*;\s*charset\s*=\s*(?:utf-8|"utf-8"))?\s*\z/i', $_SERVER['CONTENT_TYPE'] ?? '')) {
            throw new ChartError(415, 'unsupported_media_type', 'Send a JSON request.');
        }
        $length = $_SERVER['CONTENT_LENGTH'] ?? '';
        if (!preg_match('/\A[0-9]{1,8}\z/', $length) || (int) $length > 8192) {
            throw new ChartError(413, 'payload_too_large', 'The chart request is too large or has no valid length.');
        }
        $now = microtime(true);
        $recent = array_values(array_filter($_SESSION['requests'] ?? [], static function ($time) use ($now) { return $time > $now - 60; }));
        if (count($recent) >= 20) {
            header('Retry-After: 60');
            throw new ChartError(429, 'rate_limited', 'Too many chart requests. Wait a minute and try again.');
        }
        $recent[] = $now;
        $_SESSION['requests'] = $recent;
        session_write_close();
        $body = file_get_contents('php://input', false, null, 0, 8193);
        if ($body === false || strlen($body) !== (int) $length) {
            throw new ChartError(400, 'invalid_input', 'Incomplete request body.');
        }
        try {
            $input = json_decode($body, false, 4, JSON_THROW_ON_ERROR);
        } catch (JsonException $error) {
            throw new ChartError(400, 'invalid_input', 'Send a valid JSON object.');
        }
        if (!$input instanceof stdClass) {
            throw new ChartError(400, 'invalid_input', 'Send a JSON object.');
        }
        $operation = 'location database';
        $connection = ZodiacChart\location_database($config);
        $selection = ZodiacChart\city_chart_request(get_object_vars($input), $connection);
        $operation = 'CGI';
        $result = ZodiacChart\request_cgi($selection['request'], $config);
        $result['location'] = $selection['location'];
        echo json_encode($result, JSON_THROW_ON_ERROR | JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT);
    } catch (ChartError $error) {
        http_response_code($error->status);
        echo json_encode(['error' => ['code' => $error->errorCode, 'message' => $error->getMessage()]]);
    } catch (Throwable $error) {
        // Database exception messages can contain usernames/hosts. CGI diagnostics
        // are bounded by the transport helper and do not include the shared token.
        error_log('Zodiac chart (' . $operation . '): ' . get_class($error)
            . ($operation === 'CGI' ? ' ' . substr($error->getMessage(), 0, 240) : ''));
        http_response_code($operation === 'location database' ? 503 : 502);
        echo json_encode(['error' => ['code' => 'service_unavailable', 'message' => 'The chart service is unavailable. Please try again later.']]);
    }
    if (session_status() === PHP_SESSION_ACTIVE) {
        session_write_close();
    }
    exit;
}
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') !== 'GET') {
    session_write_close();
    header('Allow: GET');
    http_response_code(405);
    exit('Use GET to open the chart page.');
}
session_write_close();
header('Content-Type: text/html; charset=UTF-8');
$zones = [];
$databaseReady = false;
$locationError = '';
try {
    $connection = ZodiacChart\location_database($config);
    $zones = ZodiacChart\location_timezones($connection);
    $databaseReady = count($zones) > 0;
    if (!$databaseReady) {
        $locationError = 'No supported timezones are available in the city database.';
    }
} catch (Throwable $error) {
    // Database diagnostics can contain usernames/hosts; keep them out of responses and logs.
    error_log('Zodiac location database: ' . get_class($error));
    http_response_code(503);
    $locationError = 'Unable to load location data. Please try again later.';
}
$preferredZone = $config['default_timezone'] ?? 'America/Phoenix';
$defaultZone = in_array($preferredZone, $zones, true) ? $preferredZone : ($zones[0] ?? 'UTC');
$defaultCityId = $config['default_city_id'] ?? '';
$now = new DateTimeImmutable('now', new DateTimeZone($defaultZone));
$e = 'ZodiacChart\\escape';
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="<?= $e($csrf) ?>">
    <title>Zodiac ruler</title>
    <link rel="icon" type="image/svg+xml" href="favicon.svg">
    <link rel="stylesheet" href="zodiac-chart.css">
    <script src="zodiac-chart.js" defer></script>
</head>
<body>
<main>
    <header class="page-header">
        <p class="eyebrow">THE SKY, ALONG ONE LINE</p>
        <h1>Zodiac ruler<span class="header-star" aria-hidden="true">✧</span></h1>
        <p class="intro">Zodiac above. Houses below. The planets in between.</p>
    </header>
    <form id="chart-form" class="controls">
        <div class="control-heading"><h2>Choose your sky</h2><label class="live-toggle"><input id="live" type="checkbox" checked> Live now <span class="live-dot" aria-hidden="true"></span></label></div>
        <div class="control-grid">
            <label class="timezone-field">Timezone<select id="timezone" name="timezone" required<?= !$databaseReady ? ' disabled' : '' ?>>
                <?php if (!$databaseReady): ?><option value="">Location data unavailable</option><?php endif; ?>
                <?php foreach ($zones as $zone): ?><option value="<?= $e($zone) ?>"<?= $zone === $defaultZone ? ' selected' : '' ?>><?= $e($zone) ?></option><?php endforeach; ?>
            </select></label>
            <label class="city-field">City<select id="city" name="city_id" required disabled data-default-city="<?= $e(is_string($defaultCityId) || is_int($defaultCityId) ? (string) $defaultCityId : '') ?>" aria-describedby="city-status"><option value="">Select a timezone first</option></select></label>
            <label>Date<input id="date" name="date" type="date" min="0001-01-01" max="9999-12-31" required disabled value="<?= $e($now->format('Y-m-d')) ?>"></label>
            <label>Local time<input id="time" name="time" type="time" step="1" required disabled value="<?= $e($now->format('H:i:s')) ?>"></label>
            <label>Houses<select id="house-system" name="house_system"><option value="E">Equal</option><option value="P">Placidus</option><option value="W">Whole sign</option></select></label>
            <button id="update-button" type="submit" disabled>Update chart <span aria-hidden="true">↗</span></button>
        </div>
        <div id="fold-control" hidden><label>Repeated local hour<select id="fold" name="fold"><option value="">Choose an occurrence</option><option value="earlier">First occurrence</option><option value="later">Second occurrence</option></select></label></div>
        <p id="city-status" class="control-note" role="status" aria-live="polite"><?= $e($locationError) ?></p>
        <p id="location-details" class="control-note">Coordinates will load from the selected city. Live mode refreshes every minute.</p>
    </form>
    <p id="status" class="status<?= !$databaseReady ? ' error' : '' ?>" role="status" aria-live="polite"><?= $e($locationError !== '' ? $locationError : 'Choose a city to draw its sky.') ?></p>
    <section class="chart-panel" aria-label="Zodiac ruler chart">
        <div class="chart-heading"><h2>The ecliptic</h2><p id="chart-meta">A complete 360° view</p></div>
        <div id="chart-scroll" class="chart-scroll" tabindex="0" aria-label="Scroll horizontally to explore the ruler on a small screen">
            <svg id="zodiac-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1264 450" role="img" aria-labelledby="svg-title svg-description"><title id="svg-title">Zodiac ruler</title><desc id="svg-description">Planetary positions between zodiac signs and houses. Data is loading.</desc></svg>
        </div>
        <div class="chart-footnote"><span>0°–360° absolute ecliptic longitude</span><span id="origin-note">The left edge begins at house 1.</span></div>
    </section>
    <section class="positions-panel">
        <div class="chart-heading"><h2>Planet positions</h2><p>Tropical zodiac · geocentric</p></div>
        <div class="table-scroll"><table><caption class="sr-only">Exact absolute ecliptic longitudes of the planets</caption><thead><tr><th scope="col">Body</th><th scope="col">Absolute longitude</th><th scope="col">Sign</th><th scope="col">House</th><th scope="col">Motion</th></tr></thead><tbody id="planet-rows"></tbody></table></div>
        <p id="earth-note" class="earth-note">Earth’s heliocentric position is shown separately because Earth is the origin of the geocentric chart.</p>
    </section>
    <footer>Calculated with Swiss Ephemeris. <span id="utc-note"></span></footer>
    <noscript><p class="status error">Enable JavaScript to draw the SVG chart.</p></noscript>
</main>
</body>
</html>
