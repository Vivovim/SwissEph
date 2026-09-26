-- Import once into the database configured in update-phase.pl.
-- MySQL 5.7.8+ (native JSON support). One row per local calendar month.
-- All stamp columns contain signed Unix seconds; NULL means no event.
CREATE TABLE IF NOT EXISTS `moonphase_new` (
    `month` DATE NOT NULL COMMENT 'First day of the calendar month',
    `date_updated` DATETIME NOT NULL COMMENT 'Last successful write, UTC',
    `timezone` VARCHAR(64) NOT NULL COMMENT 'IANA zone defining the calendar month',
    `phase1` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First New Moon',
    `stamp1` BIGINT NULL DEFAULT NULL,
    `phase2` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Waxing Crescent',
    `stamp2` BIGINT NULL DEFAULT NULL,
    `phase3` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First First Quarter',
    `stamp3` BIGINT NULL DEFAULT NULL,
    `phase4` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Waxing Gibbous',
    `stamp4` BIGINT NULL DEFAULT NULL,
    `phase5` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Full Moon',
    `stamp5` BIGINT NULL DEFAULT NULL,
    `phase6` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Waning Gibbous',
    `stamp6` BIGINT NULL DEFAULT NULL,
    `phase7` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Last Quarter',
    `stamp7` BIGINT NULL DEFAULT NULL,
    `phase8` VARCHAR(20) NOT NULL DEFAULT 'na' COMMENT 'First Waning Crescent',
    `stamp8` BIGINT NULL DEFAULT NULL,
    `blue_moon_phase` VARCHAR(20) NOT NULL DEFAULT 'na',
    `blue_moon_stamp` BIGINT NULL DEFAULT NULL COMMENT 'Second Full Moon in this local month',
    `events_json` JSON NOT NULL COMMENT 'Every event: phase and Unix timestamp, chronological',
    PRIMARY KEY (`month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
