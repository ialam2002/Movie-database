use imdb_db2;

-- 1) Top 5 production companies by average IMDB rating (only those with ≥10 movies)
SELECT
  pc.name,
  COUNT(*)                  AS movie_count,
  ROUND(AVG(m.imdb_rating),1) AS avg_rating
FROM Production_Companies pc
JOIN Movie_Production_Companies mpc ON pc.production_company_id = mpc.production_company_id
JOIN Movies m                      ON mpc.movie_id               = m.movie_id
GROUP BY pc.production_company_id
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC
LIMIT 5;

-- 2) Directors who have made films in at least three different genres
SELECT
  d.name,
  COUNT(DISTINCT mg.genre_id) AS genre_diversity
FROM Directors d
JOIN Movies m         ON d.director_id = m.director_id
JOIN Movie_Genres mg  ON m.movie_id     = mg.movie_id
GROUP BY d.director_id
HAVING COUNT(DISTINCT mg.genre_id) >= 3
ORDER BY genre_diversity DESC;

-- 3) For each star, their highest-grossing movie (and its gross)
SELECT
  s.name         AS star,
  m.title        AS top_movie,
  m.gross
FROM (
  SELECT
    ms.star_id,
    ms.movie_id,
    ROW_NUMBER() OVER (PARTITION BY ms.star_id ORDER BY m.gross DESC) AS rn
  FROM Movie_Stars ms
  JOIN Movies m ON ms.movie_id = m.movie_id
) AS ranked
JOIN Stars s ON ranked.star_id  = s.star_id
JOIN Movies m ON ranked.movie_id = m.movie_id
WHERE ranked.rn = 1;

-- 4) Movies where the director also served as a producer
SELECT
  m.title,
  m.release_year,
  d.name AS director_producer
FROM Movies m
JOIN Directors d                   ON m.director_id = d.director_id
JOIN Movie_Producers mp            ON m.movie_id    = mp.movie_id
JOIN Producers p                   ON mp.producer_id = p.producer_id
WHERE p.name = d.name;

-- 5) Composers whose scored movies have average gross > 100 million
SELECT
  c.name,
  COUNT(*)                    AS num_movies,
  ROUND(AVG(m.gross)/1e6,1)   AS avg_gross_millions
FROM Composers c
JOIN Movie_Composers mc ON c.composer_id = mc.composer_id
JOIN Movies m           ON mc.movie_id    = m.movie_id
GROUP BY c.composer_id
HAVING AVG(m.gross) > 100000000
ORDER BY avg_gross_millions DESC;

-- 6) Top 10 movies by vote count, showing certificate and rating
SELECT
  m.title,
  m.release_year,
  v.no_of_votes,
  cert.certificate,
  m.imdb_rating
FROM Votes v
JOIN Movies m               ON v.movie_id       = m.movie_id
LEFT JOIN Certificates cert ON m.certificate_id = cert.certificate_id
ORDER BY v.no_of_votes DESC
LIMIT 10;

-- 7) For each year, the three most common genres by release count
SELECT
  release_year,
  genre_name,
  cnt
FROM (
  SELECT
    m.release_year,
    g.genre_name,
    COUNT(*) AS cnt,
    ROW_NUMBER() OVER (PARTITION BY m.release_year ORDER BY COUNT(*) DESC) AS rk
  FROM Movies m
  JOIN Movie_Genres mg ON m.movie_id   = mg.movie_id
  JOIN Genres g        ON mg.genre_id  = g.genre_id
  GROUP BY m.release_year, g.genre_name
) AS ranked_genres
WHERE rk <= 3
ORDER BY release_year, rk;

-- 8) Top 5 pairs of stars who co-starred most often
SELECT
  s1.name AS star_a,
  s2.name AS star_b,
  COUNT(*) AS movies_together
FROM Movie_Stars ms1
JOIN Movie_Stars ms2
  ON ms1.movie_id = ms2.movie_id
 AND ms1.star_id  <  ms2.star_id
JOIN Stars s1 ON ms1.star_id = s1.star_id
JOIN Stars s2 ON ms2.star_id = s2.star_id
GROUP BY ms1.star_id, ms2.star_id
ORDER BY movies_together DESC
LIMIT 5;

-- 9) Movies where a Production Company also appears as a Producer
SELECT
  m.title,
  m.release_year,
  pc.name AS company_name
FROM Movies m
JOIN Movie_Production_Companies mpc ON m.movie_id   = mpc.movie_id
JOIN Production_Companies pc        ON mpc.production_company_id = pc.production_company_id
JOIN Movie_Producers mp             ON m.movie_id   = mp.movie_id
JOIN Producers p                    ON mp.producer_id = p.producer_id
WHERE p.name = pc.name;

-- 10) Rolling 3-year moving average of total votes per year
SELECT
  release_year,
  total_votes,
  ROUND(AVG(total_votes) OVER (
    ORDER BY release_year 
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ),0) AS moving_avg_votes
FROM (
  SELECT
    m.release_year,
    SUM(v.no_of_votes) AS total_votes
  FROM Movies m
  JOIN Votes v ON m.movie_id = v.movie_id
  GROUP BY m.release_year
) AS yearly_votes
ORDER BY release_year;

-- 11) Directors with highest average box-office gross (among those with ≥5 movies)
SELECT
  d.name         AS director,
  COUNT(m.movie_id) AS num_films,
  ROUND(AVG(m.gross)/1e6,1) AS avg_gross_millions
FROM Directors d
JOIN Movies m ON d.director_id = m.director_id
WHERE m.gross IS NOT NULL
GROUP BY d.director_id
HAVING COUNT(*) >= 5
ORDER BY AVG(m.gross) DESC
LIMIT 5;

-- 12) For each genre, the composer whose films have the highest average IMDb rating
SELECT
  genre_name,
  composer_name,
  avg_rating
FROM (
  SELECT
    g.genre_name,
    c.name              AS composer_name,
    AVG(m.imdb_rating)  AS avg_rating,
    ROW_NUMBER() OVER (
      PARTITION BY g.genre_id
      ORDER BY AVG(m.imdb_rating) DESC
    ) AS rn
  FROM Genres g
  JOIN Movie_Genres mg      ON g.genre_id = mg.genre_id
  JOIN Movies m             ON mg.movie_id = m.movie_id
  JOIN Movie_Composers mc   ON m.movie_id = mc.movie_id
  JOIN Composers c          ON mc.composer_id = c.composer_id
  GROUP BY g.genre_id, c.composer_id
) AS ranked
WHERE rn = 1
ORDER BY genre_name;


-- actors with highest gross
WITH star_stats AS (
    SELECT 
        s.name,
        COUNT(DISTINCT m.movie_id) AS movie_count,
        ROUND(AVG(m.imdb_rating), 2) AS avg_rating,
        SUM(m.gross)/1000000 AS total_gross_millions,
        ROUND(SUM(m.gross)/COUNT(DISTINCT m.movie_id)/1000000, 2) AS avg_gross_per_movie_millions,
        MIN(m.release_year) AS first_year,
        MAX(m.release_year) AS last_year,
        GROUP_CONCAT(DISTINCT g.genre_name ORDER BY g.genre_name SEPARATOR ', ') AS genres
    FROM 
        Stars s
    JOIN 
        Movie_Stars ms ON s.star_id = ms.star_id
    JOIN 
        Movies m ON ms.movie_id = m.movie_id
    JOIN 
        Movie_Genres mg ON m.movie_id = mg.movie_id
    JOIN 
        Genres g ON mg.genre_id = g.genre_id
    WHERE 
        m.gross IS NOT NULL
    GROUP BY 
        s.star_id
    HAVING 
        movie_count >= 5
)
SELECT 
    name,
    movie_count,
    avg_rating,
    total_gross_millions,
    avg_gross_per_movie_millions,
    first_year,
    last_year,
    genres,
    last_year - first_year AS career_span
FROM 
    star_stats
ORDER BY 
    avg_gross_per_movie_millions DESC
LIMIT 20;

-- "Director Specialization" - Directors Who Stick to One Genre
SELECT 
    dg.director,
    dg.signature_genre,
    dg.genre_count,
    ROUND(dg.genre_count * 100.0 / dt.total_movies, 1) AS genre_percentage,
    ROUND(dg.avg_rating, 2) AS avg_rating
FROM (
    SELECT 
        d.director_id,
        d.name AS director,
        g.genre_name AS signature_genre,
        COUNT(DISTINCT m.movie_id) AS genre_count,
        AVG(m.imdb_rating) AS avg_rating
    FROM Movies m
    JOIN Directors d ON m.director_id = d.director_id
    JOIN Movie_Genres mg ON m.movie_id = mg.movie_id
    JOIN Genres g ON mg.genre_id = g.genre_id
    WHERE m.director_id IN (
        SELECT director_id 
        FROM Movies 
        GROUP BY director_id 
        HAVING COUNT(*) >= 5
    )
    GROUP BY d.director_id, g.genre_name
) AS dg
JOIN (
    SELECT 
        m.director_id,
        COUNT(DISTINCT m.movie_id) AS total_movies
    FROM Movies m
    GROUP BY m.director_id
) AS dt ON dg.director_id = dt.director_id
WHERE 
    (dg.genre_count * 100.0 / dt.total_movies) >= 70
ORDER BY 
    dg.genre_count DESC;
    
-- "The Cult Following" - High Rating, Low Gross Movies
SELECT 
    m.title,
    m.release_year,
    d.name AS director,
    m.imdb_rating,
    m.gross,
    v.no_of_votes,
    ROUND(m.gross/v.no_of_votes, 2) AS gross_per_vote,
    GROUP_CONCAT(DISTINCT g.genre_name ORDER BY g.genre_name SEPARATOR ', ') AS genres
FROM 
    Movies m
JOIN 
    Directors d ON m.director_id = d.director_id
JOIN 
    Votes v ON m.movie_id = v.movie_id
JOIN 
    Movie_Genres mg ON m.movie_id = mg.movie_id
JOIN 
    Genres g ON mg.genre_id = g.genre_id
WHERE 
    m.imdb_rating >= 8.0
    AND m.gross IS NOT NULL
    AND m.gross < 10000000  -- Less than $10M gross
    AND v.no_of_votes >= 50000
GROUP BY 
    m.movie_id, m.title, m.release_year, d.name, m.imdb_rating, m.gross, v.no_of_votes
ORDER BY 
    m.imdb_rating DESC, gross_per_vote ASC
LIMIT 20;

-- oscar bait, movies released during award season
SELECT 
    m.title,
    m.release_year,
    d.name AS director,
    m.imdb_rating,
    m.meta_score,
    m.gross,
    GROUP_CONCAT(DISTINCT g.genre_name ORDER BY g.genre_name SEPARATOR ', ') AS genres
FROM 
    Movies m
JOIN 
    Directors d ON m.director_id = d.director_id
JOIN 
    Movie_Genres mg ON m.movie_id = mg.movie_id
JOIN 
    Genres g ON mg.genre_id = g.genre_id
WHERE 
    (m.title LIKE '%life%' OR m.title LIKE '%story%' OR m.title LIKE '%american%')
    AND g.genre_name IN ('Drama', 'Biography', 'History')
    AND m.release_year >= 2000
    AND m.meta_score IS NOT NULL
    AND m.meta_score >= 70
GROUP BY 
    m.movie_id, m.title, m.release_year, d.name, m.imdb_rating, m.meta_score, m.gross
ORDER BY 
    m.meta_score DESC
LIMIT 20;
    
-- certificate effect on movie performance
SELECT 
    c.certificate,
    COUNT(*) AS movie_count,
    ROUND(AVG(m.imdb_rating), 2) AS avg_rating,
    ROUND(AVG(m.meta_score), 1) AS avg_meta_score,
    ROUND(AVG(m.gross)/1000000, 2) AS avg_gross_millions,
    ROUND(AVG(m.runtime_minutes)) AS avg_runtime,
    ROUND(AVG(v.no_of_votes)/1000, 1) AS avg_votes_thousands,
    SUM(m.gross)/1000000 AS total_gross_millions
FROM 
    Movies m
JOIN 
    Certificates c ON m.certificate_id = c.certificate_id
JOIN 
    Votes v ON m.movie_id = v.movie_id
WHERE 
    m.gross IS NOT NULL
GROUP BY 
    c.certificate
HAVING 
    movie_count > 10
ORDER BY 
    avg_gross_millions DESC;
    
-- Top-10 Movies by Number of Votes, with Director & Certificate
SELECT 
  m.title,
  d.name        AS director,
  c.certificate,
  v.no_of_votes
FROM Movies m
JOIN Directors d   ON m.director_id     = d.director_id
JOIN Certificates c ON m.certificate_id  = c.certificate_id
JOIN Votes v      ON m.movie_id         = v.movie_id
ORDER BY v.no_of_votes DESC
LIMIT 10;

-- Top 5 Highest-Grossing Films per Genre
WITH Ranked AS (
  SELECT
    g.genre_name,
    m.title,
    m.gross,
    ROW_NUMBER() OVER (PARTITION BY g.genre_id ORDER BY m.gross DESC) AS rn
  FROM Genres g
  JOIN Movie_Genres mg ON g.genre_id = mg.genre_id
  JOIN Movies m        ON mg.movie_id = m.movie_id
  WHERE m.gross IS NOT NULL
)
SELECT genre_name, title, gross
FROM Ranked
WHERE rn <= 5
ORDER BY genre_name, gross DESC;

-- Composers’ Genre Diversity (Genres Composed ≥ 5)
SELECT
  c.name                            AS composer,
  COUNT(DISTINCT g.genre_id)        AS distinct_genres
FROM Composers c
JOIN Movie_Composers mc ON c.composer_id = mc.composer_id
JOIN Movie_Genres mg     ON mc.movie_id    = mg.movie_id
JOIN Genres g             ON mg.genre_id   = g.genre_id
GROUP BY c.composer_id, c.name
HAVING COUNT(DISTINCT g.genre_id) >= 5
ORDER BY distinct_genres DESC;

-- Director–Actor Pairs with > 3 Collaborations
SELECT
  d.name         AS director,
  s.name         AS star,
  COUNT(*)       AS collaborations
FROM Directors d
JOIN Movies m        ON d.director_id = m.director_id
JOIN Movie_Stars ms  ON m.movie_id    = ms.movie_id
JOIN Stars s         ON ms.star_id    = s.star_id
GROUP BY d.director_id, s.star_id
HAVING COUNT(*) > 3
ORDER BY collaborations DESC;

-- Yearly Highest-Grossing Movie & Its Production Company
SELECT
  sub.release_year,
  sub.title,
  pc.name              AS production_company,
  sub.gross
FROM (
  SELECT
    m.movie_id,
    m.release_year,
    m.title,
    m.gross,
    ROW_NUMBER() OVER (
      PARTITION BY m.release_year
      ORDER BY m.gross DESC
    ) AS rn
  FROM Movies m
  WHERE m.gross IS NOT NULL
) AS sub
JOIN Movie_Production_Companies mpc
  ON sub.movie_id = mpc.movie_id
JOIN Production_Companies pc
  ON mpc.production_company_id = pc.production_company_id
WHERE sub.rn = 1
ORDER BY sub.release_year;

-- actors who have won at least one award
SELECT
  s.name             AS actor,
  ashow.show_name    AS award_show,
  ac.ceremony_year
FROM Stars AS s
JOIN Award_Nominations AS an
  ON s.star_id = an.star_id
JOIN Award_Ceremonies AS ac
  ON an.ceremony_id = ac.ceremony_id
JOIN Award_Shows AS ashow
  ON ac.award_show_id = ashow.award_show_id
WHERE an.won = TRUE
GROUP BY s.name, ashow.show_name, ac.ceremony_year
ORDER BY ac.ceremony_year DESC;

-- rank production companies by number of awards won
SELECT
  pc.name                                  AS production_company,
  COUNT(an.nomination_id)                  AS awards_won
FROM Production_Companies AS pc
JOIN Movie_Production_Companies AS mpc
  ON pc.production_company_id = mpc.production_company_id
JOIN Movies AS m
  ON mpc.movie_id = m.movie_id
JOIN Award_Nominations AS an
  ON m.movie_id = an.movie_id
JOIN Award_Ceremonies AS ac
  ON an.ceremony_id = ac.ceremony_id
WHERE an.won = TRUE
GROUP BY pc.name
ORDER BY awards_won DESC
LIMIT 10;





