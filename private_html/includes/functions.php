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


function create_collection($name, $description, $user_id)
{
    try {
        global $db;

        $query = "INSERT INTO collections (name, description, user_id) VALUES (:name, :description, :user_id)";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':name', $name);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();

        return $db->lastInsertId();
    } catch (PDOException $e) {
        // Записываем ошибку в лог файл
        error_log('Failed to create collection: ' . $e->getMessage());

        // Пробрасываем исключение дальше
        throw new Exception('Failed to create collection. Please try again.');
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


// Функция для добавления фильма в коллекцию
function add_movie_to_collection($collection_id, $title, $description, $posterPath)
{
    try {
        global $db;

        // Добавление фильма в коллекцию
        $query = "INSERT INTO movies (title, description, collection_id, poster_path) VALUES (:title, :description, :collection_id, :poster_path)";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':collection_id', $collection_id); // Добавлено: передача значения 'collection_id'
        $stmt->bindParam(':poster_path', $poster_path); // Добавлено: передача значения 'poster_path'
        $stmt->execute();
    } catch (PDOException $e) {
        // Выводим отладочную информацию
        echo 'Error Message: ' . $e->getMessage();
        // Или записываем ошибку в лог файл
        // error_log('Failed to add movie to collection: ' . $e->getMessage());

        // Пробрасываем исключение дальше
        throw new Exception('Failed to add movie to collection: ' . $e->getMessage());
    }
}

// Получение списка фильмов
function get_movies() {
    try {
        global $db;

        $query = "SELECT id, title, description, release_year, language FROM movies";
        $stmt = $db->query($query);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        throw new Exception('Failed to get movies: ' . $e->getMessage());
    }
}

function get_user_collections()
{
    global $db;

    try {
        $user_id = get_current_user_id();

       // echo '$user_id: ' . $user_id ;

        $query = "SELECT * FROM collections WHERE user_id = :user_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        // Выводим отладочную информацию
        echo 'Error Message: ' . $e->getMessage();
        // Или записываем ошибку в лог файл
        // error_log('Failed to get user collections: ' . $e->getMessage());

        // Возвращаем пустой массив в случае ошибки
        return [];
    }
}


function get_current_user_id()
{
    if (!is_logged_in()) {
        // Если пользователь не авторизован, выбрасываем исключение
        throw new Exception('User not logged in.');
    }

    try {
        global $db;

        // Получение ID текущего пользователя
        $user_id = $_SESSION['user_id'];
        $query = "SELECT id FROM users WHERE id = :user_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();

        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$result) {
            throw new Exception('User not found.');
        }

        return $result['id'];
    } catch (PDOException $e) {
        // Выводим отладочную информацию
        echo 'Error Message: ' . $e->getMessage();
        // Или записываем ошибку в лог файл
        // error_log('Failed to get current user ID: ' . $e->getMessage());

        // Пробрасываем исключение дальше
        throw new Exception('Failed to get current user ID: ' . $e->getMessage());
    }
}

function get_collection_movies($collection_id)
{
    try {
        global $db;

        $query = "SELECT * FROM movies WHERE collection_id = :collection_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':collection_id', $collection_id);
        $stmt->execute();

        $movies = $stmt->fetchAll(PDO::FETCH_ASSOC);
        return $movies;
    } catch (PDOException $e) {
        throw new Exception('Failed to get collection movies: ' . $e->getMessage());
    }
}
