<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Получение ID коллекции из параметров запроса
$collection_id = $_GET['collection_id'];

// Проверка наличия коллекции в базе данных
$collection = get_collection($collection_id);

if (!$collection) {
    // Коллекция не найдена, перенаправляем на страницу ошибки
    $error_message = 'Collection not found.';
}

// Переменные для хранения данных формы
$movie_id = '';
$error_message = '';
$success_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $movie_id = $_POST['movie_id'];

    // Проверка наличия фильма в базе данных
    $movie = get_movie($movie_id);

    if (!$movie) {
        $error_message = 'Movie not found.';
    } else {
        // Добавление фильма в коллекцию
        try {
            add_movie_to_collection($collection_id, $movie_id, $movie['language']);
            $success_message = 'Movie successfully added to collection.';
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
        <?php if ($success_message) { ?>
            <p class="success"><?php echo $success_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']) . '?collection_id=' . $collection_id; ?>">
            <div class="form-group">
                <label for="movie_id"><?php echo translate('Movie'); ?>:</label>
                <select id="movie_id" name="movie_id">
                    <option value="">-- <?php echo translate('Select Movie'); ?> --</option>
                    <?php foreach (get_movies() as $movie) { ?>
                        <option value="<?php echo $movie['id']; ?>"><?php echo $movie['title']; ?></option>
                    <?php } ?>
                </select>
            </div>
            <button type="submit"><?php echo translate('Add'); ?></button>
        </form>
    </main>
</body>
</html>
