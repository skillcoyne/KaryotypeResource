DROP DATABASE `cancer_karyotypes`;
CREATE DATABASE `cancer_karyotypes` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `cancer_karyotypes`;

CREATE TABLE `karyotypes` (
  `karyotype_id` int(11) NOT NULL AUTO_INCREMENT,
  `source_id` int(11) NOT NULL,
  `source_type` ENUM('patient', 'cell line') NOT NULL,
  `karyotype` text NOT NULL,
  PRIMARY KEY (`karyotype_id`)
);

CREATE TABLE `karyotype_source` (
  `source_id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(112) NOT NULL,
  `source_short` varchar(12) NOT NULL,
  `url` text,
  `description` text,
  PRIMARY KEY(`source_id`)
);

CREATE TABLE `cancer` (
  `cancer_id` int(11) NOT NULL AUTO_INCREMENT,
  `cancer` text NOT NULL,
  `cancer_short` varchar(32) NOT NULL,
  PRIMARY KEY(`cancer_id`)
);

CREATE TABLE `cancer_karyotype` (
  `karyotype_id` int(11) NOT NULL,
  `cancer_id` int(11) NOT NULL
);

CREATE TABLE `breakpoints` (
  `breakpoint_id` int(11) NOT NULL AUTO_INCREMENT,
  `breakpoint` varchar(32) NOT NULL,
  PRIMARY KEY (`breakpoint_id`)
);

CREATE TABLE `breakpoint_karyotype` (
  `breakpoint_id` int(11) NOT NULL,
  `karyotype_id int(11) NOT NULL
);


CREATE TABLE `aberrations` (
  `aberration_id` int(11) NOT NULL AUTO_INCREMENT,
  `aberration` text NOT NULL,
  PRIMARY KEY (`aberration_id`)
);

CREATE TABLE `karyotype_aberration` (
  `karotype_id` int(11) NOT NULL,
  `aberration_id` int(11) NOT NULL
);





