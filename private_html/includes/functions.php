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

// Функция для получения списка последних фильмов
function get_latest_movies() {
    // Здесь вам нужно добавить код для получения списка последних фильмов из базы данных
    // Возвращайте список фильмов в нужном формате, например, в виде массива
}

// Функция для получения имени пользователя
function get_user_name() {
    // Здесь вам нужно добавить код для получения имени пользователя из базы данных или сессии
    // Возвращайте имя пользователя в нужном формате
}

// Функция для получения сообщения об успехе
function get_success_message() {
    // Здесь вам нужно добавить код для получения сообщения об успехе из сессии или другого источника
    // Возвращайте сообщение об успехе в нужном формате
}
