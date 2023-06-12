<?php
require_once __DIR__ . '/config.php';

// Проверка авторизации пользователя
if (!is_logged_in()) {
    // Если пользователь не авторизован, перенаправляем на страницу входа
    redirect('/login.php');
}

// Получение информации о текущем пользователе
$user_id = $_SESSION['user_id'];
$user = get_user($user_id);

// Обработка изменений данных пользователя
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $password = $_POST['password'];

    // Обновление информации о пользователе
    update_user($user_id, $name, $email, $password);
    
    // Перенаправление на страницу профиля
    redirect('/profile.php');
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('My Profile'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/profile.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
        <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/submenu.php'; ?>    
    <?php } ?>
    </header>
    <main>
        <h1><?php echo translate('My Profile'); ?></h1>
        <form method="POST">
            <label for="name"><?php echo translate('Name'); ?>:</label>
            <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($user['name']); ?>" required>

            <label for="email"><?php echo translate('Email'); ?>:</label>
            <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($user['email']); ?>" required>

            <label for="password"><?php echo translate('Password'); ?>:</label>
            <input type="password" id="password" name="password" required>

            <button type="submit"><?php echo translate('Save'); ?></button>
        </form>
    </main>
</body>
</html>
