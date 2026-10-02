-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 27, 2026 at 08:35 PM
-- Server version: 8.4.11-0ubuntu0.26.04.1
-- PHP Version: 8.5.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `SwissAstro`
--

-- --------------------------------------------------------

--
-- Table structure for table `CheckPlanets`
--

CREATE TABLE `CheckPlanets` (
  `recid` int NOT NULL,
  `date` varchar(255) NOT NULL,
  `mercury` varchar(255) NOT NULL,
  `venus` varchar(255) NOT NULL,
  `mars` varchar(255) NOT NULL,
  `jupiter` varchar(255) NOT NULL,
  `saturn` varchar(255) NOT NULL,
  `uranus` varchar(255) NOT NULL,
  `neptune` varchar(255) NOT NULL,
  `pluto` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `mercury`
--

CREATE TABLE `mercury` (
  `recid` int NOT NULL,
  `retro` varchar(255) NOT NULL,
  `direct` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `moonphase`
--

CREATE TABLE `moonphase` (
  `recid` int NOT NULL,
  `date` varchar(255) NOT NULL,
  `phase2` varchar(255) DEFAULT NULL,
  `phase` varchar(255) NOT NULL,
  `nmoon` varchar(255) DEFAULT NULL,
  `fq` varchar(255) DEFAULT NULL,
  `fmoon` varchar(255) DEFAULT NULL,
  `lq` varchar(255) DEFAULT NULL,
  `xnmoon` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `moonphase_new`
--

CREATE TABLE `moonphase_new` (
  `month` date NOT NULL COMMENT 'First day of the calendar month',
  `date_updated` datetime NOT NULL COMMENT 'Last successful write, UTC',
  `timezone` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'IANA zone defining the calendar month',
  `phase1` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First New Moon',
  `stamp1` bigint DEFAULT NULL,
  `phase2` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waxing Crescent',
  `stamp2` bigint DEFAULT NULL,
  `phase3` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First First Quarter',
  `stamp3` bigint DEFAULT NULL,
  `phase4` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waxing Gibbous',
  `stamp4` bigint DEFAULT NULL,
  `phase5` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Full Moon',
  `stamp5` bigint DEFAULT NULL,
  `phase6` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waning Gibbous',
  `stamp6` bigint DEFAULT NULL,
  `phase7` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Last Quarter',
  `stamp7` bigint DEFAULT NULL,
  `phase8` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waning Crescent',
  `stamp8` bigint DEFAULT NULL,
  `blue_moon_phase` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na',
  `blue_moon_stamp` bigint DEFAULT NULL COMMENT 'Second Full Moon in this local month',
  `events_json` json NOT NULL COMMENT 'Every event: phase and Unix timestamp, chronological'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `moonsign`
--

CREATE TABLE `moonsign` (
  `recid` int NOT NULL,
  `sign` varchar(255) NOT NULL,
  `deg` varchar(255) NOT NULL,
  `lon` varchar(255) NOT NULL,
  `phase` varchar(255) DEFAULT NULL,
  `phase2` varchar(255) NOT NULL,
  `date` bigint UNSIGNED NOT NULL DEFAULT (unix_timestamp())
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Planets_Retrogrades`
--

CREATE TABLE `Planets_Retrogrades` (
  `id` bigint UNSIGNED NOT NULL,
  `Planet` varchar(20) NOT NULL,
  `Retrograde_Begin` bigint NOT NULL,
  `Direct_Begin` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `Solar_Event`
--

CREATE TABLE `Solar_Event` (
  `id` bigint UNSIGNED NOT NULL,
  `date_inserted` datetime NOT NULL COMMENT 'Insertion date and time in UTC',
  `event` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `unix_timestamp` bigint NOT NULL COMMENT 'Event time in signed Unix seconds'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `summer`
--

CREATE TABLE `summer` (
  `recid` int NOT NULL,
  `years` varchar(255) NOT NULL,
  `months` varchar(255) NOT NULL,
  `weeks` varchar(255) NOT NULL,
  `days` varchar(255) NOT NULL,
  `hours` varchar(255) NOT NULL,
  `minutes` varchar(255) NOT NULL,
  `seconds` varchar(255) NOT NULL,
  `date` varchar(255) NOT NULL,
  `piday` varchar(255) NOT NULL,
  `piday2` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `winter`
--

CREATE TABLE `winter` (
  `recid` int NOT NULL,
  `years` varchar(255) NOT NULL,
  `months` varchar(255) NOT NULL,
  `weeks` varchar(255) NOT NULL,
  `days` varchar(255) NOT NULL,
  `hours` varchar(255) NOT NULL,
  `minutes` varchar(255) NOT NULL,
  `seconds` varchar(255) NOT NULL,
  `date` varchar(255) NOT NULL,
  `piday` varchar(255) NOT NULL,
  `piday2` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `yearphase_new`
--

CREATE TABLE `yearphase_new` (
  `id` bigint UNSIGNED NOT NULL,
  `date` date NOT NULL,
  `phase1` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First New Moon',
  `stamp1` bigint DEFAULT NULL,
  `phase2` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waxing Crescent',
  `stamp2` bigint DEFAULT NULL,
  `phase3` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First First Quarter',
  `stamp3` bigint DEFAULT NULL,
  `phase4` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waxing Gibbous',
  `stamp4` bigint DEFAULT NULL,
  `phase5` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Full Moon',
  `stamp5` bigint DEFAULT NULL,
  `phase6` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waning Gibbous',
  `stamp6` bigint DEFAULT NULL,
  `phase7` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Last Quarter',
  `stamp7` bigint DEFAULT NULL,
  `phase8` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'First Waning Crescent',
  `stamp8` bigint DEFAULT NULL,
  `phase9` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'na' COMMENT 'Blue Moon: second Full Moon',
  `stamp9` bigint DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `CheckPlanets`
--
ALTER TABLE `CheckPlanets`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `mercury`
--
ALTER TABLE `mercury`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `moonphase`
--
ALTER TABLE `moonphase`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `moonphase_new`
--
ALTER TABLE `moonphase_new`
  ADD PRIMARY KEY (`month`);

--
-- Indexes for table `moonsign`
--
ALTER TABLE `moonsign`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `Planets_Retrogrades`
--
ALTER TABLE `Planets_Retrogrades`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_planet_retrograde` (`Planet`,`Retrograde_Begin`);

--
-- Indexes for table `Solar_Event`
--
ALTER TABLE `Solar_Event`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `summer`
--
ALTER TABLE `summer`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `winter`
--
ALTER TABLE `winter`
  ADD PRIMARY KEY (`recid`);

--
-- Indexes for table `yearphase_new`
--
ALTER TABLE `yearphase_new`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `yearphase_new_month` (`date`),
  ADD KEY `yearphase_new_blue_moon` (`phase9`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `CheckPlanets`
--
ALTER TABLE `CheckPlanets`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `mercury`
--
ALTER TABLE `mercury`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `moonphase`
--
ALTER TABLE `moonphase`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `moonsign`
--
ALTER TABLE `moonsign`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Planets_Retrogrades`
--
ALTER TABLE `Planets_Retrogrades`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Solar_Event`
--
ALTER TABLE `Solar_Event`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `summer`
--
ALTER TABLE `summer`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `winter`
--
ALTER TABLE `winter`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `yearphase_new`
--
ALTER TABLE `yearphase_new`
  MODIFY `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
