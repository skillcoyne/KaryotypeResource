DROP DATABASE `cancer_karyotypes`;
CREATE DATABASE `cancer_karyotypes`;

USE `cancer_karyotypes`;

CREATE TABLE `karyotypes` (
  `karyotype_id` int(11) NOT NULL AUTO_INCREMENT,
  `source_id` int(11) NOT NULL,
  `source_type` ENUM('patient', 'cell line') NOT NULL,
  `karyotype` text NOT NULL,
  `cell_line_id` int(11),
  PRIMARY KEY (`karyotype_id`)
);

CREATE TABLE `karyotype_source` (
  `source_id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(112) NOT NULL,
  `source_short` varchar(12) NOT NULL,
  `url` text,
  `description` text,
  `date_accessed` DATETIME NOT NULL
  PRIMARY KEY(`source_id`)
);

CREATE TABLE `cancer` (
  `cancer_id` int(11) NOT NULL AUTO_INCREMENT,
  `cancer` text NOT NULL,
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
  `karyotype_id` int(11) NOT NULL
);

CREATE TABLE `aberrations` (
  `aberration_id` int(11) NOT NULL AUTO_INCREMENT,
  `aberration_class` varchar(32) NOT NULL,
  `aberration` text NOT NULL,
  PRIMARY KEY (`aberration_id`)
);

CREATE TABLE `karyotype_aberration` (
  `karyotype_id` int(11) NOT NULL,
  `aberration_id` int(11) NOT NULL
);

CREATE TABLE `cancer_lookup` (
  `name` varchar(256) NOT NULL,
  `translation` varchar(112) NOT NULL
);

CREATE TABLE `cell_lines` (
  `cell_line_id` int(11) NOT NULL AUTO_INCREMENT,
  `cell_line` varchar(32) NOT NULL,
  PRIMARY KEY(`cell_line_id`)
);

CREATE TABLE `chromosome_bands` (
  `chromosome` varchar(12) NOT NULL,
  `band` varchar(12) NOT NULL,
  `start` int(112) NOT NULL,
  `end` int(112) NOT NULL
);


