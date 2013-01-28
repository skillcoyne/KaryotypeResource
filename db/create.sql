DROP DATABASE `cancer_karyotypes`;
CREATE DATABASE `cancer_karyotypes`;

USE `cancer_karyotypes`;

CREATE TABLE `karyotypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `karyotype_source_id` int(11) NOT NULL,
  `source_type` ENUM('patient', 'cell line') NOT NULL,
  `karyotype` text NOT NULL,
  `cell_line_id` int(11),
  `descriptions` TEXT,
  `karyotype_count` int(11) NOT NULL,
  PRIMARY KEY (`karyotype_id`)
);

CREATE TABLE `karyotype_source` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(112) NOT NULL,
  `source_short` varchar(12) NOT NULL,
  `url` text,
  `description` text,
  `date_accessed` DATETIME NOT NULL
  PRIMARY KEY(`id`, `source`)
);

CREATE TABLE `cancer` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  PRIMARY KEY(`id`, `name`)
);

CREATE TABLE `cancers_karyotypes` (
  `karyotype_id` int(11) NOT NULL,
  `cancer_id` int(11) NOT NULL,
  PRIMARY KEY(`karyotype_id`, `cancer_id`),
  foreign key (karyotype_id) references karyotypes(id),
  foreign key (cancer_id)  references cancer(id)
);

CREATE TABLE `breakpoints` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `breakpoint` varchar(32) NOT NULL,
  PRIMARY KEY (`breakpoint_id`)
);

CREATE TABLE `breakpoints_karyotypes` (
  `breakpoint_id` int(11) NOT NULL,
  `karyotype_id` int(11) NOT NULL,
  PRIMARY KEY(`breakpoint_id`, `karyotype_id`),
    foreign key(`breakpoint_id`) references breakpoints(id)
    foreign key(`karyotype_id`) references karyotypes(id)
);

CREATE TABLE `aberrations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `aberration_class` varchar(32) NOT NULL,
  `aberration` text NOT NULL,
  PRIMARY KEY (`aberration_id`)
);

CREATE TABLE `abberations_karyotypes` (
  `karyotype_id` int(11) NOT NULL,
  `aberration_id` int(11) NOT NULL,
    PRIMARY KEY(`aberration_id`, `karyotype_id`),
    foreign key(`aberration_id`) references aberrations(id)
    foreign key(`karyotype_id`) references karyotypes(id)
);

CREATE TABLE `cancer_lookup` (
  `name` varchar(256) NOT NULL,
  `translation` varchar(112) NOT NULL
);

CREATE TABLE `cell_lines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `description` TEXT,
  PRIMARY KEY(`id`, `name`)
);

CREATE TABLE `chromosome_bands` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `chromosome` varchar(12) NOT NULL,
  `band` varchar(12) NOT NULL,
  `start` int(112) NOT NULL,
  `end` int(112) NOT NULL,
  PRIMARY KEY(`id`, `chromosome`, `band`)
);


