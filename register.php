<?php
require_once __DIR__ . '/config.php';
require_once INCLUDES_PATH . '/session_start.php';
require_once INCLUDES_PATH . '/functions.php';

// Проверка, если пользователь уже авторизован, перенаправляем на главную страницу
if (is_logged_in()) {
    redirect('/index.php');
}

// Переменные для хранения данных формы
$name = $email = $password = '';
$error_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $name = $_POST['name'];
    $email = $_POST['email'];
    $password = $_POST['password'];

    // Валидация данных
    if (empty($name) || empty($email) || empty($password)) {
        $error_message = 'Please fill in all fields.';
    } else {
        // Попытка создания нового пользователя
        $result = create_user($name, $email, $password);
        if ($result['success']) {
            // Успешная регистрация, перенаправление на страницу входа
            redirect('/login.php');
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
    <title><?php echo translate('Register'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
</head>
<body>
    <div class="container">
        <h1><?php echo translate('Register'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="name"><?php echo translate('Name'); ?>:</label>
                <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($name); ?>">
            </div>
            <div class="form-group">
                <label for="email"><?php echo translate('Email'); ?>:</label>
                <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($email); ?>">
            </div>
            <div class="form-group">
                <label for="password"><?php echo translate('Password'); ?>:</label>
                <input type="password" id="password" name="password" value="<?php echo htmlspecialchars($password); ?>">
            </div>
            <button type="submit"><?php echo translate('Register'); ?></button>
        </form>
    </div>
</body>
</html>
