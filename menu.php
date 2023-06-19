<nav>
        <ul>
            <li class="site-title"><a href="/index.php"><?php echo translate('Film Collection'); ?></a></li>
            <li class="right"><a href="/register.php"><?php echo translate('Register'); ?></a></li>
            <li class="right"><a href="/login.php"><?php echo translate('Login'); ?></a></li>
            <li class="center"><a href="/collection_create.php"><?php echo translate('Create Collection'); ?></a></li>
            <li class="center"><a href="/collectios.php"><?php echo translate('My Collections'); ?></a></li>
            <li class="language"><a href="<?php echo update_query_param('lang', 'en'); ?>">EN</a></li>
            <li class="language"><a href="<?php echo update_query_param('lang', 'lv'); ?>">LV</a></li>
            <li class="language"><a href="<?php echo update_query_param('lang', 'ru'); ?>">RU</a></li>
        </ul>
    </nav>
