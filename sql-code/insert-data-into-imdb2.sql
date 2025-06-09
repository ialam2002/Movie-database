
use imdb_db2;

DROP TABLE IF EXISTS temp_movies;

-- Create a temporary table to hold the raw CSV data
CREATE TABLE temp_movies (
  Poster_Link          TEXT,
  Series_Title         VARCHAR(512),
  Released_Year        VARCHAR(10),
  Certificate          VARCHAR(50),
  Runtime              VARCHAR(20),
  Genre                TEXT,
  IMDB_Rating          VARCHAR(10),
  Overview             TEXT,
  Meta_score           VARCHAR(10),
  Director             VARCHAR(255),
  Star1                VARCHAR(255),
  Star2                VARCHAR(255),
  Star3                VARCHAR(255),
  Star4                VARCHAR(255),
  No_of_Votes          VARCHAR(20),
  Gross                VARCHAR(50),
  Producers            TEXT,
  Composers            TEXT,
  Production_Companies TEXT
) ENGINE=InnoDB;

-- Load the CSV data into the temporary table
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 9.2/Uploads/imdb_top_1000_complete.csv"
INTO TABLE temp_movies
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"' 
ESCAPED BY '"' 
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
  Poster_Link,
  Series_Title,
  @Released_Year,
  Certificate,
  Runtime,
  Genre,
  @IMDB_Rating,
  Overview,
  @Meta_score,
  Director,
  Star1,
  Star2,
  Star3,
  Star4,
  @No_of_Votes,
  @Gross,
  Producers,
  Composers,
  @Production_Companies
)
SET
  Released_Year        = NULLIF(@Released_Year, ''),
  IMDB_Rating          = NULLIF(@IMDB_Rating,    ''),
  Meta_score           = NULLIF(@Meta_score,     ''),
  No_of_Votes          = NULLIF(@No_of_Votes,    ''),
  Gross                = NULLIF(@Gross,          ''),
  Production_Companies = NULLIF(@Production_Companies, '');
  
-- Process and insert data into normalized tables

-- Insert certificates
INSERT IGNORE INTO Certificates (certificate)
SELECT DISTINCT Certificate 
FROM temp_movies 
WHERE Certificate IS NOT NULL AND Certificate != '';

-- Insert directors
INSERT IGNORE INTO Directors (name)
SELECT DISTINCT Director 
FROM temp_movies 
WHERE Director IS NOT NULL AND Director != '';

-- Insert stars
INSERT IGNORE INTO Stars (name)
SELECT DISTINCT Star1 FROM temp_movies WHERE Star1 IS NOT NULL AND Star1 != ''
UNION
SELECT DISTINCT Star2 FROM temp_movies WHERE Star2 IS NOT NULL AND Star2 != ''
UNION
SELECT DISTINCT Star3 FROM temp_movies WHERE Star3 IS NOT NULL AND Star3 != ''
UNION
SELECT DISTINCT Star4 FROM temp_movies WHERE Star4 IS NOT NULL AND Star4 != '';

-- Insert movies (with proper type conversion and NULL handling)
INSERT INTO Movies (
    title, release_year, certificate_id, runtime_minutes, 
    imdb_rating, overview, meta_score, gross, poster_link, director_id
)
SELECT 
    t.Series_Title,
    NULLIF(t.Released_Year, ''),
    c.certificate_id,
    CAST(REPLACE(t.Runtime, ' min', '') AS UNSIGNED),
    CAST(NULLIF(t.IMDB_Rating, '') AS DECIMAL(3,1)),
    NULLIF(t.Overview, ''),
    NULLIF(t.Meta_score, ''),
    NULLIF(REPLACE(t.Gross, ',', ''), ''),
    NULLIF(t.Poster_Link, ''),
    d.director_id
FROM temp_movies t
LEFT JOIN Certificates c ON t.Certificate = c.certificate
LEFT JOIN Directors d ON t.Director = d.name;

-- Insert genres (handling comma-separated lists)
INSERT IGNORE INTO Genres (genre_name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Genre, ',', n.n), ',', -1))
FROM temp_movies t
JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) n
WHERE n.n <= 1 + (LENGTH(t.Genre) - LENGTH(REPLACE(t.Genre, ',', '')))
AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Genre, ',', n.n), ',', -1)) != ''
AND t.Genre IS NOT NULL;

-- Insert movie-genre relationships
INSERT IGNORE INTO Movie_Genres (movie_id, genre_id)
SELECT 
    m.movie_id,
    g.genre_id
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN (
    SELECT 
        t.Series_Title,
        t.Released_Year,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Genre, ',', n.n), ',', -1)) AS genre_name
    FROM temp_movies t
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    ) n
    WHERE n.n <= 1 + (LENGTH(t.Genre) - LENGTH(REPLACE(t.Genre, ',', '')))
    AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Genre, ',', n.n), ',', -1)) != ''
    AND t.Genre IS NOT NULL
) AS split_genres ON t.Series_Title = split_genres.Series_Title 
                  AND t.Released_Year = split_genres.Released_Year
JOIN Genres g ON split_genres.genre_name = g.genre_name;

-- Insert producers (handling semi-colon separated lists)
INSERT IGNORE INTO Producers (name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Producers, ';', n.n), ';', -1))
FROM temp_movies t
JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) n
WHERE n.n <= 1 + (LENGTH(t.Producers) - LENGTH(REPLACE(t.Producers, ';', '')))
AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Producers, ';', n.n), ';', -1)) != ''
AND t.Producers IS NOT NULL;

-- Insert movie-producer relationships
INSERT IGNORE INTO Movie_Producers (movie_id, producer_id)
SELECT 
    m.movie_id,
    p.producer_id
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN (
    SELECT 
        t.Series_Title,
        t.Released_Year,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Producers, ';', n.n), ';', -1)) AS producer_name
    FROM temp_movies t
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    ) n
    WHERE n.n <= 1 + (LENGTH(t.Producers) - LENGTH(REPLACE(t.Producers, ';', '')))
    AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Producers, ';', n.n), ';', -1)) != ''
    AND t.Producers IS NOT NULL
) AS split_producers ON t.Series_Title = split_producers.Series_Title 
                     AND t.Released_Year = split_producers.Released_Year
JOIN Producers p ON split_producers.producer_name = p.name;

-- Insert composers (handling semi-colon separated lists)
INSERT IGNORE INTO Composers (name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Composers, ';', n.n), ';', -1))
FROM temp_movies t
JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
    SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) n
WHERE n.n <= 1 + (LENGTH(t.Composers) - LENGTH(REPLACE(t.Composers, ';', '')))
AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Composers, ';', n.n), ';', -1)) != ''
AND t.Composers IS NOT NULL;

-- Insert movie-composer relationships
INSERT IGNORE INTO Movie_Composers (movie_id, composer_id)
SELECT 
    m.movie_id,
    c.composer_id
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN (
    SELECT 
        t.Series_Title,
        t.Released_Year,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Composers, ';', n.n), ';', -1)) AS composer_name
    FROM temp_movies t
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    ) n
    WHERE n.n <= 1 + (LENGTH(t.Composers) - LENGTH(REPLACE(t.Composers, ';', '')))
    AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Composers, ';', n.n), ';', -1)) != ''
    AND t.Composers IS NOT NULL
) AS split_composers ON t.Series_Title = split_composers.Series_Title 
                      AND t.Released_Year = split_composers.Released_Year
JOIN Composers c ON split_composers.composer_name = c.name;

-- Insert movie-star relationships
INSERT IGNORE INTO Movie_Stars (movie_id, star_id, billing_order)
SELECT 
    m.movie_id,
    s.star_id,
    1 AS billing_order
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN Stars s ON t.Star1 = s.name
WHERE t.Star1 IS NOT NULL AND t.Star1 != ''

UNION ALL

SELECT 
    m.movie_id,
    s.star_id,
    2 AS billing_order
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN Stars s ON t.Star2 = s.name
WHERE t.Star2 IS NOT NULL AND t.Star2 != ''

UNION ALL

SELECT 
    m.movie_id,
    s.star_id,
    3 AS billing_order
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN Stars s ON t.Star3 = s.name
WHERE t.Star3 IS NOT NULL AND t.Star3 != ''

UNION ALL

SELECT 
    m.movie_id,
    s.star_id,
    4 AS billing_order
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
JOIN Stars s ON t.Star4 = s.name
WHERE t.Star4 IS NOT NULL AND t.Star4 != '';

-- Insert votes
INSERT INTO Votes (movie_id, no_of_votes)
SELECT 
    m.movie_id,
    CAST(NULLIF(t.No_of_Votes, '') AS UNSIGNED)
FROM temp_movies t
JOIN Movies m ON t.Series_Title = m.title AND t.Released_Year = m.release_year
WHERE t.No_of_Votes IS NOT NULL AND t.No_of_Votes != '';



-- Populate Production_Companies from temp_movies

INSERT IGNORE INTO Production_Companies (name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Production_Companies, ';', n.n), ';', -1))
FROM temp_movies t
-- adjust the max splits to the maximum number of companies you expect
JOIN (
    SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
  UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) AS n
WHERE n.n <= 1 + (LENGTH(t.Production_Companies) - LENGTH(REPLACE(t.Production_Companies, ';', '')))
  AND t.Production_Companies IS NOT NULL
  AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Production_Companies, ';', n.n), ';', -1)) != '';


-- Link movies to their production companies

INSERT IGNORE INTO Movie_Production_Companies (movie_id, production_company_id)
SELECT 
  m.movie_id,
  pc.production_company_id
FROM temp_movies t
JOIN Movies m
  ON t.Series_Title   = m.title
 AND t.Released_Year  = m.release_year
-- split out each semicolon-separated company
JOIN (
    SELECT 
      t.Series_Title,
      t.Released_Year,
      TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Production_Companies, ';', n.n), ';', -1)) AS company_name
    FROM temp_movies t
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
    ) AS n
    WHERE n.n <= 1 + (LENGTH(t.Production_Companies) - LENGTH(REPLACE(t.Production_Companies, ';', '')))
      AND t.Production_Companies IS NOT NULL
      AND TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(t.Production_Companies, ';', n.n), ';', -1)) != ''
) AS split_pc
  ON t.Series_Title  = split_pc.Series_Title
 AND t.Released_Year = split_pc.Released_Year
JOIN Production_Companies pc
  ON split_pc.company_name = pc.name;


-- Clean up
DROP  TABLE IF EXISTS temp_movies;

