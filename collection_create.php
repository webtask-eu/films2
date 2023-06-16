<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Переменные для хранения данных формы
$name = $description = '';
$error_message = '';

try {
    // Обработка отправки формы
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Получение данных из формы
        $name = $_POST['name'];
        $description = $_POST['description'];

        // Валидация данных
        if (empty($name)) {
            throw new Exception('Please enter a name for the collection.');
        } else {
            // Создание коллекции
            $collection_id = create_collection($name, $description);

            if ($collection_id) {
                // Коллекция успешно добавлена
                // Перенаправление на страницу добавления фильма в коллекцию с передачей ID коллекции
                redirect('/add_movie.php?collection_id=' . $collection_id);
            } else {
                throw new Exception('Failed to create collection. Please try again.');
            }
        }
    }
} catch (Exception $e) {
    $error_message = $e->getMessage();
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Create Collection'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/collection_create.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <main>
        <h1><?php echo translate('Create Collection'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="name"><?php echo translate('Name'); ?>:</label>
                <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($name); ?>">
            </div>
            <div class="form-group">
                <label for="description"><?php echo translate('Description'); ?>:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($description); ?></textarea>
            </div>
            <button type="submit"><?php echo translate('Create'); ?></button>
        </form>
    </main>
</body>
</html>

