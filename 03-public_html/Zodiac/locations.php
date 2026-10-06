<?php
declare(strict_types=1);

namespace ZodiacChart;

use RuntimeException;

// Reuse MoonRise's connection configuration and prepared Zones queries.
function location_database(array $config)
{
    if (!function_exists('zones_database')) {
        $file = $config['moonrise_database_file'] ?? '';
        if (!is_string($file) || $file === '' || $file[0] !== '/' || !is_file($file) || !is_readable($file)) {
            throw new RuntimeException('The MoonRise database helper is missing or unreadable. Configure moonrise_database_file in Zodiac/config.php.');
        }
        require_once $file;
    }
    return \zones_database();
}

function location_timezones($connection): array
{
    $supported = array_fill_keys(timezones(), true);
    $zones = [];
    foreach (\zones_timezones($connection) as $zone) {
        if (is_string($zone) && strlen($zone) <= 64 && isset($supported[$zone])) {
            $zones[$zone] = true;
        }
    }
    $result = array_keys($zones);
    sort($result, SORT_STRING);
    return $result;
}

function location_timezone($value): string
{
    if (!is_string($value) || strlen($value) > 64 || !in_array($value, timezones(), true)) {
        throw new ChartError(400, 'invalid_input', 'Select a timezone from the list.');
    }
    return $value;
}

function location_city_id($value): string
{
    if ((!is_string($value) && !is_int($value))
        || !preg_match('/\A[1-9][0-9]{0,9}\z/', (string) $value)
        || (float) $value > 4294967295) {
        throw new ChartError(400, 'invalid_input', 'Select a city from the list.');
    }
    return (string) $value;
}

function city_option(array $row): array
{
    try {
        $id = location_city_id($row['id'] ?? null);
    } catch (ChartError $error) {
        throw new RuntimeException('The city database returned an invalid city ID.');
    }
    $name = $row['city'] ?? null;
    if (!is_string($name) || $name === '' || strlen($name) > 512
        || preg_match('/[\x00-\x1f\x7f]/', $name) || preg_match('//u', $name) !== 1) {
        throw new RuntimeException('The city database returned an invalid city name.');
    }
    return ['id' => $id, 'city' => $name];
}

function location_cities($connection, $value): array
{
    $timezone = location_timezone($value);
    if (!in_array($timezone, location_timezones($connection), true)) {
        throw new ChartError(400, 'invalid_input', 'Select a timezone from the list.');
    }
    $result = [];
    foreach (\zones_cities($connection, $timezone) as $row) {
        if (!is_array($row)) {
            throw new RuntimeException('The city database returned an invalid city list.');
        }
        $result[] = city_option($row);
    }
    return $result;
}

function city_chart_request(array $input, $connection): array
{
    $fields = ['mode', 'date', 'time', 'timezone', 'city_id', 'house_system', 'fold'];
    if (array_diff(array_keys($input), $fields)) {
        throw new ChartError(400, 'invalid_input', 'Unknown request field. Choose a database city for the location.');
    }
    $timezone = location_timezone($input['timezone'] ?? null);
    $id = location_city_id($input['city_id'] ?? null);
    // The reused query requires both ID and timezone, preventing a city from
    // being paired with a different timezone or browser-supplied coordinates.
    $row = \zones_city($connection, $timezone, $id);
    if ($row === null) {
        throw new ChartError(400, 'invalid_city', 'That city does not belong to the selected timezone. Choose a city from the list.');
    }
    $city = city_option($row);
    if ($city['id'] !== $id) {
        throw new RuntimeException('The city database returned a mismatched city ID.');
    }
    try {
        $latitude = numeric($row['latitude'] ?? null, 'latitude', -90, 90);
        $longitude = numeric($row['longitude'] ?? null, 'longitude', -180, 180);
        if (abs($latitude) === 90.0) {
            throw new RuntimeException('The city database returned a polar latitude unsupported by houses.');
        }
    } catch (ChartError $error) {
        throw new RuntimeException('The city database returned invalid coordinates.');
    }
    unset($input['city_id']);
    $input['latitude'] = $latitude;
    $input['longitude'] = $longitude;
    return [
        'request' => make_request($input),
        'location' => $city + ['timezone' => $timezone, 'latitude' => $latitude, 'longitude' => $longitude],
    ];
}
