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

// Функция для добавления параметра к URL
function add_query_param($url, $param, $value) {
    $separator = (parse_url($url, PHP_URL_QUERY) == NULL) ? '?' : '&';
    return $url . $separator . urlencode($param) . '=' . urlencode($value);
}

// Функция для получения имени пользователя
function get_user_name() {
    // Здесь должна быть логика получения имени пользователя
    // Замените этот код на вашу реализацию
    return 'User';
}

// Функция для проверки авторизации пользователя
function is_logged_in() {
    // Здесь должна быть логика проверки авторизации пользователя
    // Замените этот код на вашу реализацию
    return false;
}
