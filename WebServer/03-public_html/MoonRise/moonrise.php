<?php
declare(strict_types=1);

namespace AstroMoonrise;

use DateTimeImmutable;
use DateTimeZone;
use RuntimeException;

// This URL is server-owned, never constructed from a form or HTTP header.
const CGI_URL = 'https://astro.ctopher.me/cgi-bin/MoonRise-Table.pl';
const PRIVATE_CONFIG = '/home/moonrise-config.php';

function fetch_events(string $id, string $timezone, string $configFile = PRIVATE_CONFIG): array
{
    if (!preg_match('/\A[1-9][0-9]{0,9}\z/', $id) || (float) $id > 4294967295) {
        throw new RuntimeException('Invalid city ID for moonrise request.');
    }
    if (!is_file($configFile) || !is_readable($configFile)) {
        throw new RuntimeException('Private moonrise configuration is missing or unreadable.');
    }
    $config = require $configFile;
    if (!is_array($config) || !is_string($config['shared_key'] ?? null)
        || !preg_match('/\A[a-f0-9]{64}\z/', $config['shared_key'])) {
        throw new RuntimeException('Configure the private moonrise shared key.');
    }
    if (!extension_loaded('curl')) {
        throw new RuntimeException('The PHP cURL extension is required.');
    }

    $request = json_encode(['id' => $id], JSON_THROW_ON_ERROR);
    $response = '';
    $receivedBytes = 0;
    $responseTooLarge = false;
    $handle = curl_init(CGI_URL);
    if ($handle === false) {
        throw new RuntimeException('Unable to initialize moonrise request.');
    }
    try {
        $options = [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => $request,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json',
                'Content-Length: ' . strlen($request),
                'X-Moonrise-Key: ' . $config['shared_key'],
                'Origin: https://astro.ctopher.me',
                'Expect:',
            ],
            CURLOPT_FOLLOWLOCATION => false, // Never forward the key to a redirect.
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 20,
            CURLOPT_PROXY => '', // Do not use environment-controlled proxies.
            CURLOPT_WRITEFUNCTION => static function ($curl, string $chunk) use (&$response, &$receivedBytes, &$responseTooLarge): int {
                $receivedBytes += strlen($chunk);
                if ($receivedBytes > 8192) {
                    $responseTooLarge = true;
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
        // Optional loopback routing preserves the HTTPS hostname and certificate.
        $connectIp = $config['connect_ip'] ?? '';
        if ($connectIp !== '') {
            if (!is_string($connectIp) || !filter_var($connectIp, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
                throw new RuntimeException('Invalid moonrise connection IP.');
            }
            $options[CURLOPT_RESOLVE] = ['astro.ctopher.me:443:' . $connectIp];
        }
        if (!curl_setopt_array($handle, $options)) {
            throw new RuntimeException('Unable to configure moonrise request.');
        }
        if (curl_exec($handle) === false) {
            // Log status and byte counts, never keys or an upstream response body.
            $status = (int) curl_getinfo($handle, CURLINFO_HTTP_CODE);
            $type = curl_getinfo($handle, CURLINFO_CONTENT_TYPE);
            $mime = is_string($type) ? strtolower(trim(explode(';', $type, 2)[0])) : 'unknown';
            if (!in_array($mime, ['application/json', 'text/html', 'text/plain', 'text/x-perl', 'application/octet-stream'], true)) {
                $mime = 'unknown';
            }
            $context = sprintf('HTTP %d; type %s; bytes received %d', $status, $mime, $receivedBytes);
            if ($responseTooLarge) {
                throw new RuntimeException('Moonrise CGI response exceeded the 8192-byte limit (' . $context . ').');
            }
            throw new RuntimeException('Moonrise CGI transport failed (cURL error ' . curl_errno($handle) . '; ' . $context . ').');
        }
        $status = curl_getinfo($handle, CURLINFO_HTTP_CODE);
        if ($status !== 200) {
            throw new RuntimeException('Moonrise CGI returned HTTP ' . $status . '.');
        }
        $contentType = curl_getinfo($handle, CURLINFO_CONTENT_TYPE);
        if (!is_string($contentType) || !preg_match('/\Aapplication\/json(?:\s*;|\z)/i', $contentType)) {
            throw new RuntimeException('Moonrise CGI did not return JSON.');
        }
    } finally {
        unset($handle);
    }

    return validate_response(json_decode($response, true, 4, JSON_THROW_ON_ERROR), $id, $timezone);
}

function validate_response($data, string $id, string $timezone): array
{
    if (!is_array($data) || isset($data['error'])
        || (!is_int($data['id'] ?? null) && !is_string($data['id'] ?? null))
        || (string) $data['id'] !== $id || ($data['timezone'] ?? null) !== $timezone
        || !is_string($data['date'] ?? null)) {
        throw new RuntimeException('Moonrise CGI returned a mismatched location.');
    }
    $date = DateTimeImmutable::createFromFormat('!Y-m-d', $data['date']);
    if ($date === false || $date->format('Y-m-d') !== $data['date']) {
        throw new RuntimeException('Moonrise CGI returned an invalid date.');
    }
    $zone = new DateTimeZone($timezone);
    foreach (['moonrise', 'moonset'] as $event) {
        if (!array_key_exists($event, $data)) {
            throw new RuntimeException('Moonrise CGI response is missing an event.');
        }
        if ($data[$event] === null) {
            continue;
        }
        $value = $data[$event];
        if (!is_string($value)
            || !preg_match('/\A[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}\z/', $value)) {
            throw new RuntimeException('Moonrise CGI returned an invalid event.');
        }
        $instant = DateTimeImmutable::createFromFormat('!Y-m-d\TH:i:sP', $value);
        if ($instant === false || $instant->setTimezone($zone)->format('Y-m-d\TH:i:sP') !== $value
            || $instant->format('Y-m-d') !== $data['date']) {
            throw new RuntimeException('Moonrise CGI returned an event outside the selected local date.');
        }
    }
    return $data;
}
