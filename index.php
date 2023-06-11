<?php
require_once 'private_html/includes/session_start.php';
require_once 'private_html/includes/db_connect.php';
require_once 'private_html/includes/functions.php';

try {
    // Проверяем, если параметр языка передан в URL, устанавливаем его в сессии
    if (isset($_GET['lang'])) {
        $language = $_GET['lang'];
        set_language($language);
        redirect($_SERVER['PHP_SELF']);
    }

    // Получаем список последних фильмов
    $movies = get_latest_movies();

} catch (Exception $e) {
    echo 'Error: ' . $e->getMessage();
    exit();
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Film Collection</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <nav>
        <ul>
            <li><a href="collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
            <?php if (is_logged_in()): ?>
                <li><a href="logout.php"><?php echo translate('Logout'); ?></a></li>
            <?php else: ?>
                <li><a href="register.php"><?php echo translate('Register'); ?></a></li>
                <li><a href="login.php"><?php echo translate('Login'); ?></a></li>
            <?php endif; ?>
            <li>
                <a href="?lang=en">English</a>
                <a href="?lang=lv">Latvian</a>
                <a href="?lang=ru">Russian</a>
            </li>
        </ul>
    </nav>

    <h1><?php echo translate('Welcome to My Film Collection!'); ?></h1>

    <?php if (is_logged_in()): ?>
        <p><?php echo sprintf(translate('Welcome, %s!'), get_user_name()); ?></p>
    <?php endif; ?>

    <h2><?php echo translate('Latest Movies'); ?></h2>
    <ul>
        <?php foreach ($movies as $movie): ?>
            <li><?php echo $movie['title']; ?> (<?php echo $movie['release_year']; ?>)</li>
        <?php endforeach; ?>
    </ul>

    <?php if (get_error_message()): ?>
        <p><?php echo get_error_message(); ?></p>
    <?php endif; ?>

    <?php if (get_success_message()): ?>
        <p><?php echo get_success_message(); ?></p>
    <?php endif; ?>

    <h3>Debug Info:</h3>
    <pre>
        <?php var_dump($_SESSION); ?>
        <?php var_dump($_GET); ?>
    </pre>

</body>
</html>
