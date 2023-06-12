<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/includes/session_start.php';
require_once __DIR__ . '/includes/functions.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Переменные для хранения данных формы
$name = $description = '';
$error_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $name = $_POST['name'];
    $description = $_POST['description'];

    // Валидация данных
    if (empty($name)) {
        $error_message = 'Please enter a name for the collection.';
    } else {
        // Создание новой коллекции
        $result = create_collection($name, $description);
        if ($result['success']) {
            // Перенаправление на страницу коллекции
            redirect('/collection.php?id=' . $result['collection_id']);
        } else {
            $error_message = $result['message'];
        }
    }
}

// Получение коллекций текущего пользователя
$user_id = $_SESSION['user_id'];
$collections = get_user_collections($user_id);
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Collections</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <div class="container">
        <h1>My Collections</h1>
        <h2>Create Collection</h2>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($name); ?>">
            </div>
            <div class="form-group">
                <label for="description">Description:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($description); ?></textarea>
            </div>
            <button type="submit">Create</button>
        </form>
        <h2>My Collections</h2>
        <?php if (!empty($collections)) { ?>
            <ul>
                <?php foreach ($collections as $collection) { ?>
                    <li>
                        <a href="/collection.php?id=<?php echo $collection['id']; ?>">
                            <?php echo $collection['name']; ?>
                        </a>
                    </li>
                <?php } ?>
            </ul>
        <?php } else { ?>
            <p>No collections found.</p>
        <?php } ?>
    </div>
</body>
</html>
