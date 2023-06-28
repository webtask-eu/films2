<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><?php echo translate('Add Movie'); ?></title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="stylesheet" href="/css/add_movie.css">
    <link rel="stylesheet" href="/css/submenu.css">
    <link rel="stylesheet" href="/css/menu.css">
    <style>
        .suggestions {
            position: relative;
        }

        .suggestions ul {
            position: absolute;
            top: 100%;
            left: 0;
            z-index: 999;
            width: 100%;
            background-color: #fff;
            border: 1px solid #ccc;
            border-radius: 4px;
            padding: 0;
            margin-top: 5px;
            list-style: none;
        }

        .suggestions ul li {
            padding: 5px 10px;
            cursor: pointer;
        }

        .suggestions ul li:hover {
            background-color: #f2f2f2;
        }

        .poster-preview {
            max-width: 200px;
            display: none;
            margin-top: 10px;
        }
    </style>
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
                <input type="text" id="poster" name="poster" value="<?php echo htmlspecialchars($poster); ?>" readonly>
                <img id="poster-preview" class="poster-preview" src="" alt="Poster Preview">
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
            const apiKey = 'YOUR_TMDB_API_KEY';
            const url = `https://api.themoviedb.org/3/search/movie?api_key=${apiKey}&query=${query}`;

            fetch(url)
                .then(response => response.json())
                .then(data => {
                    const suggestionsContainer = document.getElementById('suggestions');
                    suggestionsContainer.innerHTML = '';

                    data.results.forEach(movie => {
                        const li = document.createElement('li');
                        li.textContent = movie.title;
                        suggestionsContainer.appendChild(li);
                    });
                })
                .catch(error => {
                    console.error('Failed to fetch movie suggestions:', error);
                });
        }

        function selectMovie(event) {
            const selectedTitle = event.target.textContent;
            const selectedMovie = movieSuggestions.find(movie => movie.title === selectedTitle);

            if (selectedMovie) {
                document.getElementById('title').value = selectedMovie.title;
                document.getElementById('poster').value = `https://image.tmdb.org/t/p/w500${selectedMovie.poster_path}`;
                document.getElementById('poster-preview').src = `https://image.tmdb.org/t/p/w200${selectedMovie.poster_path}`;
                document.getElementById('poster-preview').style.display = 'block';
                document.getElementById('description').value = selectedMovie.overview;
            }
        }
    </script>
</body>
</html>

<!-- Debug Info -->
<pre>
    <?php // var_dump($collections); ?>
</pre>