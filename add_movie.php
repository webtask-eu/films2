<?php
require_once __DIR__ . '/config.php';

$currentLanguage = get_current_language();
echo $currentLanguage;

// Проверка авторизации пользователя
if (!is_logged_in()) {
    redirect('/login.php');
}

// Получение ID коллекции из параметра запроса
$collection_id = $_GET['collection_id'] ?? '';

// Переменные для хранения данных формы
$title = $description = '';
$error_message = '';

// Получение списка коллекций пользователя
try {
    $collections = get_user_collections();

    // Если у пользователя нет доступных коллекций, предложить создать коллекцию
    if (empty($collections)) {
        echo translate('You don\'t have any collections. <a href="/collection_create.php">Create a collection</a>');
        exit;
    }
} catch (Exception $e) {
    $error_message = translate('Failed to get user collections: ') . $e->getMessage();
}

// Обработка отправки формы
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Получение данных из формы
    $title = $_POST['title'];
    $description = $_POST['description'];
    $selected_collection_id = $_POST['collection_id'] ?? '';
    $poster_path = $_POST['poster'] ?? '';

    // Валидация данных
    if (empty($title)) {
        $error_message = translate('Please enter a title for the movie.');
    } elseif (empty($selected_collection_id)) {
        $error_message = translate('Please select a collection.');
    } else {
        // Добавление фильма в коллекцию
        try {
            add_movie_to_collection($selected_collection_id, $title, $description, $poster_path);
            redirect('/collections.php');
        } catch (Exception $e) {
            $error_message = translate('Failed to add movie to collection: ') . $e->getMessage();
        }
    }
}

?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Add Movie'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/add_movie.css">
    <link rel="stylesheet" href="/css/submenu.css">
    <link rel="stylesheet" href="/css/menu.css">
    <link rel="stylesheet" href="/css/custom.css">
</head>
<body>
    <header>
        <?php include_once __DIR__ . '/menu.php'; ?>
        <?php if (is_logged_in()) { ?>
        <?php include_once __DIR__ . '/submenu.php'; ?>    
        <?php } ?>
    </header>
    <main>
        <h1><?php echo translate('Add Movie'); ?></h1>
        <?php if ($error_message) { ?>
            <p class="error"><?php echo $error_message; ?></p>
        <?php } ?>
        <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <div class="form-group">
                <label for="collection"><?php echo translate('Collection'); ?>:</label>
                <select id="collection" name="collection_id">
                    <?php foreach ($collections as $collection) { ?>
                        <option value="<?php echo $collection['id']; ?>" <?php echo ($collection_id === $collection['id']) ? 'selected' : ''; ?>><?php echo $collection['name']; ?></option>
                    <?php } ?>
                </select>
            </div>
            <div class="form-group suggestions">
                <label for="title"><?php echo translate('Title'); ?>:</label>
                <input type="text" id="title" name="title" value="<?php echo htmlspecialchars($title); ?>" oninput="getMovieSuggestions(this.value)">
                <ul id="suggestions" onclick="selectMovie(event)"></ul>
            </div>
            <div class="form-group">
                <label for="poster"><?php echo translate('Poster'); ?>:</label>
                <input type="text" id="poster" name="poster" value="<?php echo isset($poster) ? htmlspecialchars($poster) : ''; ?>" readonly>
                <img id="poster-preview" class="poster-preview" src="<?php echo htmlspecialchars($poster); ?>" alt="Poster Preview">
            </div>
            <div class="form-group">
                <label for="description"><?php echo translate('Description'); ?>:</label>
                <textarea id="description" name="description"><?php echo htmlspecialchars($description); ?></textarea>
            </div>
            <button type="submit"><?php echo translate('Add Movie'); ?></button>
        </form>
    </main>
    <script>
function getMovieSuggestions(query) {
    const apiKey = '<?php echo TMDB_API_KEY; ?>';
    const language = '<?php echo $currentLanguage; ?>'; // Получение текущего языка
    const url = `https://api.themoviedb.org/3/search/movie?api_key=${apiKey}&query=${query}&language=${language}`;

    fetch(url)
        .then(response => response.json())
        .then(data => {
            const suggestionsContainer = document.getElementById('suggestions');
            suggestionsContainer.innerHTML = '';

            data.results.forEach(movie => {
                const li = document.createElement('li');
                const img = document.createElement('img'); // Создание элемента <img>
                img.src = `https://image.tmdb.org/t/p/w92${movie.poster_path}`; // Установка src для миниатюры постера
                img.alt = 'Poster';
                li.textContent = movie.title;
                li.prepend(img); // Добавление миниатюры перед текстом фильма
                li.setAttribute('data-movie-id', movie.id); // Добавление атрибута с ID фильма
                suggestionsContainer.appendChild(li);
            });
        })
        .catch(error => {
            console.error('Failed to fetch movie suggestions:', error);
        });
}

function selectMovie(event) {
    const selectedTitle = event.target.textContent;
    const selectedMovieId = event.target.getAttribute('data-movie-id'); // Получение ID фильма из атрибута

    if (selectedMovieId) {
        const apiKey = '<?php echo TMDB_API_KEY; ?>';
        const language = '<?php echo $currentLanguage; ?>'; // Получение текущего языка
        const url = `https://api.themoviedb.org/3/movie/${selectedMovieId}?api_key=${apiKey}&language=${language}`;

        fetch(url)
            .then(response => response.json())
            .then(data => {
                document.getElementById('title').value = selectedTitle || '';
                document.getElementById('poster').value = data.poster_path ? `https://image.tmdb.org/t/p/w500${data.poster_path}` : '';
                document.getElementById('poster-preview').src = data.poster_path ? `https://image.tmdb.org/t/p/w200${data.poster_path}` : '';
                document.getElementById('poster-preview').style.display = data.poster_path ? 'block' : 'none';
                document.getElementById('description').value = data.overview || '';
            })
            .catch(error => {
                console.error('Failed to fetch movie details:', error);
            });
    }
}
    </script>
    <script src="/js/add_movie.js"></script>
</body>
</html>

<!-- Debug Info -->
<pre>
    <?php // var_dump($collections); ?>
</pre>
