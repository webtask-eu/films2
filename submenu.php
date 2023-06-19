<?php ?>
$active_page = basename($_SERVER['PHP_SELF']);
?>
<ul class="submenu">
  <li class="left-items<?php echo ($active_page === 'collection_create.php') ? ' active' : ''; ?>">
    <a href="/collection_create.php"><?php echo translate('Create Collection'); ?></a>
  </li>   
  <li class="left-items<?php echo ($active_page === 'add_movie.php') ? ' active' : ''; ?>">
    <a href="/add_movie.php"><?php echo translate('Add Movie'); ?></a>
  </li>
  <li class="left-items<?php echo ($active_page === 'collections.php') ? ' active' : ''; ?>">
    <a href="/collections.php"><?php echo translate('My Collections'); ?></a>
  </li>
  <li class="right-items<?php echo ($active_page === 'profile.php') ? ' active' : ''; ?>">
    <a href="/profile.php"><?php echo translate('My Profile'); ?></a>
  </li>
  <li class="right-items<?php echo ($active_page === 'logout.php') ? ' active' : ''; ?>">
    <a href="/logout.php"><?php echo translate('Logout'); ?></a>
  </li>
</ul>
