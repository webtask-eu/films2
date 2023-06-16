<?php
require_once 'db_connect.php'; // Подключаем файл с подключением к базе данных
require_once '/var/www/vhosts/eveem.in/vendor/autoload.php';

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
// Проверяет, существует ли пользователь с указанным email в базе данных
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

// Для получения информации о пользователе из базы данных
function get_user($userId) {
    global $db;

    try {
        $query = "SELECT * FROM users WHERE id = :userId";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':userId', $userId);
        $stmt->execute();
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $user;
    } catch (PDOException $e) {
        die('Failed to fetch user: ' . $e->getMessage());
    }
}

function login_user_by_email($email, $password) {
    global $db;
    
    // Подготовка запроса для выборки пользователя по электронной почте
    $query = $db->prepare("SELECT * FROM users WHERE email = :email");
    $query->bindParam(':email', $email);
    $query->execute();
    
    // Проверка наличия пользователя в базе данных
    if ($query->rowCount() > 0) {
        $user = $query->fetch(PDO::FETCH_ASSOC);
        
        // Проверка совпадения пароля
        if (password_verify($password, $user['password'])) {
            // Авторизация пользователя
            $_SESSION['user_id'] = $user['id'];
            
            // Возвращаем успешный результат
            return ['success' => true];
        }
    }
    
    // Если авторизация не удалась, возвращаем ошибку
    return ['success' => false, 'message' => 'Invalid email or password.'];
}

/**
 * Получает коллекции пользователя из базы данных.
 *
 * @param int $user_id Идентификатор пользователя
 * @return array Массив с информацией о коллекциях пользователя
 * @throws PDOException Если произошла ошибка при выполнении запроса
 */
function get_user_collections($user_id)
{
    global $db;

    try {
        $query = $db->prepare("SELECT * FROM collections WHERE user_id = :user_id");
        $query->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $query->execute();

        return $query->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        // Обработка ошибки при выполнении запроса
        throw new PDOException('Error retrieving user collections: ' . $e->getMessage());
    }
}

use GuzzleHttp\Client;

// Функция для автоматического перевода текста с помощью Deepl Translate API
function translate_text($text, $targetLanguage) {
    $apiKey = '98289735-7f85-93b8-3d57-5b13159a3689';
    
    $client = new Client();
    
    try {
        $response = $client->request('POST', 'https://api-free.deepl.com/v2/translate', [
            'form_params' => [
                'auth_key' => $apiKey,
                'text' => $text,
                'target_lang' => $targetLanguage,
            ],
        ]);
        
        $data = json_decode($response->getBody(), true);
        
        if (isset($data['translations'][0]['text'])) {
            return $data['translations'][0]['text'];
        } else {
            return $text;
        }
    } catch (Exception $e) {
        // Обработка ошибки перевода
        error_log("Error translating text: " . $e->getMessage());
        return $text;
    }
}


function create_collection($user_id, $movie_id, $language) {
    try {
        global $db;
        
        // Проверка существования пользователя
        $user = get_user($user_id);
        if (!$user) {
            throw new Exception("User does not exist.");
        }
        
        // Проверка существования фильма
        $movie = get_movie($movie_id);
        if (!$movie) {
            throw new Exception("Movie does not exist.");
        }
        
        // Проверка наличия перевода названия коллекции
        $translatedName = translate_text($movie['title'], $language);
        if (empty($translatedName)) {
            throw new Exception("Failed to translate collection name.");
        }
        
        // Вставка новой коллекции в базу данных
        $query = "INSERT INTO collections (user_id, movie_id, language, name) VALUES (:user_id, :movie_id, :language, :name)";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
        $stmt->bindParam(':movie_id', $movie_id, PDO::PARAM_INT);
        $stmt->bindParam(':language', $language, PDO::PARAM_STR);
        $stmt->bindParam(':name', $translatedName, PDO::PARAM_STR);
        $stmt->execute();
        
        return true;
    } catch (Exception $e) {
        return $e->getMessage();
    }
}




/**
 * Получить текущий язык пользователя.
 *
 * @return string Текущий язык пользователя.
 */
function get_current_language()
{
    // Проверяем, есть ли информация о языке в сессии
    if (isset($_SESSION['language'])) {
        return $_SESSION['language'];
    }

    // Если информации о языке в сессии нет, возвращаем язык по умолчанию
    return 'en'; // Здесь вы можете установить ваш язык по умолчанию
}

/**
 * Получить список других языков, исключая текущий язык.
 *
 * @return array Список других языков.
 */
function get_other_languages()
{
    // Предполагаем, что вы храните доступные языки в массиве
    $availableLanguages = ['en', 'ru', 'lv'];

    $currentLanguage = get_current_language();

    // Удалите текущий язык из массива доступных языков
    $otherLanguages = array_diff($availableLanguages, [$currentLanguage]);

    return $otherLanguages;
}

function get_collection($collectionId)
{
    global $db;

    try {
        // Подготовка SQL-запроса
        $query = "SELECT * FROM collections WHERE id = :collection_id";

        // Подготовка и выполнение запроса с использованием подготовленного выражения
        $statement = $db->prepare($query);
        $statement->bindParam(':collection_id', $collectionId, PDO::PARAM_INT);
        $statement->execute();

        // Получение результатов запроса
        $collection = $statement->fetch(PDO::FETCH_ASSOC);

        // Отладочная информация
        echo "SQL Query: " . $query . "<br>";
        echo "Collection ID: " . $collectionId . "<br>";
        echo "Fetched Collection: " . print_r($collection, true) . "<br>";

        return $collection;
    } catch (PDOException $e) {
        // Обработка ошибки запроса
        die('Error executing query: ' . $e->getMessage());
    }
}
