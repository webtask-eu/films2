<?php
require_once 'includes/session_start.php';
require_once 'includes/functions.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Загрузка переводов
$translations = load_translations();

// Получение текущего языка
$currentLanguage = get_language();

// Обработка формы создания коллекции
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Обработка данных формы и создание коллекции
    // ...
}

// Получение сообщения об ошибке
$error_message = get_error_message();

// Получение сообщения об успехе
$success_message = get_success_message();
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Create Collection'); ?></title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <header>
        <nav>
            <ul>
                <li><a href="index.php"><?php echo translate('Home'); ?></a></li>
                <li><a href="collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
                <li><a href="logout.php"><?php echo translate('Logout'); ?></a></li>
                <li><a href="<?php echo update_query_param('lang', 'en'); ?>">EN</a></li>
                <li><a href="<?php echo update_query_param('lang', 'lv'); ?>">LV</a></li>
                <li><a href="<?php echo update_query_param('lang', 'ru'); ?>">RU</a></li>
            </ul>
        </nav>
    </header>
    <main>
        <h1><?php echo translate('Create Collection'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <?php if ($success_message) { ?>
            <p class="success"><?php echo $success_message; ?></p>
        <?php } ?>
        <form method="post">
            <!-- Форма для создания коллекции -->
            <!-- ... -->
            <button type="submit"><?php echo translate('Create'); ?></button>
        </form>
    </main>
</body>
</html>
