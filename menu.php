<nav>
    <ul>
        <li><a href="/index.php"><?php echo translate('Home'); ?></a></li>
        <?php if (is_logged_in()) { ?>
            <li><a href="/collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
            <li><a href="/my_collections.php"><?php echo translate('My Collections'); ?></a></li>
        <?php } else { ?>
            <li><a href="/register.php"><?php echo translate('Register'); ?></a></li>
            <li><a href="/login.php"><?php echo translate('Login'); ?></a></li>
        <?php } ?>
        <li><a href="<?php echo update_query_param('lang', 'en'); ?>">EN</a></li>
        <li><a href="<?php echo update_query_param('lang', 'lv'); ?>">LV</a></li>
        <li><a href="<?php echo update_query_param('lang', 'ru'); ?>">RU</a></li>
    </ul>
</nav>
