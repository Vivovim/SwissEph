<?php
declare(strict_types=1);

// Reuse the existing MoonRise database settings rather than duplicating credentials.
// PLANETRISE_DB_CONFIG may point to a private PHP file returning the same array.
$databaseFile = getenv('PLANETRISE_DB_CONFIG') ?: __DIR__ . '/../MoonRise/config.php';
if (!is_file($databaseFile) || !is_readable($databaseFile)) {
    throw new RuntimeException('PlanetRise database configuration is missing or unreadable.');
}
$database = require $databaseFile;
if (!is_array($database)) {
    throw new RuntimeException('PlanetRise database configuration must return an array.');
}

return array_merge($database, [
    // Upload planet-rise.pl to this CGI location. This URL is never taken from a form.
    'cgi_url' => 'https://astro.ctopher.me/cgi-bin/planet-rise.pl',
    'connect_ip' => '', // Optional IPv4 loopback routing, preserving HTTPS verification.
    'site_include_path' => '/home/misfitx/astro/BoxINC/',
]);
