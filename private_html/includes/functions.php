<?php
require_once 'db_connect.php'; // Подключаем файл с подключением к базе данных

// Функция для перевода текста
function translate($text) {
    global $translations;
    $language = get_language();

    if (isset($translations[$language]) && isset($translations[$language][$text])) {
        return $translations[$language][$text];
    } else {
        echo "Translation not found for text: $text, language: $language";
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

// Функция для установки языка
function set_language($language) {
    $_SESSION['language'] = $language;
}

// Функция для получения текущего языка
function get_language() {
    if (isset($_SESSION['language'])) {
        return $_SESSION['language'];
    } else {
        // Здесь вы можете установить язык по умолчанию
        return 'en';
    }
}

// Функция для проверки авторизации пользователя
function is_logged_in() {
    return isset($_SESSION['user_id']);
}

// Функция для получения списка последних фильмов
function get_latest_movies() {
    global $db;

    try {
        // Выборка последних 10 фильмов из базы данных
        $query = 'SELECT * FROM movies ORDER BY id DESC LIMIT 10';
        $statement = $db->query($query);
        $movies = $statement->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        // В случае ошибки выборки вывести сообщение об ошибке
        die('Failed to get latest movies: ' . $e->getMessage());
    }

    return $movies;
}



// Функция для получения имени пользователя
function get_user_name() {
    // Здесь вам нужно добавить код для получения имени пользователя из базы данных или сессии
    // Возвращайте имя пользователя в нужном формате
}

// Функция для получения сообщения об ошибке
function get_error_message() {
    if (isset($_SESSION['error_message'])) {
        $message = $_SESSION['error_message'];
        unset($_SESSION['error_message']);
        return $message;
    }
    return '';
}

// Функция для получения сообщения об успехе
function get_success_message() {
    if (isset($_SESSION['success_message'])) {
        $message = $_SESSION['success_message'];
        unset($_SESSION['success_message']);
        return $message;
    }
    return '';
}

// Загрузка файлов локализации
function load_translations() {
    $language = get_language();
    $translations = [];

    // Путь до файлов с локализацией
    $localePath = __DIR__ . '/../locales/';

    // Загрузка файлов локализации
    $translationFiles = glob($localePath . '*.php');
    foreach ($translationFiles as $file) {
        $langCode = basename($file, '.php');
        if (file_exists($file)) {
            $translations[$langCode] = include $file;
        } else {
            echo "Localization file not found: $file";
        }
    }
/*
    // Отладочная информация
    echo $localePath . "<br>";
    echo "<pre>";
    echo "Debug Info:\n";
    echo "Translations:\n";
    print_r($translations);
    echo "Translation Files:\n";
    print_r($translationFiles);
    echo "</pre>";
*/
    return $translations;
}

// Загрузка переводов
$translations = load_translations();

function create_user($name, $email, $password) {
    global $db;

    try {
        // Хэширование пароля
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

        // Подготовка SQL-запроса
        $stmt = $db->prepare("INSERT INTO users (name, email, password) VALUES (:name, :email, :password)");

        // Привязка параметров
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':email', $email);
        $stmt->bindParam(':password', $hashedPassword);

        // Выполнение запроса
        $stmt->execute();

        // Возвращаем ID нового пользователя
        return $db->lastInsertId();
    } catch (PDOException $e) {
        // Обработка ошибки
        echo 'Error creating user: ' . $e->getMessage();
        exit();
    }
}

function user_exists($email) {
    global $db;

    try {
        $stmt = $db->prepare("SELECT COUNT(*) FROM users WHERE email = :email");
        $stmt->bindParam(':email', $email);
        $stmt->execute();

        $count = $stmt->fetchColumn();

        return ($count > 0);
    } catch (PDOException $e) {
        die('Database error: ' . $e->getMessage());
    }
}
