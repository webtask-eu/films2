<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Получение списка коллекций пользователя
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
        <div class="collection-list">
            <?php if (empty($collections)) { ?>
                <p><?php echo translate('No collections found.'); ?></p>
            <?php } else { ?>
                <?php foreach ($collections as $collection) { ?>
                    <div class="collection-item">
                        <h2><?php echo htmlspecialchars($collection['name']); ?></h2>
                        <p><?php echo translate('Movie Count'); ?>: <?php echo $collection['movie_count']; ?></p>
                        <a href="/collection.php?id=<?php echo $collection['id']; ?>"><?php echo translate('View Collection'); ?></a>
                    </div>
                <?php } ?>
            <?php } ?>
        </div>
    </main>
</body>
</html>