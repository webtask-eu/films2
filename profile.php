
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
    <title>My Profile</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/submenu.css">
    <link rel="stylesheet" href="/css/registration.css">
</head>
<body>
<header>
        <?php include_once __DIR__ . '/menu.php'; ?>
        <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/submenu.php'; ?>    
        <?php } ?>
    </header>
    <div class="container">
        <h1>My Profile</h1>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" id="name" name="name" value="<?php echo htmlspecialchars($user['name']); ?>">
            </div>
            <div class="form-group">
                <label for="email">Email:</label>
                <input type="email" id="email" name="email" value="<?php echo htmlspecialchars($user['email']); ?>">
            </div>
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password">
            </div>
            <button type="submit">Save</button>
        </form>
    </div>
</body>
</html>
