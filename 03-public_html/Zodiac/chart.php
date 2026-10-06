<?php
declare(strict_types=1);

namespace ZodiacChart;

use DateTimeImmutable;
use DateTimeZone;
use RuntimeException;

const CGI_URL = 'https://astro.ctopher.me/cgi-bin/zodiac-chart.pl';
const SIGN_NAMES = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
const SIGN_SYMBOLS = ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'];
const BODIES = [
    ['sun', 'Sun', '☉'], ['moon', 'Moon', '☽'], ['mercury', 'Mercury', '☿'],
    ['venus', 'Venus', '♀'], ['earth', 'Earth', '⊕'], ['mars', 'Mars', '♂'],
    ['jupiter', 'Jupiter', '♃'], ['saturn', 'Saturn', '♄'], ['uranus', 'Uranus', '♅'],
    ['neptune', 'Neptune', '♆'], ['pluto', 'Pluto', '♇'],
];

final class ChartError extends RuntimeException
{
    public $status;
    public $errorCode;
    public function __construct(int $status, string $code, string $message)
    {
        parent::__construct($message);
        $this->status = $status;
        $this->errorCode = $code;
    }
}

function numeric($value, string $field, float $min, float $max): float
{
    if ((!is_int($value) && !is_float($value) && !is_string($value)) || !is_numeric($value)
        || !is_finite((float) $value) || (float) $value < $min || (float) $value > $max) {
        throw new ChartError(400, 'invalid_input', "Enter a valid $field between $min and $max.");
    }
    return (float) $value;
}

function timezones(): array
{
    return array_values(array_unique(array_merge(['UTC'], DateTimeZone::listIdentifiers(DateTimeZone::ALL_WITH_BC))));
}

function make_request(array $input): array
{
    $fields = ['mode', 'date', 'time', 'timezone', 'latitude', 'longitude', 'house_system', 'fold'];
    if (array_diff(array_keys($input), $fields)) {
        throw new ChartError(400, 'invalid_input', 'Unknown request field.');
    }
    $name = $input['timezone'] ?? null;
    if (!is_string($name) || strlen($name) > 100 || !in_array($name, timezones(), true)) {
        throw new ChartError(400, 'invalid_input', 'Select a valid timezone.');
    }
    $zone = new DateTimeZone($name);
    $latitude = numeric($input['latitude'] ?? null, 'latitude', -90, 90);
    $longitude = numeric($input['longitude'] ?? null, 'longitude', -180, 180);
    if (abs($latitude) === 90.0) {
        throw new ChartError(400, 'invalid_input', 'Latitude must be strictly between -90 and 90.');
    }
    $system = $input['house_system'] ?? 'E';
    $mode = $input['mode'] ?? 'manual';
    $fold = $input['fold'] ?? '';
    if (!in_array($system, ['E', 'P', 'W'], true) || !in_array($mode, ['manual', 'now'], true)
        || !in_array($fold, ['', 'earlier', 'later'], true)) {
        throw new ChartError(400, 'invalid_input', 'Invalid chart mode, house system, or repeated-hour choice.');
    }
    if ($mode === 'now') {
        $instant = new DateTimeImmutable('now', $zone);
    } else {
        $date = $input['date'] ?? null;
        $time = $input['time'] ?? null;
        if (!is_string($date) || !preg_match('/\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/', $date, $parts)
            || !checkdate((int) $parts[2], (int) $parts[3], (int) $parts[1])
            || !is_string($time) || !preg_match('/\A(?:[01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?\z/', $time)) {
            throw new ChartError(400, 'invalid_input', 'Enter a valid date and local time.');
        }
        if (strlen($time) === 5) {
            $time .= ':00';
        }
        $wall = $date . ' ' . $time;
        $naive = DateTimeImmutable::createFromFormat('!Y-m-d H:i:s', $wall, new DateTimeZone('UTC'));
        $epoch = $naive->getTimestamp();
        $transitions = $zone->getTransitions($epoch - 172800, $epoch + 172800);
        $offsets = $transitions === false ? [$zone->getOffset($naive)] : array_column($transitions, 'offset');
        $matches = [];
        foreach (array_unique($offsets) as $offset) {
            $candidate = (new DateTimeImmutable('@' . ($epoch - $offset)))->setTimezone($zone);
            if ($candidate->format('Y-m-d H:i:s') === $wall) {
                $matches[$candidate->getTimestamp()] = $candidate;
            }
        }
        ksort($matches, SORT_NUMERIC);
        if (!$matches) {
            throw new ChartError(400, 'nonexistent_local_time', 'That local time does not exist in this timezone. Select a time outside the daylight-saving gap.');
        }
        if (count($matches) > 1 && $fold === '') {
            throw new ChartError(400, 'ambiguous_local_time', 'That local time occurs twice. Choose the first or second occurrence below.');
        }
        $instant = $fold === 'later' ? end($matches) : reset($matches);
    }
    return [
        'date' => $instant->format('Y-m-d'), 'time' => $instant->format('H:i:s'),
        'timezone' => $name, 'latitude' => $latitude, 'longitude' => $longitude,
        'house_system' => $system, 'width' => 1200, 'utc_offset_seconds' => $instant->getOffset(),
    ];
}

function request_cgi(array $request, array $config): array
{
    if (($config['cgi_url'] ?? '') !== CGI_URL) {
        throw new RuntimeException('The CGI URL must match the fixed HTTPS endpoint.');
    }
    if (!extension_loaded('curl')) {
        throw new RuntimeException('The PHP cURL extension is required.');
    }
    $token = $config['cgi_token'] ?? '';
    if (!is_string($token) || strlen($token) > 256 || preg_match('/[\x00-\x20\x7f]/', $token)) {
        throw new RuntimeException('Invalid CGI token configuration.');
    }
    $headers = ['Content-Type: application/json', 'Accept: application/json', 'Expect:'];
    if ($token !== '') {
        $headers[] = 'X-Zodiac-Token: ' . $token;
    }
    $body = '';
    $tooLarge = false;
    $handle = curl_init(CGI_URL);
    if ($handle === false) {
        throw new RuntimeException('Unable to initialize CGI transport.');
    }
    try {
        $options = [
            CURLOPT_POST => true, CURLOPT_POSTFIELDS => json_encode($request, JSON_THROW_ON_ERROR),
            CURLOPT_HTTPHEADER => $headers, CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_SSL_VERIFYPEER => true, CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => 5, CURLOPT_TIMEOUT => 20, CURLOPT_PROXY => '',
            CURLOPT_WRITEFUNCTION => static function ($handle, string $chunk) use (&$body, &$tooLarge): int {
                if (strlen($body) + strlen($chunk) > 131072) {
                    $tooLarge = true;
                    return 0;
                }
                $body .= $chunk;
                return strlen($chunk);
            },
        ];
        if (defined('CURLOPT_PROTOCOLS_STR')) {
            $options[CURLOPT_PROTOCOLS_STR] = 'https';
        } else {
            $options[CURLOPT_PROTOCOLS] = CURLPROTO_HTTPS;
        }
        if (!curl_setopt_array($handle, $options) || curl_exec($handle) === false) {
            throw new RuntimeException($tooLarge ? 'CGI response exceeds 128 KiB.' : 'CGI HTTPS transport failed (cURL error ' . curl_errno($handle) . ').');
        }
        $status = (int) curl_getinfo($handle, CURLINFO_HTTP_CODE);
        $type = curl_getinfo($handle, CURLINFO_CONTENT_TYPE);
        if (!is_string($type) || !preg_match('/\Aapplication\/json(?:\s*;|\z)/i', $type)) {
            throw new RuntimeException('CGI returned HTTP ' . $status . ' without JSON.');
        }
        $data = json_decode($body, true, 16, JSON_THROW_ON_ERROR);
        if ($status !== 200) {
            $code = is_array($data) ? ($data['error']['code'] ?? null) : null;
            if ($status === 401 && $code === 'unauthorized') {
                throw new RuntimeException($token === ''
                    ? 'CGI authentication failed: ZODIAC_CGI_TOKEN is not configured in PHP/FPM.'
                    : 'CGI authentication failed: PHP token was rejected. Check that PHP and CGI use the same ZODIAC_CGI_TOKEN and that Apache forwards X-Zodiac-Token.');
            }
            if ($code === 'house_calculation_error' && $status === 422) {
                throw new ChartError(422, $code, 'This house system is unavailable at this location and time. Try equal or whole-sign houses.');
            }
            throw new RuntimeException('CGI returned HTTP ' . $status . '.');
        }
        return validate_response($data, $request);
    } finally {
        unset($handle);
    }
}

function upstream_number($value, float $min, float $max): float
{
    if ((!is_int($value) && !is_float($value)) || !is_finite((float) $value) || $value < $min || $value > $max) {
        throw new RuntimeException('CGI returned an invalid numeric field.');
    }
    return (float) $value;
}

function sign(float $longitude): array
{
    $i = (int) floor($longitude / 30);
    return ['index' => $i, 'name' => SIGN_NAMES[$i], 'symbol' => SIGN_SYMBOLS[$i], 'degree' => $longitude - $i * 30];
}

function offset(float $longitude, float $origin): float
{
    return fmod($longitude - $origin + 360, 360);
}

function segment(float $start, float $end): array
{
    return ['x_start_fraction' => $start / 360, 'x_end_fraction' => $end / 360,
        'x_start_px' => $start / 360 * 1200, 'x_end_px' => $end / 360 * 1200, 'width_px' => ($end - $start) / 360 * 1200];
}

function validate_response($data, array $request): array
{
    if (!is_array($data) || isset($data['error']) || ($data['schema_version'] ?? null) !== 1
        || ($data['calculation']['zodiac'] ?? null) !== 'tropical'
        || ($data['calculation']['house_system'] ?? null) !== $request['house_system']) {
        throw new RuntimeException('CGI returned an unexpected schema or calculation.');
    }
    $instant = $data['instant'] ?? [];
    foreach (['date', 'time', 'timezone', 'utc_offset_seconds'] as $field) {
        if (($instant[$field] ?? null) !== $request[$field]) {
            throw new RuntimeException('CGI returned a mismatched date, time, or timezone.');
        }
    }
    $expected = new DateTimeImmutable($request['date'] . 'T' . $request['time'], new DateTimeZone('UTC'));
    $expected = $expected->modify(sprintf('%+d seconds', -$request['utc_offset_seconds']));
    if (($instant['unix_timestamp'] ?? null) !== $expected->getTimestamp()
        || ($instant['utc_datetime'] ?? null) !== $expected->format('Y-m-d\TH:i:s\Z')) {
        throw new RuntimeException('CGI returned a mismatched UTC instant.');
    }
    foreach (['latitude', 'longitude'] as $field) {
        $value = upstream_number($data['location'][$field] ?? null, -180, 180);
        if (abs($value - $request[$field]) > 1e-9) {
            throw new RuntimeException('CGI returned mismatched coordinates.');
        }
    }
    $origin = upstream_number($data['chart']['origin_longitude_deg'] ?? null, 0, 359.99999999999994);
    foreach (['houses' => 12, 'zodiac' => 12, 'planets' => 11] as $key => $count) {
        if (!isset($data[$key]) || !is_array($data[$key]) || array_keys($data[$key]) !== range(0, $count - 1)) {
            throw new RuntimeException('CGI returned an incomplete chart.');
        }
    }
    $cusps = [];
    foreach ($data['houses'] as $i => $house) {
        if (!is_array($house) || ($house['number'] ?? null) !== $i + 1) {
            throw new RuntimeException('CGI returned an invalid house number.');
        }
        $cusps[] = upstream_number($house['cusp_longitude_deg'] ?? null, 0, 359.99999999999994);
    }
    if (abs($cusps[0] - $origin) > 1e-8) {
        throw new RuntimeException('CGI returned a mismatched ruler origin.');
    }
    $offsets = array_map(static function ($cusp) use ($origin) { return offset($cusp, $origin); }, $cusps);
    $offsets[] = 360.0;
    $houses = [];
    for ($i = 0; $i < 12; $i++) {
        if ($offsets[$i + 1] <= $offsets[$i]
            || ($request['house_system'] !== 'P' && abs($offsets[$i + 1] - $offsets[$i] - 30) > 1e-7)) {
            throw new RuntimeException('CGI returned inconsistent house cusps.');
        }
        $houses[] = ['number' => $i + 1, 'cusp_longitude_deg' => $cusps[$i], 'sign' => sign($cusps[$i])]
            + segment($offsets[$i], $offsets[$i + 1]);
    }
    $zodiac = [];
    for ($i = 0; $i < 12; $i++) {
        $start = offset($i * 30.0, $origin);
        $end = $start + 30;
        $zodiac[] = ['index' => $i, 'name' => SIGN_NAMES[$i], 'symbol' => SIGN_SYMBOLS[$i],
            'segments' => $end <= 360 ? [segment($start, $end)] : [segment(0, $end - 360), segment($start, 360)]];
    }
    $planets = [];
    foreach ($data['planets'] as $i => $planet) {
        [$key, $name, $symbol] = BODIES[$i];
        $earth = $key === 'earth';
        if (!is_array($planet) || ($planet['key'] ?? null) !== $key || ($planet['name'] ?? null) !== $name
            || ($planet['reference_frame'] ?? null) !== ($earth ? 'heliocentric' : 'geocentric')
            || ($planet['plot_on_chart'] ?? null) !== !$earth) {
            throw new RuntimeException('CGI returned an unexpected planet or reference frame.');
        }
        $lon = upstream_number($planet['longitude_deg'] ?? null, 0, 359.99999999999994);
        $speed = upstream_number($planet['longitude_speed_deg_per_day'] ?? null, -1000, 1000);
        if (($planet['retrograde'] ?? null) !== ($speed < 0)) {
            throw new RuntimeException('CGI returned inconsistent planetary motion.');
        }
        $x = $earth ? null : offset($lon, $origin);
        $house = null;
        if (!$earth) {
            for ($h = 0; $h < 12; $h++) {
                if ($x >= $offsets[$h] && $x < $offsets[$h + 1]) {
                    $house = $h + 1;
                }
            }
        }
        if (($planet['house_number'] ?? null) !== $house
            || ($earth && (($planet['x_fraction'] ?? null) !== null))
            || (!$earth && abs(upstream_number($planet['x_fraction'] ?? null, 0, 1) - $x / 360) > 1e-8)) {
            throw new RuntimeException('CGI returned inconsistent planetary house or position.');
        }
        $planets[] = ['key' => $key, 'name' => $name, 'symbol' => $symbol, 'longitude_deg' => $lon,
            'longitude_speed_deg_per_day' => $speed, 'retrograde' => $speed < 0,
            'reference_frame' => $earth ? 'heliocentric' : 'geocentric', 'plot_on_chart' => !$earth,
            'sign' => sign($lon), 'house_number' => $house, 'x_fraction' => $earth ? null : $x / 360];
    }
    $local = $expected->setTimezone(new DateTimeZone($request['timezone']));
    // Return only normalized, allowlisted data. Upstream strings never become SVG markup.
    return [
        'schema_version' => 1, 'instant' => ['date' => $request['date'], 'time' => $request['time'],
            'timezone' => $request['timezone'], 'local_datetime' => $local->format('Y-m-d\TH:i:sP'),
            'utc_datetime' => $expected->format('Y-m-d\TH:i:s\Z')],
        'location' => ['latitude' => $request['latitude'], 'longitude' => $request['longitude']],
        'calculation' => ['house_system' => $request['house_system']],
        'chart' => ['width_px' => 1200, 'origin_longitude_deg' => $origin],
        'angles' => ['ascendant_longitude_deg' => upstream_number($data['angles']['ascendant_longitude_deg'] ?? null, 0, 359.99999999999994),
            'midheaven_longitude_deg' => upstream_number($data['angles']['midheaven_longitude_deg'] ?? null, 0, 359.99999999999994)],
        'zodiac' => $zodiac, 'houses' => $houses, 'planets' => $planets,
    ];
}

function escape(string $text): string
{
    return htmlspecialchars($text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
