-- phpMyAdmin SQL Dump
-- version 5.2.1deb3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jul 13, 2024 at 01:01 PM
-- Server version: 8.0.37-0ubuntu0.24.04.1
-- PHP Version: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `id-lcm-prd1`
--

-- --------------------------------------------------------

--
-- Table structure for table `penjualan_ikan`
--

CREATE TABLE `penjualan_ikan` (
  `id` int NOT NULL,
  `name` varchar(45) NOT NULL,
  `timestamp` timestamp NOT NULL,
  `price` float NOT NULL,
  `stock` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `penjualan_ikan`
--

INSERT INTO `penjualan_ikan` (`id`, `name`, `timestamp`, `price`, `stock`) VALUES
(1, 'Ikan Gurame', '2024-07-11 21:20:47', 87500, 2099),
(2, 'Ikan Lele', '2024-07-11 21:20:47', 33500, 3548),
(3, 'Ikan Nila', '2024-07-11 21:20:47', 56250, 2545),
(4, 'Ikan Patin', '2024-07-11 21:20:47', 35000, 2200),
(5, 'Ikan Tuna', '2024-07-11 21:20:47', 114600, 1800),
(6, 'Ikan Gurame', '2024-07-11 21:21:47', 87500, 2099),
(7, 'Ikan Lele', '2024-07-11 21:21:47', 33500, 3548),
(8, 'Ikan Nila', '2024-07-11 21:21:47', 56250, 2545),
(9, 'Ikan Patin', '2024-07-11 21:21:47', 35000, 2200),
(10, 'Ikan Tuna', '2024-07-11 21:21:47', 114600, 1800),
(11, 'Ikan Gurame', '2024-07-11 21:22:47', 87500, 2099),
(12, 'Ikan Lele', '2024-07-11 21:22:47', 33500, 3548),
(13, 'Ikan Nila', '2024-07-11 21:22:47', 56250, 2545),
(14, 'Ikan Patin', '2024-07-11 21:22:47', 35000, 2200),
(15, 'Ikan Tuna', '2024-07-11 21:22:47', 114600, 1800),
(16, 'Ikan Gurame', '2024-07-11 21:23:47', 87500, 2099),
(17, 'Ikan Lele', '2024-07-11 21:23:47', 33500, 3548),
(18, 'Ikan Nila', '2024-07-11 21:23:47', 56250, 2545),
(19, 'Ikan Patin', '2024-07-11 21:23:47', 35000, 2200),
(20, 'Ikan Tuna', '2024-07-11 21:23:47', 114600, 1800),
(21, 'Ikan Gurame', '2024-07-11 21:24:47', 87500, 2099),
(22, 'Ikan Lele', '2024-07-11 21:24:47', 33500, 3548),
(23, 'Ikan Nila', '2024-07-11 21:24:47', 56250, 2545),
(24, 'Ikan Patin', '2024-07-11 21:24:47', 35000, 2200),
(25, 'Ikan Tuna', '2024-07-11 21:24:47', 114600, 1800),
(26, 'Ikan Gurame', '2024-07-11 21:25:47', 87500, 2099),
(27, 'Ikan Lele', '2024-07-11 21:25:47', 33500, 3548),
(28, 'Ikan Nila', '2024-07-11 21:25:47', 56250, 2545),
(29, 'Ikan Patin', '2024-07-11 21:25:47', 35000, 2200),
(30, 'Ikan Tuna', '2024-07-11 21:25:47', 114600, 1800),
(31, 'Ikan Gurame', '2024-07-11 21:26:47', 87500, 2099),
(32, 'Ikan Lele', '2024-07-11 21:26:47', 33500, 3548),
(33, 'Ikan Nila', '2024-07-11 21:26:47', 56250, 2545),
(34, 'Ikan Patin', '2024-07-11 21:26:47', 35000, 2200),
(35, 'Ikan Tuna', '2024-07-11 21:26:47', 114600, 1800),
(36, 'Ikan Gurame', '2024-07-11 21:27:47', 87500, 2099),
(37, 'Ikan Lele', '2024-07-11 21:27:47', 33500, 3548),
(38, 'Ikan Nila', '2024-07-11 21:27:47', 56250, 2545),
(39, 'Ikan Patin', '2024-07-11 21:27:47', 35000, 2200),
(40, 'Ikan Tuna', '2024-07-11 21:27:47', 114600, 1800);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `penjualan_ikan`
--
ALTER TABLE `penjualan_ikan`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `penjualan_ikan`
--
ALTER TABLE `penjualan_ikan`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=41;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
