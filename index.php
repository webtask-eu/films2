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
    <ul>
      <li class="menu-items center"><a href="/register.php"><?php echo translate('Register'); ?></a></li>
      <li class="menu-items center"><a href="/login.php"><?php echo translate('Login'); ?></a></li>
      <li class="menu-items language"><a href="<?php echo update_query_param('lang', 'en'); ?>">EN</a></li>
      <li class="menu-items language"><a href="<?php echo update_query_param('lang', 'lv'); ?>">LV</a></li>
      <li class="menu-items language"><a href="<?php echo update_query_param('lang', 'ru'); ?>">RU</a></li>
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
        <ul class="movie-list">
            <?php foreach ($latestMovies as $movie) { ?>
                <li><?php echo $movie['title']; ?></li>
            <?php } ?>
        </ul>
    <?php } else { ?>
        <p><?php echo translate('No movies found.'); ?></p>
    <?php } ?>

    <!-- Debug Info -->
    <pre>
        <?php //var_dump($latestMovies); ?>
    </pre>
</main>

</body>
</html>
