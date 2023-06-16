<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/private_html/includes/session_start.php';
require_once __DIR__ . '/private_html/includes/functions.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Проверяем, передан ли идентификатор коллекции в URL-параметрах
if (!isset($_GET['collection_id']) || empty($_GET['collection_id'])) {
    // Если идентификатор коллекции отсутствует, выводим сообщение об ошибке
    $error_message = 'Collection ID is missing or invalid.';
} else {
    $collection_id = $_GET['collection_id'];

    // Получение информации о коллекции
    $collection = get_collection($collection_id);

    // Проверка, если коллекция не найдена, выводим сообщение об ошибке
    if (!$collection) {
        $error_message = 'Collection not found.';
    }
}

// Переменные для хранения данных формы
$title = $description = '';
$error_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $title = $_POST['title'];
    $description = $_POST['description'];

    // Валидация данных
    if (empty($title)) {
        $error_message = 'Please enter a title for the movie.';
    } else {
        // Добавление фильма в коллекцию
        $movie_id = add_movie_to_collection($collection_id, $title, $description);

        if ($movie_id) {
            // Фильм успешно добавлен
            // Перенаправление на страницу просмотра коллекции с передачей ID коллекции
            header('Location: /view_collection.php?collection_id=' . $collection_id);
            exit;
        } else {
            $error_message = 'Failed to add movie to collection. Please try again.';
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Add Movie'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/add_movie.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <h1><?php echo translate('Add Movie'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="title"><?php echo translate('Title'); ?>:</label>
                <input type="text" id="title" name="title" value="<?php echo htmlspecialchars($title); ?>">
            </div>
            <div class="form-group">
                <label for="description"><?php echo translate('Description'); ?>:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($description); ?></textarea>
            </div>
            <button type="submit"><?php echo translate('Add'); ?></button>
        </form>
    </main>
</body>
</html>
