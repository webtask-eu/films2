<?php
require_once 'private_html/includes/session_start.php';
require_once 'private_html/includes/db_connect.php';
require_once 'private_html/includes/functions.php';

// Получаем последние добавленные фильмы из базы данных
$query = "SELECT * FROM movies ORDER BY id DESC LIMIT 10";
$stmt = $db->query($query);
$movies = $stmt->fetchAll(PDO::FETCH_ASSOC);

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Film Collection</title>
    <link rel="stylesheet" href="public_html/css/style.css">
</head>
<body>
    <nav>
        <ul>
            <li><a href="public_html/collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
            <?php if (is_logged_in()): ?>
                <li><a href="public_html/logout.php"><?php echo translate('Logout'); ?></a></li>
            <?php else: ?>
                <li><a href="public_html/register.php"><?php echo translate('Register'); ?></a></li>
                <li><a href="public_html/login.php"><?php echo translate('Login'); ?></a></li>
            <?php endif; ?>
            <li>
            <a href="<?php echo update_query_param('lang', 'en'); ?>">English</a>
            <a href="<?php echo update_query_param('lang', 'lv'); ?>">Latvian</a>
            <a href="<?php echo update_query_param('lang', 'ru'); ?>">Russian</a>

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

</body>
</html>
