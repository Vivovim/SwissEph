-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 09, 2026 at 08:02 AM
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
-- Database: `masterbox`
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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `CheckPlanets`
--
ALTER TABLE `CheckPlanets`
  ADD PRIMARY KEY (`recid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `CheckPlanets`
--
ALTER TABLE `CheckPlanets`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
