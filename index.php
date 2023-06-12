<?php
require_once __DIR__ . '/config.php';

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
    <?php if (is_logged_in()) { ?>
        <link rel="stylesheet" href="/css/submenu.css">
    <?php } ?>
</head>
<body>
<header>
    <?php include_once __DIR__ . '/menu.php'; ?>
    <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/menu.php'; ?>    
    <?php } ?>

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
