-- Base ESX owned vehicles table (skip if your framework already has it).
CREATE TABLE IF NOT EXISTS `owned_vehicles` (
    `owner` VARCHAR(60) NOT NULL,
    `plate` VARCHAR(12) NOT NULL,
    `vehicle` LONGTEXT,
    `type` VARCHAR(20) NOT NULL DEFAULT 'car',
    `job` VARCHAR(20) NULL DEFAULT NULL,
    `stored` TINYINT(1) NOT NULL DEFAULT '0',
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Player created categories (folders) for sorting their vehicles.
CREATE TABLE IF NOT EXISTS `garage_categories` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NOT NULL,
    `name` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Which category a vehicle belongs to (one category per plate).
CREATE TABLE IF NOT EXISTS `garage_vehicle_category` (
    `plate` VARCHAR(12) NOT NULL,
    `category_id` INT NOT NULL,
    PRIMARY KEY (`plate`),
    INDEX `idx_category` (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vehicles shared with another player (shared_with = target identifier).
CREATE TABLE IF NOT EXISTS `garage_shared` (
    `plate` VARCHAR(12) NOT NULL,
    `shared_with` VARCHAR(60) NOT NULL,
    PRIMARY KEY (`plate`, `shared_with`),
    INDEX `idx_shared_with` (`shared_with`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
