<?php
require_once __DIR__ . '/config.php';

// Проверка, если пользователь уже авторизован, перенаправляем на главную страницу
if (is_logged_in()) {
    redirect('/profile.php');
}

// Переменные для хранения данных формы
$email = '';
$password = '';
$error_message = '';

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $email = $_POST['email'];
    $password = $_POST['password'];

    // Валидация данных
    if (empty($email) || empty($password)) {
        $error_message = 'Please enter email and password.';
    } else {
        // Попытка авторизации пользователя
        $result = login_user_by_email($email, $password);
        if ($result['success']) {
            // Авторизация успешна, перенаправление на страницу профиля
            redirect('/profile.php');
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
    <title><?php echo translate('Login'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/login.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
        <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/submenu.php'; ?>    
        <?php } ?>
    </header>
    <div class="container">
        <h1><?php echo translate('Login'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form class="login-form" method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="email"><?php echo translate('Email'); ?>:</label>
                <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($email); ?>">
            </div>
            <div class="form-group">
                <label for="password"><?php echo translate('Password'); ?>:</label>
                <input type="password" id="password" name="password">
            </div>
            <button type="submit"><?php echo translate('Login'); ?></button>
        </form>
    </div>
</body>
</html>
