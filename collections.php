<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Получение списка коллекций пользователя
try {
    $collections = get_user_collections();
} catch (Exception $e) {
    $error_message = 'Failed to get user collections: ' . $e->getMessage();
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Collections</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/collections.css">
    <link rel="stylesheet" href="/css/submenu.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
        <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/submenu.php'; ?>    
        <?php } ?>
    </header>
    <main>
        <h1>My Collections</h1>
        <?php if (!empty($error_message)) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } else { ?>
            <?php if (empty($collections)) { ?>
                <p>You don't have any collections. <a href="/collection_create.php">Create a collection</a></p>
            <?php } else { ?>
                <?php foreach ($collections as $collection) { ?>
                    <h2><?php echo $collection['name']; ?></h2>
                    <?php
                    try {
                        echo $collection['id'];
                        $movies = get_collection_movies($collection['id']);
                    } catch (Exception $e) {
                        $error_message = 'Failed to get collection movies: ' . $e->getMessage();
                    }
                    ?>
                    <?php if (!empty($movies)) { ?>
                        <ul>
                            <?php foreach ($movies as $movie) { ?>
                                <li><?php echo $movie['title']; ?></li>
                            <?php } ?>
                        </ul>
                    <?php } else { ?>
                        <p>No movies in this collection.</p>
                    <?php } ?>
                <?php } ?>
            <?php } ?>
        <?php } ?>
    </main>
</body>
</html>
