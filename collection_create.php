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
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Collection</title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <div class="container">
        <h1>Create Collection</h1>
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
    </div>
</body>
</html>
