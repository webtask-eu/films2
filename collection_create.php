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
    <title><?php echo translate('Create Collection'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/registration.css">
    <link rel="stylesheet" href="/css/submenu.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
    </header>
    <?php include_once __DIR__ . '/submenu.php'; ?>
    <div class="container">
        <h1><?php echo translate('Create Collection'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="name"><?php echo translate('Name'); ?>:</label>
                <input type="text" id="name" name="name" value="<?php echo isset($_POST['name']) ? htmlspecialchars($_POST['name']) : ''; ?>">
            </div>
            <div class="form-group">
                <label for="description"><?php echo translate('Description'); ?>:</label>
                <textarea id="description" name="description"><?php echo isset($_POST['description']) ? htmlspecialchars($_POST['description']) : ''; ?></textarea>
            </div>
            <button type="submit"><?php echo translate('Create'); ?></button>
        </form>
    </div>
</body>
</html>
