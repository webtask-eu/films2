<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
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
        try {
            $collection_id = $_GET['collection_id'];
            add_movie_to_collection($collection_id, $title, $description);
            
            // Фильм успешно добавлен, перенаправление на страницу коллекции
            redirect('/collection.php?id=' . $collection_id);
        } catch (Exception $e) {
            $error_message = 'Failed to add movie to collection: ' . $e->getMessage();
        }
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add Movie</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/register.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <h1>Add Movie</h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF'] . '?collection_id=' . $_GET['collection_id']); ?>">
            <div class="form-group">
                <label for="title">Title:</label>
                <input type="text" id="title" name="title" value="<?php echo htmlspecialchars($title); ?>">
            </div>
            <div class="form-group">
                <label for="description">Description:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($description); ?></textarea>
            </div>
            <button type="submit">Add Movie</button>
        </form>
    </main>
</body>
</html>
