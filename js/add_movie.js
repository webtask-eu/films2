        var movieSuggestions = []; // Инициализация переменной movieSuggestions

        function getMovieSuggestions(query) {
            const apiKey = '<?php echo TMDB_API_KEY; ?>';
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