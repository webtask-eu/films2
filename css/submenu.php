<nav class="submenu">
    <ul>
        <?php if (is_logged_in()) { ?>
            <li><a href="/collection_create.php"><?php echo translate('Add to Collection'); ?></a></li>
            <li><a href="/profile.php"><?php echo translate('My Profile'); ?></a></li>
            <li><a href="/logout.php"><?php echo translate('Logout'); ?></a></li>
        <?php } else { ?>
            <li><a href="/register.php"><?php echo translate('Register'); ?></a></li>
            <li><a href="/login.php"><?php echo translate('Login'); ?></a></li>
        <?php } ?>
    </ul>
</nav>
