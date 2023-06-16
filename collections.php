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
    <title><?php echo translate('Collection'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/collections.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <div class="collection">
            <?php if (isset($collection['name'])) { ?>
                <h2><?php echo $collection['name']; ?></h2>
            <?php } ?>
            <p><?php echo $collection['description']; ?></p>
            <a href="/collection.php?id=<?php echo $collection['id']; ?>"><?php echo translate('View Collection'); ?></a>
        </div>
    </main>
</body>
</html>     <?php } ?>
        </div>
    </main>
</body>
</html>
