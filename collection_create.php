<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Получение ID текущего пользователя
$user_id = $_SESSION['user_id'];

// Переменные для хранения данных формы
$name = '';
$description = '';
$error_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $name = $_POST['name'];
    $description = $_POST['description'];

    // Валидация данных
    if (empty($name) || empty($description)) {
        $error_message = 'Please fill in all fields.';
    } else {
        // Создание коллекции
        $result = create_collection($user_id, $name, $description);

        if ($result['success']) {
            // Перенаправление на страницу коллекции
            header("Location: /collections.php?collection_id=" . $result['collection_id']);
            exit();
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
    <link rel="stylesheet" href="/css/collection_create.css">
</head>
<body>
<header>
    <?php include_once __DIR__ . '/menu.php'; ?>
</header>
<main>
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
</main>
</body>
</html>
