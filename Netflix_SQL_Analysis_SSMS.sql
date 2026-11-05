/* =====================================================================
   Netflix Shows & Movies Analysis  -  SQL Server (SSMS / T-SQL)
   Database : NetflixDB
   Tables   : dbo.titles  (from titles.csv)
              dbo.credits (from credits.csv)
   Run each query separately: highlight it, then press F5 (or Execute).
   ===================================================================== */

USE NetflixDB;
GO

-- ---------------------------------------------------------------------
-- Q0. Sanity check: did the import work?
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS titles_rows  FROM dbo.titles;
SELECT COUNT(*) AS credits_rows FROM dbo.credits;
SELECT TOP 5 * FROM dbo.titles;

-- ---------------------------------------------------------------------
-- Q1. Top 10 movies by IMDB score
-- ---------------------------------------------------------------------
SELECT TOP 10 title, type, imdb_score
FROM dbo.titles
WHERE type = 'MOVIE' AND imdb_score >= 8.0
ORDER BY imdb_score DESC;

-- Top 10 shows by IMDB score
SELECT TOP 10 title, type, imdb_score
FROM dbo.titles
WHERE type = 'SHOW' AND imdb_score >= 8.0
ORDER BY imdb_score DESC;

-- Bottom 10 movies by IMDB score
SELECT TOP 10 title, type, imdb_score
FROM dbo.titles
WHERE type = 'MOVIE' AND imdb_score IS NOT NULL
ORDER BY imdb_score ASC;

-- Bottom 10 shows by IMDB score
SELECT TOP 10 title, type, imdb_score
FROM dbo.titles
WHERE type = 'SHOW' AND imdb_score IS NOT NULL
ORDER BY imdb_score ASC;

-- ---------------------------------------------------------------------
-- Q2. Average IMDB and TMDB scores for movies vs shows
-- ---------------------------------------------------------------------
SELECT type,
       ROUND(AVG(imdb_score), 2) AS avg_imdb_score,
       ROUND(AVG(tmdb_score), 2) AS avg_tmdb_score
FROM dbo.titles
GROUP BY type;

-- ---------------------------------------------------------------------
-- Q3. How many titles fall in each decade?
-- ---------------------------------------------------------------------
SELECT CONCAT(FLOOR(release_year / 10) * 10, 's') AS decade,
       COUNT(*) AS movies_shows_count
FROM dbo.titles
WHERE release_year >= 1940
GROUP BY CONCAT(FLOOR(release_year / 10) * 10, 's')
ORDER BY decade;

-- ---------------------------------------------------------------------
-- Q4. Titles per production country (feeds the map in Tableau)
--     production_countries looks like "['US']" so we strip the symbols.
--     Titles with several countries are counted per list as-is.
-- ---------------------------------------------------------------------
SELECT REPLACE(REPLACE(REPLACE(production_countries, '[', ''), ']', ''), '''', '') AS country,
       COUNT(*) AS title_count
FROM dbo.titles
WHERE production_countries IS NOT NULL
  AND production_countries <> '[]'
GROUP BY REPLACE(REPLACE(REPLACE(production_countries, '[', ''), ']', ''), '''', '')
ORDER BY title_count DESC;

-- Average scores per production country list
SELECT production_countries,
       ROUND(AVG(imdb_score), 2) AS avg_imdb_score,
       ROUND(AVG(tmdb_score), 2) AS avg_tmdb_score
FROM dbo.titles
GROUP BY production_countries
ORDER BY avg_imdb_score DESC;

-- ---------------------------------------------------------------------
-- Q5. Age certifications
-- ---------------------------------------------------------------------
-- Average scores per certification
SELECT age_certification,
       ROUND(AVG(imdb_score), 2) AS avg_imdb_score,
       ROUND(AVG(tmdb_score), 2) AS avg_tmdb_score
FROM dbo.titles
GROUP BY age_certification
ORDER BY avg_imdb_score DESC;

-- Top 5 most common certifications for movies
SELECT TOP 5 age_certification,
       COUNT(*) AS certification_count
FROM dbo.titles
WHERE type = 'MOVIE'
  AND age_certification IS NOT NULL
  AND age_certification <> 'N/A'
GROUP BY age_certification
ORDER BY certification_count DESC;

-- ---------------------------------------------------------------------
-- Q6. Most common genres
-- ---------------------------------------------------------------------
-- Movies
SELECT TOP 10 genres, COUNT(*) AS title_count
FROM dbo.titles
WHERE type = 'MOVIE'
GROUP BY genres
ORDER BY title_count DESC;

-- Shows
SELECT TOP 10 genres, COUNT(*) AS title_count
FROM dbo.titles
WHERE type = 'SHOW'
GROUP BY genres
ORDER BY title_count DESC;

-- Top 3 overall
SELECT TOP 3 genres, COUNT(*) AS genre_count
FROM dbo.titles
GROUP BY genres
ORDER BY genre_count DESC;

-- ---------------------------------------------------------------------
-- Q7. Shows with the most seasons (feeds the line chart)
-- ---------------------------------------------------------------------
SELECT TOP 10 title, SUM(seasons) AS total_seasons
FROM dbo.titles
WHERE type = 'SHOW'
GROUP BY title
ORDER BY total_seasons DESC;

-- ---------------------------------------------------------------------
-- Q8. Average runtime (minutes) for movies and shows
-- ---------------------------------------------------------------------
SELECT type, ROUND(AVG(CAST(runtime AS FLOAT)), 2) AS avg_runtime_min
FROM dbo.titles
GROUP BY type;

-- ---------------------------------------------------------------------
-- Q9. Number of titles per release year
-- ---------------------------------------------------------------------
SELECT release_year, COUNT(*) AS title_count
FROM dbo.titles
GROUP BY release_year
ORDER BY release_year DESC;

-- ---------------------------------------------------------------------
-- Q10. People (credits table; role is either ACTOR or DIRECTOR)
-- ---------------------------------------------------------------------
-- Top 20 actors by number of titles
SELECT TOP 20 name AS actor, COUNT(*) AS number_of_appearances
FROM dbo.credits
WHERE role = 'ACTOR'
GROUP BY name
ORDER BY number_of_appearances DESC;

-- Top 20 directors by number of titles
SELECT TOP 20 name AS director, COUNT(*) AS number_of_titles
FROM dbo.credits
WHERE role = 'DIRECTOR'
GROUP BY name
ORDER BY number_of_titles DESC;

-- Movies released 2010 or later, with their director
SELECT DISTINCT t.title, c.name AS director, t.release_year
FROM dbo.titles  AS t
JOIN dbo.credits AS c ON t.id = c.id
WHERE t.type = 'MOVIE'
  AND t.release_year >= 2010
  AND c.role = 'DIRECTOR'
ORDER BY t.release_year DESC;

-- Highly rated (IMDB > 7.5) and popular (TMDB popularity > 80) movies + director
SELECT t.title, c.name AS director
FROM dbo.titles  AS t
JOIN dbo.credits AS c ON t.id = c.id
WHERE t.type = 'MOVIE'
  AND t.imdb_score > 7.5
  AND t.tmdb_popularity > 80
  AND c.role = 'DIRECTOR';

-- Actors in the most highly rated titles (IMDB > 8 and TMDB > 8)
SELECT c.name AS actor, COUNT(*) AS num_highly_rated_titles
FROM dbo.credits AS c
JOIN dbo.titles  AS t ON c.id = t.id
WHERE c.role = 'ACTOR'
  AND t.imdb_score > 8.0
  AND t.tmdb_score > 8.0
GROUP BY c.name
ORDER BY num_highly_rated_titles DESC;

-- Actors who played the same character in more than one title
SELECT c.name AS actor, c.[character], COUNT(DISTINCT t.title) AS num_titles
FROM dbo.credits AS c
JOIN dbo.titles  AS t ON c.id = t.id
WHERE c.role = 'ACTOR'
  AND c.[character] IS NOT NULL
GROUP BY c.name, c.[character]
HAVING COUNT(DISTINCT t.title) > 1
ORDER BY num_titles DESC;

-- Average IMDB score per actor (only actors with at least 5 scored titles)
SELECT c.name AS actor,
       COUNT(*) AS scored_titles,
       ROUND(AVG(t.imdb_score), 2) AS average_imdb_score
FROM dbo.credits AS c
JOIN dbo.titles  AS t ON c.id = t.id
WHERE c.role = 'ACTOR'
  AND t.imdb_score IS NOT NULL
GROUP BY c.name
HAVING COUNT(*) >= 5
ORDER BY average_imdb_score DESC;
