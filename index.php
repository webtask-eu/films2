<?php
require_once __DIR__ . '/config.php';
require_once INCLUDES_PATH . '/session_start.php';
require_once INCLUDES_PATH . '/functions.php';



// Загрузка переводов
$translations = load_translations();

// Получение языка из параметра GET
if (isset($_GET['lang'])) {
    $lang = $_GET['lang'];

    // Установка языка
    set_language($lang);

    // Перенаправление на главную страницу
    redirect('/index.php');
}

// Получение текущего языка
$currentLanguage = get_language();

// Получение последних фильмов
$latestMovies = get_latest_movies();

// Получение сообщения об ошибке
$error_message = get_error_message();

// Получение сообщения об успехе
$success_message = get_success_message();
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Film Collection'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <nav>
            <div class="logo">
                <a href="/index.php"><?php echo translate('Film Collection'); ?></a>
            </div>
            <ul class="menu">
                <li><a href="/index.php"><?php echo translate('Home'); ?></a></li>
                <?php if (is_logged_in()) { ?>
                    <li><a href="/collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
                <?php } else { ?>
                    <li><a href="/register.php"><?php echo translate('Register'); ?></a></li>
                    <li><a href="/login.php"><?php echo translate('Login'); ?></a></li>
                <?php } ?>
            </ul>
            <ul class="language">
                <li><a href="?lang=en">EN</a></li>
                <li><a href="?lang=lv">LV</a></li>
                <li><a href="?lang=ru">RU</a></li>
            </ul>
        </nav>
    </header>
    <main>
        <h1><?php echo translate('Latest Movies'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <?php if ($success_message) { ?>
            <p class="success"><?php echo $success_message; ?></p>
        <?php } ?>
        <?php if (!empty($latestMovies)) { ?>
            <ul>
                <?php foreach ($latestMovies as $movie) { ?>
                    <li><?php echo $movie; ?></li>
                <?php } ?>
            </ul>
        <?php } else { ?>
            <p><?php echo translate('No movies found.'); ?></p>
        <?php } ?>
    </main>
</body>
</html>
