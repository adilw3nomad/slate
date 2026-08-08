CREATE TABLE `schema_migrations`(`filename` varchar(255) NOT NULL PRIMARY KEY);
CREATE TABLE `menu_items`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(255),
  `price_cents` integer DEFAULT(0) NOT NULL,
  `available` boolean DEFAULT(1) NOT NULL,
  `created_at` timestamp NOT NULL,
  `updated_at` timestamp NOT NULL
);
CREATE TABLE `scheduled_changes`(
  `id` integer NOT NULL PRIMARY KEY AUTOINCREMENT,
  `target_type` varchar(255) NOT NULL,
  `target_id` integer NOT NULL,
  `new_values` varchar(255) NOT NULL,
  `apply_at` timestamp,
  `status` varchar(255) DEFAULT('pending') NOT NULL,
  `created_at` timestamp NOT NULL,
  `applied_at` timestamp
  ,
  `base_values` varchar(255),
  `expires_at` timestamp,
  `attempts` integer DEFAULT(0) NOT NULL,
  `last_error` varchar(255),
  `locked_at` timestamp,
  `locked_by` varchar(255),
  `next_run_at` timestamp,
  `author_id` integer,
  `applied_by` integer
);
CREATE INDEX `scheduled_changes_status_apply_at_index` ON `scheduled_changes`(
  `status`,
  `apply_at`
);
INSERT INTO schema_migrations (filename) VALUES
('20260808172639_create_menu_items.rb'),
('20260808172640_create_scheduled_changes.rb'),
('20260808194814_add_scheduling_columns_to_scheduled_changes.rb');
