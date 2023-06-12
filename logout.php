<?php
require_once __DIR__ . '/config.php';

// Удаление данных сессии
session_unset();
session_destroy();

// Перенаправление на страницу входа после выхода
redirect('/login.php');
?>
