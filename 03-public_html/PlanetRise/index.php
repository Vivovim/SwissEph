<?php
declare(strict_types=1);

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/planetrise.php';
$siteConfig = ['site_include_path' => '/home/misfitx/astro/BoxINC/'];
try {
    $siteConfig = require __DIR__ . '/config.php';
} catch (Throwable $exception) {
    error_log('PlanetRise configuration: ' . $exception->getMessage());
    // The database error below is displayed using the normal page layout.
}
set_include_path($siteConfig['site_include_path'] . PATH_SEPARATOR . get_include_path());

header('Content-Type: text/html; charset=UTF-8');
header('Cache-Control: no-store');

// Use the site's session so timezone.php can restore the remembered TZ.
if (session_status() !== PHP_SESSION_ACTIVE) {
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    session_set_cookie_params([
        'path' => '/',
        'secure' => strtolower((string) ($_SERVER['HTTPS'] ?? '')) === 'on'
            || ($_SERVER['HTTPS'] ?? '') === '1' || (string) ($_SERVER['SERVER_PORT'] ?? '') === '443',
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    if (!session_start()) {
        http_response_code(500);
        exit('Unable to start the location lookup session.');
    }
}

if (!function_exists('sanity_Check_1')) {
    function sanity_Check_1($value): string
    {
        if (!is_string($value)) {
            throw new InvalidArgumentException('Invalid timezone value.');
        }
        return htmlentities(strip_tags($value), ENT_QUOTES, 'UTF-8');
    }
}
$timezoneInclude = stream_resolve_include_path('timezone.php');
if ($timezoneInclude !== false) { require $timezoneInclude; }
$savedTimezone = is_string($TimeZone1 ?? null) ? $TimeZone1 : ($_SESSION['planet_rise_timezone'] ?? '');

if (!isset($_SESSION['planet_rise_csrf_token'])) {
    $_SESSION['planet_rise_csrf_token'] = bin2hex(random_bytes(32));
}
$csrfToken = $_SESSION['planet_rise_csrf_token'];
// Release the session lock after validating selections, before the CGI request.

$timezones = [];
$cities = [];
$timezone = '';
$cityId = '';
$selectedDate = '';
$selectedCity = null;
$planetEvents = null;
$planetError = '';
$error = '';
$databaseReady = false;
$submitted = ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'POST';

try {
    $connection = zones_database();
    $timezones = zones_timezones($connection);
    $databaseReady = true;

    if ($submitted) {
        $requestedTimezone = $_POST['tz'] ?? null;
        $requestedId = $_POST['city_id'] ?? null;
        $postedToken = $_POST['csrf_token'] ?? null;
        $requestedDate = $_POST['date'] ?? '';
        if (is_string($requestedDate)) { $selectedDate = $requestedDate; }

        if (!is_string($postedToken) || !hash_equals($csrfToken, $postedToken)) {
            http_response_code(403);
            $error = 'Your form session expired. Please select your timezone and city again.';
        } elseif (!is_string($requestedDate) || ($requestedDate !== '' && !AstroPlanetrise\valid_date($requestedDate))) {
            http_response_code(400);
            $error = 'Choose a valid calendar date.';
        } elseif (!zones_valid_timezone($requestedTimezone) || !in_array($requestedTimezone, $timezones, true)) {
            http_response_code(400);
            $error = 'Choose a timezone from the list.';
        } else {
            $timezone = $requestedTimezone;
            $cities = zones_cities($connection, $timezone);

            if ($requestedId === '' || $requestedId === null) {
                // Initial timezone-only submission loads the city choices.
            } elseif (!is_string($requestedId) || !preg_match('/\A[1-9][0-9]{0,9}\z/', $requestedId)
                || (float) $requestedId > 4294967295) {
                http_response_code(400);
                $error = 'Choose a city from the list.';
            } else {
                $selectedCity = zones_city($connection, $timezone, $requestedId);
                if ($selectedCity === null) {
                    http_response_code(400);
                    $error = 'That city does not belong to the selected timezone. Choose a city from the list.';
                } else {
                    $cityId = (string) $selectedCity['id'];
                    $_SESSION['planet_rise_timezone'] = $timezone;
                }
            }
        }
    }
} catch (Throwable $exception) {
    error_log('PlanetRise page: ' . $exception->getMessage());
    http_response_code(500);
    $databaseReady = false;
    $selectedCity = null;
    $error = 'Unable to load location data. Please try again later.';
} finally {
    if (isset($connection) && $connection instanceof mysqli) {
        $connection->close();
    }
}

session_write_close();

if ($selectedCity !== null) {
    try {
        $planetEvents = AstroPlanetrise\fetch_events($selectedCity, $timezone, $selectedDate === '' ? null : $selectedDate, $siteConfig);
    } catch (Throwable $exception) {
        error_log('PlanetRise lookup: ' . $exception->getMessage());
        http_response_code(502);
        $planetError = 'Unable to load planet rise times right now. Please try again later.';
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Planet rise times by city</title>
    
    
<link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
<link href="https://astro.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css">
<link href="https://astro.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
<script src="https://astro.ctopher.me/js/jquery-3.5.1.min.js"></script> 
<script src="https://astro.ctopher.me/js/bootstrap.min.js"></script> 

    
    
    
    
    <style>
       
        main { max-width: 640px; margin: 3rem auto; padding: 2rem; background: white; border-radius: 12px; }
        h1 { margin-top: 0; font-size: 1.7rem; }
        label { display: block; font-weight: 600; margin: 1.2rem 0 .4rem; }
        select, input, button { box-sizing: border-box; width: 100%; padding: .8rem; font: inherit; border-radius: 6px; }
        select, input { border: 1px solid #8793a3; background: white; }
        button { border: 0; background: #2157ad; color: white; cursor: pointer; margin-top: 1rem; }
        button:disabled { background: #667085; cursor: default; }
        :focus-visible { outline: 3px solid #eab308; outline-offset: 3px; }
        .error { color: #a11c25; }
        #city-status { min-height: 1.5em; color: #000; }
        #city-details { color: #000; }
        table { width: 100%; color: #000; border-collapse: collapse; margin-top: 1rem; }
        th, td { text-align: left; padding: .7rem; border-bottom: 1px solid #dce2ea; overflow-wrap: anywhere; }
        th { width: 30%; }
        
        body, select, input, #city-status { color: #000; }
        button { color: white; }
        @media (max-width: 700px) { main { margin: 1rem; padding: 1.2rem; } }
    </style>
    <script src="zones.js?v=1" defer></script>
    <script src="timezone-autoselect.js?v=1" defer></script>
</head>
<body>
<header>
<!-- Nav bar Code Here -->
<?php $navInclude = stream_resolve_include_path('Nav-Bar.php'); if ($navInclude !== false) { require $navInclude; } ?>
<!-- end Nav Bar Code --> 
</header>
<main>
    <h1>Planet rise times by city</h1>
    <p>Choose a timezone, then a city to see when the Sun and planets rise. Times are local to the selected timezone.</p>

    <?php if ($error !== ''): ?>
        <p class="error" id="form-error" role="alert"><?= zones_escape($error) ?></p>
    <?php endif; ?>
    <?php if ($databaseReady && !$timezones): ?>
        <p>No timezones are available. Import Zones.tab into the database first.</p>
    <?php endif; ?>

    <form method="post" action="index.php" id="zone-form">
        <input type="hidden" name="csrf_token" value="<?= zones_escape($csrfToken) ?>">
        <label for="timezone">Timezone</label>
        <select id="timezone" name="tz" data-saved-timezone="<?= zones_escape(is_string($savedTimezone) ? $savedTimezone : '') ?>" required <?= !$databaseReady || !$timezones ? 'disabled' : '' ?>>
            <option value="">Select a timezone</option>
            <?php foreach ($timezones as $zone): ?>
                <option value="<?= zones_escape($zone) ?>" <?= $zone === $timezone ? 'selected' : '' ?>><?= zones_escape($zone) ?></option>
            <?php endforeach; ?>
        </select>

        <label for="date">Date (optional)</label>
        <input id="date" type="date" name="date" value="<?= zones_escape($selectedDate) ?>" aria-describedby="date-help">
        <p id="date-help">Leave blank for today in the selected timezone.</p>

        <label for="city">City</label>
        <select id="city" name="city_id" aria-describedby="city-status" <?= !$databaseReady || !$cities ? 'disabled' : '' ?>>
            <option value=""><?= $timezone === '' ? 'Select a timezone first' : 'Select a city' ?></option>
            <?php foreach ($cities as $city): ?>
                <option value="<?= zones_escape($city['id']) ?>" <?= (string) $city['id'] === $cityId ? 'selected' : '' ?>><?= zones_escape($city['city']) ?></option>
            <?php endforeach; ?>
        </select>
        <p id="city-status" role="status" aria-live="polite"></p>
        <button type="submit" id="show-city" <?= !$databaseReady || !$timezones ? 'disabled' : '' ?>>Show planet rise times</button>
    </form>
    <noscript><p>JavaScript loads cities automatically. Without it, select a timezone and submit to load its cities.</p></noscript>

    <?php if ($selectedCity !== null): ?>
        <section id="city-details" aria-labelledby="details-heading">
            <h2 id="details-heading"><?= zones_escape($selectedCity['city']) ?></h2>
            <?php if ($planetEvents !== null): ?>
                <p>For <?= zones_escape($planetEvents['date']) ?> in <?= zones_escape($timezone) ?>.</p>
                <table aria-label="Planet rise times">
                    <thead><tr><th scope="col">Body</th><th scope="col">Rise time</th></tr></thead>
                    <tbody>
                    <?php foreach ($planetEvents['planets'] as $planet): ?>
                        <tr><th scope="row"><?= zones_escape($planet['name']) ?></th><td>
                            <?php if (!$planet['rises']): ?>
                                No rise on this date.
                            <?php else: ?>
                                <?php foreach ($planet['rises'] as $rise): ?>
                                    <div><time datetime="<?= zones_escape($rise) ?>"><?= zones_escape((new DateTimeImmutable($rise))->format('g:i:s A (P)')) ?></time></div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </td></tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
            <?php if ($planetError !== ''): ?>
                <p class="error" role="alert"><?= zones_escape($planetError) ?></p>
            <?php endif; ?>
            <h3>City details</h3>
            <table>
                <tbody>
                <?php foreach (['id', 'city', 'latitude', 'longitude'] as $field): ?>
                    <tr><th scope="row"><?= zones_escape($field) ?></th><td><?= zones_escape($selectedCity[$field]) ?></td></tr>
                <?php endforeach; ?>
                </tbody>
            </table>
        </section>
    <?php endif; ?>
    
    </main>
    
<section class="extra-content">
    <div class="container">			
			<div class="About_Body">
    Astronomical calculations powered by
    <a href="https://www.astro.com/swisseph/" target="_blank" rel="noopener">
        Swiss Ephemeris
    </a>.
    <p>Read our <a href="https://astro.ctopher.me/About.php">About Page</a> for more details. Source <a href="https://github.com/Vivovim/SwissEph">Code</a></p>
   
</div>
</section>


   

<!-- Footer IS Magic -->
  <footer>  
<?php $footerInclude = stream_resolve_include_path('Footer.php'); if ($footerInclude !== false) { require $footerInclude; } ?>
</footer>
</body>
</html>
