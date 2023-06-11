<?php
session_start();

// Функция для установки языка
function set_language($language) {
    $_SESSION['language'] = $language;
}

// Функция для получения текущего языка
function get_language() {
    return isset($_SESSION['language']) ? $_SESSION['language'] : 'en'; // Здесь 'en' - язык по умолчанию
}

// Функция для установки сообщения об ошибке
function set_error_message($message) {
    $_SESSION['error_message'] = $message;
}

// Функция для получения сообщения об ошибке
function get_error_message() {
    $message = isset($_SESSION['error_message']) ? $_SESSION['error_message'] : '';
    unset($_SESSION['error_message']); // Удаляем сообщение после чтения, чтобы оно не отображалось повторно
    return $message;
}

// Функция для установки сообщения об успехе
function set_success_message($message) {
    $_SESSION['success_message'] = $message;
}

// Функция для получения сообщения об успехе
function get_success_message() {
    $message = isset($_SESSION['success_message']) ? $_SESSION['success_message'] : '';
    unset($_SESSION['success_message']); // Удаляем сообщение после чтения, чтобы оно не отображалось повторно
    return $message;
}

// Проверка, если параметр языка передан в URL, устанавливаем его в сессии
if (isset($_GET['lang'])) {
    $language = $_GET['lang'];
    set_language($language);
}

// Загрузка языкового файла на основе текущего языка
$language = get_language();
$language_file = "private_html/locales/{$language}.php";
if (file_exists($language_file)) {
    require_once $language_file;
}
