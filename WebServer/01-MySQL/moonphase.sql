-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Sep 09, 2026 at 02:11 AM
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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `moonphase`
--
ALTER TABLE `moonphase`
  ADD PRIMARY KEY (`recid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `moonphase`
--
ALTER TABLE `moonphase`
  MODIFY `recid` int NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
