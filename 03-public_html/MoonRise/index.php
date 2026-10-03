<?php
declare(strict_types=1);

require_once __DIR__ . '/database.php';
require_once __DIR__ . '/moonrise.php';
set_include_path( '/path_to_support_files/' );

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
require('timezone.php');

if (!isset($_SESSION['zone_csrf_token'])) {
    $_SESSION['zone_csrf_token'] = bin2hex(random_bytes(32));
}
$csrfToken = $_SESSION['zone_csrf_token'];
session_write_close(); // Release the session lock before the CGI request.

$timezones = [];
$cities = [];
$timezone = '';
$cityId = '';
$selectedCity = null;
$moonEvents = null;
$moonError = '';
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

        if (!is_string($postedToken) || !hash_equals($csrfToken, $postedToken)) {
            http_response_code(403);
            $error = 'Your form session expired. Please select your timezone and city again.';
        } elseif (!zones_valid_timezone($requestedTimezone) || !in_array($requestedTimezone, $timezones, true)) {
            http_response_code(400);
            $error = 'Choose a timezone from the list.';
        } else {
            $timezone = $requestedTimezone;
            $cities = zones_cities($connection, $timezone);

            if (!is_string($requestedId) || !preg_match('/\A[1-9][0-9]{0,9}\z/', $requestedId)
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
                }
            }
        }
    }
} catch (Throwable $exception) {
    error_log('Zones page: ' . $exception->getMessage());
    http_response_code(500);
    $databaseReady = false;
    $selectedCity = null;
    $error = 'Unable to load location data. Please try again later.';
}

if ($selectedCity !== null) {
    try {
        $moonEvents = AstroMoonrise\fetch_events($cityId, $timezone);
    } catch (Throwable $exception) {
        error_log('Zones moonrise lookup: ' . $exception->getMessage());
        http_response_code(502);
        $moonError = 'Unable to load moonrise and moonset right now. Please try again later.';
    }
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Moonrise and moonset by city</title>
    
    
<link rel="stylesheet" href="https://use.typekit.net/cfx5zcm.css">
<link href="https://astro.ctopher.me/css/bootstrap.css" rel="stylesheet" type="text/css">
<link href="https://astro.ctopher.me/css/misfit-ctopher-css.css?reload=true" rel="stylesheet" type="text/css">
<script src="https://astro.ctopher.me/js/jquery-3.5.1.min.js"></script> 
<script src="https://astro.ctopher.me/js/bootstrap.min.js"></script> 

<meta name="viewport" content="width=device-width, initial-scale=1.0">


    
    
    
    
    <style>
       
        main { max-width: 640px; margin: 3rem auto; padding: 2rem; background: white; border-radius: 12px; }
        h1 { margin-top: 0; font-size: 1.7rem; }
        label { display: block; font-weight: 600; margin: 1.2rem 0 .4rem; }
        select, button { box-sizing: border-box; width: 100%; padding: .8rem; font: inherit; border-radius: 6px; }
        select { border: 1px solid #8793a3; background: white; }
        button { border: 0; background: #2157ad; color: white; cursor: pointer; margin-top: 1rem; }
        button:disabled { background: #667085; cursor: default; }
        :focus-visible { outline: 3px solid #eab308; outline-offset: 3px; }
        .error { color: #a11c25; }
        #city-status { min-height: 1.5em; color: #000; }
        #city-details { color #000; }
        table { width: 100%; color #000; border-collapse: collapse; margin-top: 1rem; }
        th, td { text-align: left; padding: .7rem; border-bottom: 1px solid #dce2ea; overflow-wrap: anywhere; }
        th { width: 30%; }
        
        body, select, button, .error, #city-status { color: #000;}
        @media (max-width: 700px) { main { margin: 1rem; padding: 1.2rem; } }
    </style>
    <script src="zones.js?v=2" defer></script>
    <script src="timezone-autoselect.js?v=1" defer></script>
</head>
<body>
<header>
<!-- Nav bar Code Here -->
<?php require('Nav-Bar.php'); ?>
<!-- end Nav Bar Code --> 
</header>
<main>
    <h1>Moonrise and moonset by city</h1>
    <p>Choose a timezone, then a city to see today's moonrise and moonset.</p>

    <?php if ($error !== ''): ?>
        <p class="error" id="form-error" role="alert"><?= zones_escape($error) ?></p>
    <?php endif; ?>
    <?php if ($databaseReady && !$timezones): ?>
        <p>No timezones are available. Import Zones.tab into the database first.</p>
    <?php endif; ?>

    <form method="post" action="index.php" id="zone-form">
        <input type="hidden" name="csrf_token" value="<?= zones_escape($csrfToken) ?>">
        <label for="timezone">Timezone</label>
        <select id="timezone" name="tz" data-saved-timezone="<?= zones_escape(is_string($TimeZone1 ?? null) ? $TimeZone1 : '') ?>" required <?= !$databaseReady || !$timezones ? 'disabled' : '' ?>>
            <option value="">Select a timezone</option>
            <?php foreach ($timezones as $zone): ?>
                <option value="<?= zones_escape($zone) ?>" <?= $zone === $timezone ? 'selected' : '' ?>><?= zones_escape($zone) ?></option>
            <?php endforeach; ?>
        </select>

        <label for="city">City</label>
        <select id="city" name="city_id" required aria-describedby="city-status" <?= !$databaseReady || !$cities ? 'disabled' : '' ?>>
            <option value=""><?= $timezone === '' ? 'Select a timezone first' : 'Select a city' ?></option>
            <?php foreach ($cities as $city): ?>
                <option value="<?= zones_escape($city['id']) ?>" <?= (string) $city['id'] === $cityId ? 'selected' : '' ?>><?= zones_escape($city['city']) ?></option>
            <?php endforeach; ?>
        </select>
        <p id="city-status" role="status" aria-live="polite"></p>
        <button type="submit" id="show-city" <?= !$databaseReady || $cityId === '' ? 'disabled' : '' ?>>Show moonrise and moonset</button>
    </form>
    <noscript><p>Enable JavaScript to load cities when you select a timezone.</p></noscript>

    <?php if ($selectedCity !== null): ?>
        <section id="city-details" aria-labelledby="details-heading">
            <h2 id="details-heading"><?= zones_escape($selectedCity['city']) ?></h2>
            <?php if ($moonEvents !== null): ?>
                <p>For <?= zones_escape($moonEvents['date']) ?> in <?= zones_escape($timezone) ?>.</p>
                <table aria-label="Moonrise and moonset">
                    <tbody>
                    <?php foreach (['moonrise' => 'Moonrise', 'moonset' => 'Moonset'] as $event => $label): ?>
                        <tr><th scope="row"><?= $label ?></th><td>
                            <?php if ($moonEvents[$event] === null): ?>
                                No <?= $event ?> on this date.
                            <?php else: ?>
                                <time datetime="<?= zones_escape($moonEvents[$event]) ?>"><?= zones_escape((new DateTimeImmutable($moonEvents[$event]))->format('g:i:s A (P)')) ?></time>
                            <?php endif; ?>
                        </td></tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            <?php endif; ?>
            <?php if ($moonError !== ''): ?>
                <p class="error" role="alert"><?= zones_escape($moonError) ?></p>
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
<?php require('Footer.php'); ?>
</footer>
</body>
</html>
