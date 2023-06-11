<?php
// Функция для проверки, авторизован ли пользователь
function is_logged_in() {
    return isset($_SESSION['user_id']);
}

// Функция для перенаправления пользователя на другую страницу
function redirect($url) {
    header("Location: $url");
    exit();
}

// Функция для вывода сообщения об ошибке
function display_error($message) {
    echo '<div class="error">' . $message . '</div>';
}

// Функция для вывода сообщения об успехе
function display_success($message) {
    echo '<div class="success">' . $message . '</div>';
}

// Функция для очистки ввода от потенциально опасных символов
function sanitize_input($input) {
    return htmlspecialchars(trim($input), ENT_QUOTES, 'UTF-8');
}

// Функция для проверки длины пароля
function is_valid_password($password) {
    $min_length = 6;
    $max_length = 255;
    $password_length = strlen($password);
    return $password_length >= $min_length && $password_length <= $max_length;
}

// Функция для генерации хеша пароля
function generate_password_hash($password) {
    return password_hash($password, PASSWORD_DEFAULT);
}

// Функция для проверки соответствия пароля и хеша
function verify_password_hash($password, $hash) {
    return password_verify($password, $hash);
}

// Функция для генерации случайной строки
function generate_random_string($length = 8) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $characters_length = strlen($characters);
    $random_string = '';
    for ($i = 0; $i < $length; $i++) {
        $random_string .= $characters[rand(0, $characters_length - 1)];
    }
    return $random_string;
}

// Функция для перевода текстовых строк
function translate($text) {
    $language = get_language();

    // Загружаем файл с переводами для текущего языка
    $translation_file = "locales/{$language}.php";
    if (file_exists($translation_file)) {
        require_once $translation_file;

        // Проверяем, есть ли перевод для указанного текста
        if (isset($translations[$text])) {
            return $translations[$text];
        }
    }

    // Если перевод не найден, возвращаем исходный текст
    return $text;
}
