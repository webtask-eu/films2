<?php
define('PRIVATE_PATH', __DIR__ . '/private_html');
define('INCLUDES_PATH', PRIVATE_PATH . '/includes');
define('LOCALES_PATH', PRIVATE_PATH . '/../locales');

// Подключение файла session_start.php
require_once INCLUDES_PATH . '/session_start.php';

// Подключение файла functions.php
require_once INCLUDES_PATH . '/functions.php';

// Включение отображения ошибок в PHP
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);
