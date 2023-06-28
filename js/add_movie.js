document.addEventListener('DOMContentLoaded', () => {
    const movieSuggestions = [];

    function getMovieSuggestions(query) {
        const apiKey = 'YOUR_API_KEY';
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
                    movieSuggestions.push(movie);
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
            document.getElementById('poster').value = selectedMovie.poster_path ? `https://image.tmdb.org/t/p/w500${selectedMovie.poster_path}` : '';
            document.getElementById('poster-preview').src = selectedMovie.poster_path ? `https://image.tmdb.org/t/p/w200${selectedMovie.poster_path}` : '';
            document.getElementById('poster-preview').style.display = selectedMovie.poster_path ? 'block' : 'none';
            document.getElementById('description').value = selectedMovie.overview;
        }
    }

    const titleInput = document.getElementById('title');
    titleInput.addEventListener('input', () => {
        const query = titleInput.value.trim();
        if (query) {
            getMovieSuggestions(query);
        } else {
            const suggestionsContainer = document.getElementById('suggestions');
            suggestionsContainer.innerHTML = '';
            movieSuggestions.length = 0;
        }
    });

    const suggestionsContainer = document.getElementById('suggestions');
    suggestionsContainer.addEventListener('click', (event) => {
        selectMovie(event);
        suggestionsContainer.innerHTML = '';
        movieSuggestions.length = 0;
    });
});
