<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Получение коллекции по ее ID
$collectionId = $_GET['id'];
$collection = get_collection($collectionId);

// Проверка, принадлежит ли коллекция текущему пользователю
if ($collection['user_id'] !== $_SESSION['user_id']) {
    // Если коллекция не принадлежит текущему пользователю, перенаправляем на страницу с ошибкой доступа
    redirect('/error.php?message=Access denied.');
}

// Обработка удаления коллекции
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_collection'])) {
    // Удаление коллекции
    delete_collection($collectionId);

    // Перенаправление на страницу со списком коллекций пользователя
    redirect('/my_collections.php');
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Collection</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/login.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <div class="container">
            <h1>Collection</h1>
            <p>ID: <?php echo $collection['id']; ?></p>
            <p>Name: <?php echo $collection['name']; ?></p>
            <p>Description: <?php echo $collection['description']; ?></p>

            <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
                <input type="hidden" name="collection_id" value="<?php echo $collection['id']; ?>">
                <button type="submit" name="delete_collection">Delete Collection</button>
            </form>
        </div>
    </main>
</body>
</html>
