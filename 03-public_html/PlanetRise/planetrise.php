<?php
declare(strict_types=1);

namespace AstroPlanetrise;

use DateTimeImmutable;
use DateTimeZone;
use RuntimeException;

const PLANETS = ['Sun', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto'];

function valid_date($date): bool
{
    if (!is_string($date) || !preg_match('/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/', $date)) {
        return false;
    }
    [$year, $month, $day] = array_map('intval', explode('-', $date));
    return checkdate($month, $day, $year);
}

function make_request(array $city, string $timezone, ?string $date = null): array
{
    if (!preg_match('/\A[A-Za-z][A-Za-z0-9_+-]*(?:\/[A-Za-z0-9_+-]+)*\z/', $timezone)
        || strlen($timezone) > 100) {
        throw new RuntimeException('Invalid timezone for planet rise request.');
    }
    $zone = new DateTimeZone($timezone);
    $request = ['timezone' => $timezone];
    foreach (['latitude' => 90, 'longitude' => 180] as $field => $limit) {
        $raw = $city[$field] ?? null;
        if ((!is_string($raw) && !is_int($raw) && !is_float($raw)) || !is_numeric($raw)
            || !is_finite((float) $raw) || abs((float) $raw) > $limit) {
            throw new RuntimeException('Invalid ' . $field . ' in city database.');
        }
        $request[$field] = (float) $raw;
    }
    $date = $date ?? (new DateTimeImmutable('now', $zone))->format('Y-m-d');
    if (!valid_date($date)) {
        throw new RuntimeException('Invalid date for planet rise request.');
    }
    $request['date'] = $date;
    return $request;
}

function fetch_events(array $city, string $timezone, ?string $date = null, ?array $config = null): array
{
    $request = make_request($city, $timezone, $date);
    $config = $config ?? require __DIR__ . '/config.php';
    $url = $config['cgi_url'] ?? null;
    $parts = is_string($url) ? parse_url($url) : false;
    if (!$parts || ($parts['scheme'] ?? '') !== 'https' || empty($parts['host'])
        || isset($parts['user']) || isset($parts['pass']) || isset($parts['fragment']) || isset($parts['query'])) {
        throw new RuntimeException('Configure a fixed HTTPS PlanetRise CGI URL.');
    }
    if (!extension_loaded('curl')) {
        throw new RuntimeException('The PHP cURL extension is required.');
    }
    $body = json_encode($request, JSON_THROW_ON_ERROR);
    $response = '';
    $bytes = 0;
    $tooLarge = false;
    $handle = curl_init($url);
    if ($handle === false) {
        throw new RuntimeException('Unable to initialize planet rise request.');
    }
    try {
        $options = [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $body,
            CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json',
                'Content-Length: ' . strlen($body), 'Expect:'],
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 20,
            CURLOPT_PROXY => '',
            CURLOPT_WRITEFUNCTION => static function ($curl, string $chunk) use (&$response, &$bytes, &$tooLarge): int {
                $bytes += strlen($chunk);
                if ($bytes > 8192) {
                    $tooLarge = true;
                    return 0;
                }
                $response .= $chunk;
                return strlen($chunk);
            },
        ];
        if (defined('CURLOPT_PROTOCOLS_STR')) {
            $options[CURLOPT_PROTOCOLS_STR] = 'https';
        } else {
            $options[CURLOPT_PROTOCOLS] = CURLPROTO_HTTPS;
        }
        $connectIp = $config['connect_ip'] ?? '';
        if ($connectIp !== '') {
            if (!is_string($connectIp) || !filter_var($connectIp, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                throw new RuntimeException('Invalid PlanetRise connection IP.');
            }
            $options[CURLOPT_RESOLVE] = [$parts['host'] . ':' . ($parts['port'] ?? 443) . ':' . $connectIp];
        }
        if (!curl_setopt_array($handle, $options)) {
            throw new RuntimeException('Unable to configure planet rise request.');
        }
        if (curl_exec($handle) === false) {
            throw new RuntimeException($tooLarge
                ? 'PlanetRise CGI response exceeded 8192 bytes.'
                : 'PlanetRise CGI transport failed (cURL error ' . curl_errno($handle) . ').');
        }
        $status = (int) curl_getinfo($handle, CURLINFO_HTTP_CODE);
        if ($status !== 200) {
            throw new RuntimeException('PlanetRise CGI returned HTTP ' . $status . '.');
        }
        $type = curl_getinfo($handle, CURLINFO_CONTENT_TYPE);
        if (!is_string($type) || !preg_match('/\Aapplication\/json(?:\s*;|\z)/i', $type)) {
            throw new RuntimeException('PlanetRise CGI did not return JSON.');
        }
    } finally {
        unset($handle);
    }
    return validate_response(json_decode($response, true, 8, JSON_THROW_ON_ERROR), $request);
}

function validate_response($data, array $request): array
{
    if (!is_array($data) || isset($data['error']) || ($data['timezone'] ?? null) !== $request['timezone']
        || ($data['date'] ?? null) !== $request['date'] || !valid_date($data['date'] ?? null)) {
        throw new RuntimeException('PlanetRise CGI returned a mismatched timezone or date.');
    }
    foreach (['latitude', 'longitude', 'elevation'] as $field) {
        $value = $data[$field] ?? null;
        if ((!is_int($value) && !is_float($value)) || !is_finite((float) $value)
            || abs((float) $value - (float) ($request[$field] ?? 0)) > 0.000000001) {
            throw new RuntimeException('PlanetRise CGI returned mismatched coordinates or elevation.');
        }
    }
    if (!isset($data['planets']) || !is_array($data['planets'])
        || array_values($data['planets']) !== $data['planets'] || count($data['planets']) !== count(PLANETS)) {
        throw new RuntimeException('PlanetRise CGI response must contain all nine bodies.');
    }
    $zone = new DateTimeZone($request['timezone']);
    foreach ($data['planets'] as $index => $planet) {
        if (!is_array($planet) || ($planet['name'] ?? null) !== PLANETS[$index]
            || !array_key_exists('rise', $planet) || !isset($planet['rises']) || !is_array($planet['rises'])
            || array_values($planet['rises']) !== $planet['rises'] || count($planet['rises']) > 8
            || $planet['rise'] !== ($planet['rises'][0] ?? null)) {
            throw new RuntimeException('PlanetRise CGI returned invalid planet data.');
        }
        $previous = null;
        foreach ($planet['rises'] as $value) {
            if (!is_string($value) || !preg_match('/\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}\z/', $value)) {
                throw new RuntimeException('PlanetRise CGI returned an invalid rise timestamp.');
            }
            $instant = DateTimeImmutable::createFromFormat('!Y-m-d\TH:i:sP', $value);
            if ($instant === false || $instant->setTimezone($zone)->format('Y-m-d\TH:i:sP') !== $value
                || $instant->setTimezone($zone)->format('Y-m-d') !== $request['date']
                || ($previous !== null && $instant->getTimestamp() <= $previous)) {
                throw new RuntimeException('PlanetRise CGI returned an out-of-date, out-of-order, or invalid local rise time.');
            }
            $previous = $instant->getTimestamp();
        }
    }
    return $data;
}
