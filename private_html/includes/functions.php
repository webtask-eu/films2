<?php
// Функция для перевода текста
function translate($text) {
    global $translations;
    $language = get_language();

    if (isset($translations[$language]) && isset($translations[$language][$text])) {
        return $translations[$language][$text];
    }

    return $text; // Возвращаем оригинальный текст, если перевод не найден
}

// Функция для обновления параметра в URL
function update_query_param($param, $value) {
    $query = $_GET;
    $query[$param] = $value;
    return '?' . http_build_query($query);
}

// Функция для перенаправления на другую страницу
function redirect($url) {
    header("Location: $url");
    exit();
}

// Функция для проверки авторизации пользователя
function is_logged_in() {
    return isset($_SESSION['user_id']);
}
