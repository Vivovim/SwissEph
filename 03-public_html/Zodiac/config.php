<?php
declare(strict_types=1);

// Administrator configuration only. Never accept an upstream URL from a form.
$cgiToken = getenv('ZODIAC_CGI_TOKEN');
return [
    'cgi_url' => 'https://astro.ctopher.me/cgi-bin/zodiac-chart.pl',
    // Optional shared token: set the SAME secret in the PHP and CGI environments.
    'cgi_token' => $cgiToken === false ? '' : $cgiToken,
    // Sibling MoonRise directory: reuse its database.php and config.php.
    // This is an administrator-owned filesystem path, never a request parameter.
    'moonrise_database_file' => dirname(__DIR__) . '/MoonRise/database.php',
    'default_timezone' => 'America/Phoenix',
    // Optional Zones.id to preselect in the default timezone; otherwise choose a city.
    'default_city_id' => '',
];
