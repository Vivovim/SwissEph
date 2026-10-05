<?php
declare(strict_types=1);

function zones_database(): mysqli
{
    $config = require __DIR__ . '/config.php';
    if ($config['database'] === 'your_database' || $config['user'] === 'your_user'
        || $config['password'] === 'your_password') {
        throw new RuntimeException('Configure the MySQL connection settings in config.php first.');
    }
    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    $connection = mysqli_init();
    $connection->options(MYSQLI_OPT_CONNECT_TIMEOUT, 5);
    $connection->real_connect(
        $config['host'],
        $config['user'],
        $config['password'],
        $config['database'],
        $config['port']
    );
    $connection->set_charset('utf8mb4');

    return $connection;
}

function zones_valid_timezone($value): bool
{
    return is_string($value) && strlen($value) <= 64
        && preg_match('/\A[A-Za-z][A-Za-z0-9_+-]*(?:\/[A-Za-z0-9_+-]+)*\z/', $value) === 1;
}

function zones_timezones(mysqli $connection): array
{
    $result = $connection->query('SELECT DISTINCT `tz` FROM `Zones` ORDER BY `tz`');
    $timezones = [];
    while ($row = $result->fetch_assoc()) {
        $timezones[] = $row['tz'];
    }
    $result->free();
    return $timezones;
}

function zones_cities(mysqli $connection, string $timezone): array
{
    $statement = $connection->prepare(
        'SELECT `id`, `city` FROM `Zones` WHERE `tz` = ? ORDER BY `city`, `id`'
    );
    $statement->bind_param('s', $timezone);
    $statement->execute();
    $statement->bind_result($id, $city);
    $cities = [];
    while ($statement->fetch()) {
        $cities[] = ['id' => $id, 'city' => $city];
    }
    $statement->close();
    return $cities;
}

function zones_city(mysqli $connection, string $timezone, string $id): ?array
{
    $statement = $connection->prepare(
        'SELECT `id`, `city`, `latitude`, `longitude` FROM `Zones` WHERE `id` = ? AND `tz` = ?'
    );
    $statement->bind_param('ss', $id, $timezone);
    $statement->execute();
    $statement->bind_result($resultId, $city, $latitude, $longitude);
    $row = $statement->fetch() ? [
        'id' => $resultId,
        'city' => $city,
        'latitude' => $latitude,
        'longitude' => $longitude,
    ] : null;
    $statement->close();
    return $row;
}

function zones_escape($value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}
