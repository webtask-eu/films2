<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Получение ID коллекции из параметра запроса
$collection_id = $_GET['collection_id'] ?? '';

// Переменные для хранения данных формы
$title = $description = '';
$error_message = '';

// Получение списка коллекций пользователя
try {
    $collections = get_user_collections();
    var_dump($collections); // Отладочная информация

    // Если у пользователя нет доступных коллекций, предложить создать коллекцию
    if (empty($collections)) {
        echo 'You don\'t have any collections. <a href="/collection_create.php">Create a collection</a>';
        exit;
    }
} catch (Exception $e) {
    $error_message = 'Failed to get user collections: ' . $e->getMessage();
}

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
            add_movie_to_collection($collection_id, $title, $description);
            redirect('/collections.php');
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
    <link rel="stylesheet" href="/css/add_movie.css">
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
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="collection">Collection:</label>
                <select id="collection" name="collection_id">
                    <?php foreach ($collections as $collection) { ?>
                        <option value="<?php echo $collection['id']; ?>" <?php echo ($collection_id === $collection['id']) ? 'selected' : ''; ?>><?php echo $collection['name']; ?></option>
                    <?php } ?>
                </select>
            </div>
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

 <!-- Debug Info -->
 <pre>
        <?php var_dump($collections); ?>
    </pre>