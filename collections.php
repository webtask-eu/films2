<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Получение коллекций пользователя
$user_id = $_SESSION['user_id'];
$collections = get_user_collections($user_id);

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('My Collections'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/collections.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <h1><?php echo translate('My Collections'); ?></h1>
        <?php if (count($collections) > 0) { ?>
            <ul class="collection-list">
                <?php foreach ($collections as $collection) { ?>
                    <li>
                        <a href="/collection.php?id=<?php echo $collection['id']; ?>">
                            <div class="collection-details">
                                <h2><?php echo $collection['name']; ?></h2>
                                <p><?php echo translate('Movie Count'); ?>: <?php echo isset($collection['movie_count']) ? $collection['movie_count'] : 0; ?></p>
                            </div>
                        </a>
                    </li>
                <?php } ?>
            </ul>
        <?php } else { ?>
            <p><?php echo translate('No collections found.'); ?></p>
        <?php } ?>
    </main>
</body>
</html>
