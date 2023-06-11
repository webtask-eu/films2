<?php
require_once 'db_connect.php';

// Начинаем сессию
session_start();

// Функция для установки языка
function set_language($language) {
    if (in_array($language, ['en', 'lv', 'ru'])) {
        $_SESSION['language'] = $language;
    }
}

// Функция для получения языка
function get_language() {
    return $_SESSION['language'] ?? 'en';
}

// Функция для получения сообщения об успехе
function get_success_message() {
    return $_SESSION['success_message'] ?? '';
}

// Очищаем сообщение об успехе
function clear_success_message() {
    unset($_SESSION['success_message']);
}

// Функция для установки сообщения об ошибке
function set_error_message($message) {
    $_SESSION['error_message'] = $message;
}

// Функция для получения сообщения об ошибке
function get_error_message() {
    return $_SESSION['error_message'] ?? '';
}

// Очищаем сообщение об ошибке
function clear_error_message() {
    unset($_SESSION['error_message']);
}
