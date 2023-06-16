<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Проверка, что передан параметр collection_id в URL
if (isset($_GET['collection_id'])) {
    $collection_id = $_GET['collection_id'];

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Получение данных из формы
        $movie_id = $_POST['movie_id'];

        if (!empty($movie_id)) {
            // Вызов функции add_movie_to_collection()
            try {
                add_movie_to_collection($collection_id, $movie_id);
                echo "Movie successfully added to collection.";
            } catch (Exception $e) {
                echo "Failed to add movie to collection: " . $e->getMessage();
            }
        } else {
            echo "Error: Invalid movie ID.";
        }
    }
} else {
    echo "Error: Invalid collection ID.";
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add Movie to Collection</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/add_movie.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <h1>Add Movie to Collection</h1>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF'] . '?collection_id=' . $collection_id); ?>">
            <div class="form-group">
                <label for="movie_id">Movie ID:</label>
                <input type="text" id="movie_id" name="movie_id" required>
            </div>
            <button type="submit">Add Movie</button>
        </form>
    </main>
</body>
</html>
