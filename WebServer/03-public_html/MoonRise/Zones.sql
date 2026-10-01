CREATE TABLE IF NOT EXISTS `Zones` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `city`      VARCHAR(255) NOT NULL,
    `latitude`  DECIMAL(8,5) NOT NULL,
    `longitude` DECIMAL(8,5) NOT NULL,
    `tz`        VARCHAR(64) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
