<?php
define('PRIVATE_PATH', __DIR__ . '/private_html');
define('INCLUDES_PATH', PRIVATE_PATH . '/includes');
define('LOCALES_PATH', PRIVATE_PATH . '/../locales');

// Включение отображения ошибок в PHP
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
