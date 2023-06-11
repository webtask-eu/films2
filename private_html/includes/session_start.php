<?php
// Функция для начала сессии
function start_session() {
    if (session_status() == PHP_SESSION_NONE) {
        session_start();
    }
}

// Запускаем сессию
start_session();
?>
