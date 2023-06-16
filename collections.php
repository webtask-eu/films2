<?php
require_once __DIR__ . '/config.php';

// Получение ID коллекции из параметров запроса
$collection_id = $_GET['id'];

// Получение информации о коллекции
$collection = get_collection($collection_id);

// Проверка, если коллекция не найдена, перенаправляем на страницу ошибки
if (!$collection) {
    redirect('/error.php');
}

// Debug Info
// var_dump($collection);

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
</html>
