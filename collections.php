<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Получение всех коллекций пользователя
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
        <div class="collections">
            <?php if (!empty($collections)) { ?>
                <?php foreach ($collections as $collection) { ?>
                    <div class="collection">
                        <h2><?php echo $collection['name']; ?></h2>
                        <p><?php echo $collection['description']; ?></p>
                        <a href="/collection.php?id=<?php echo $collection['id']; ?>"><?php echo translate('View Collection'); ?></a>
                    </div>
                <?php } ?>
            <?php } else { ?>
                <p><?php echo translate('You have no collections.'); ?></p>
            <?php } ?>
        </div>
    </main>
</body>
</html>
