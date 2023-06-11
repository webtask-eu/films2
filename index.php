<?php
require_once 'private_html/includes/session_start.php';
require_once 'private_html/includes/db_connect.php';
require_once 'private_html/includes/functions.php';

// Получаем последние добавленные фильмы из базы данных
$query = "SELECT * FROM movies ORDER BY id DESC LIMIT 10";
$stmt = $db->query($query);
$movies = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Получаем текущий язык
$language = get_language();

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

    <h1>Welcome to My Film Collection!</h1>

    <?php if (is_logged_in()): ?>
        <p>Welcome, User! <!-- Replace "User" with the actual user's name --></p>
    <?php endif; ?>

    <h2>Latest Movies</h2>
    <ul>
        <?php foreach ($movies as $movie): ?>
            <li><?php echo $movie['title']; ?> (<?php echo $movie['release_year']; ?>)</li>
        <?php endforeach; ?>
    </ul>

    <script src="js/script.js"></script>
</body>
</html>
