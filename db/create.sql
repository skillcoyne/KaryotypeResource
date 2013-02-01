DROP DATABASE `cancer_karyotypes`;
CREATE DATABASE `cancer_karyotypes`;

USE `cancer_karyotypes`;

CREATE TABLE `karyotypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `karyotype_source_id` int(11) NOT NULL,
  `source_type` ENUM('patient', 'cell line') NOT NULL,
  `karyotype` text NOT NULL,
  `cell_line_id` int(11),
  `description` TEXT,
  PRIMARY KEY (`id`),
  INDEX ksindex (`id`,`karyotype_source_id`),
    FOREIGN KEY (`id`,`karyotype_source_id`) REFERENCES karyotypes(`id`, `karyotype_source_id`),
  INDEX kcellindex (`id`, `cell_line_id`),
    FOREIGN KEY (`id`, `cell_line_id`) REFERENCES karyotypes(`id`, `cell_line_id`)
);

CREATE TABLE `karyotype_source` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(112) NOT NULL,
  `source_short` varchar(12) NOT NULL,
  `url` text,
  `description` text,
  `date_accessed` DATETIME NOT NULL,
  `karyotype_count` INT(11) NOT NULL,
  PRIMARY KEY(`id`)
);

CREATE TABLE `cancer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  PRIMARY KEY(`id`),
  INDEX c_index (`id`, `name`(12))
);

CREATE TABLE `cancers_karyotypes` (
  `karyotype_id` int(11) NOT NULL,
  `cancer_id` int(11) NOT NULL,
  INDEX ck_index (`karyotype_id`, `cancer_id`)
);

CREATE TABLE `breakpoints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `breakpoint` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX bp_index (`id`,`breakpoint`)
);

CREATE TABLE `breakpoints_karyotypes` (
  `breakpoint_id` int(11) NOT NULL,
  `karyotype_id` int(11) NOT NULL,
  INDEX bpk_index (`breakpoint_id`, `karyotype_id`)
);

CREATE TABLE `aberrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `aberration_class` varchar(32) NOT NULL,
  `aberration` text NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `aberrations_breakpoints` (
  `aberration_id` int(11) NOT NULL,
  `breakpoint_id` int(11) NOT NULL,
  INDEX abbp_index (`aberration_id`, `breakpoint_id`)
);

CREATE TABLE `aberrations_karyotypes` (
  `karyotype_id` int(11) NOT NULL,
  `aberration_id` int(11) NOT NULL,
  INDEX abk_index (`karyotype_id`, `aberration_id`)
);

CREATE TABLE `cancer_lookup` (
  `name` varchar(256) NOT NULL,
  `translation` varchar(112) NOT NULL
);

CREATE TABLE `cell_lines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `description` TEXT,
  PRIMARY KEY(`id`),
  INDEX cl_index (`id`,`name`)
);

CREATE TABLE `chromosome_bands` (
  `chromosome` varchar(12) NOT NULL,
  `band` varchar(12) NOT NULL,
  `start` int(112) NOT NULL,
  `end` int(112) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY(`id`)
);


