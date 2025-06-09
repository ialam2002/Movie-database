CREATE DATABASE IF NOT EXISTS imdb_db2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE imdb_db2;

-- CERTIFICATES
CREATE TABLE Certificates (
  certificate_id INT AUTO_INCREMENT PRIMARY KEY,
  certificate     VARCHAR(50) NOT NULL,
  UNIQUE KEY (certificate)
) ENGINE=InnoDB;

-- DIRECTORS
CREATE TABLE Directors (
  director_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  birth_date DATE NULL,
  UNIQUE KEY (name)
) ENGINE=InnoDB;

-- PRODUCERS
CREATE TABLE Producers (
  producer_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  UNIQUE KEY (name)
) ENGINE=InnoDB;

-- COMPOSERS
CREATE TABLE Composers (
  composer_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  UNIQUE KEY (name)
) ENGINE=InnoDB;

-- STARS
CREATE TABLE Stars (
  star_id INT AUTO_INCREMENT PRIMARY KEY,
  name    VARCHAR(255) NOT NULL,
  birth_date DATE NULL,
  UNIQUE KEY (name)
) ENGINE=InnoDB;

-- GENRES
CREATE TABLE Genres (
  genre_id   INT AUTO_INCREMENT PRIMARY KEY,
  genre_name VARCHAR(100) NOT NULL,
  UNIQUE KEY (genre_name)
) ENGINE=InnoDB;

-- MOVIES
CREATE TABLE Movies (
  movie_id        INT AUTO_INCREMENT PRIMARY KEY,
  title           VARCHAR(255)    NOT NULL,
  release_year    YEAR            NOT NULL,
  certificate_id  INT             NULL,
  runtime_minutes INT             NOT NULL  CHECK (runtime_minutes > 0),
  imdb_rating     DECIMAL(3,1)    NOT NULL  CHECK (imdb_rating BETWEEN 0 AND 10),
  overview        TEXT            NULL,
  meta_score      INT             NULL      CHECK (meta_score BETWEEN 0 AND 100),
  gross           BIGINT UNSIGNED NULL      CHECK (gross >= 0),
  poster_link     VARCHAR(2048)   NULL,
  director_id     INT             NULL,
  
  UNIQUE KEY uq_movie_title_year (title, release_year),

  FOREIGN KEY (certificate_id)
    REFERENCES Certificates(certificate_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,

  FOREIGN KEY (director_id)
    REFERENCES Directors(director_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- MOVIE ↔ STAR (Many-to-Many)
CREATE TABLE Movie_Stars (
  movie_id      INT NOT NULL,
  star_id       INT NOT NULL,
  billing_order TINYINT NOT NULL  CHECK (billing_order > 0),

  PRIMARY KEY (movie_id, star_id),

  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  FOREIGN KEY (star_id)
    REFERENCES Stars(star_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- MOVIE ↔ GENRE (Many-to-Many)
CREATE TABLE Movie_Genres (
  movie_id INT NOT NULL,
  genre_id INT NOT NULL,

  PRIMARY KEY (movie_id, genre_id),

  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  FOREIGN KEY (genre_id)
    REFERENCES Genres(genre_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- MOVIE ↔ PRODUCER (Many-to-Many)
CREATE TABLE Movie_Producers (
  movie_id    INT NOT NULL,
  producer_id INT NOT NULL,

  PRIMARY KEY (movie_id, producer_id),

  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  FOREIGN KEY (producer_id)
    REFERENCES Producers(producer_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- MOVIE ↔ COMPOSER (Many-to-Many)
CREATE TABLE Movie_Composers (
  movie_id    INT NOT NULL,
  composer_id INT NOT NULL,

  PRIMARY KEY (movie_id, composer_id),

  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  FOREIGN KEY (composer_id)
    REFERENCES Composers(composer_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- VOTES
CREATE TABLE Votes (
  movie_id     INT           PRIMARY KEY,
  no_of_votes  INT NOT NULL  DEFAULT 0  CHECK (no_of_votes >= 0),

  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Production Companies
CREATE TABLE Production_Companies (
  production_company_id INT AUTO_INCREMENT PRIMARY KEY,
  name                  VARCHAR(255) NOT NULL,
  UNIQUE KEY (name)
) ENGINE=InnoDB;

CREATE TABLE Movie_Production_Companies (
  movie_id                INT NOT NULL,
  production_company_id   INT NOT NULL,
  PRIMARY KEY (movie_id, production_company_id),
  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (production_company_id)
    REFERENCES Production_Companies(production_company_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- award shows (oscars/golden globe)
CREATE TABLE Award_Shows (
  award_show_id   INT AUTO_INCREMENT PRIMARY KEY,
  show_name       VARCHAR(100) NOT NULL UNIQUE   -- e.g. 'Oscars', 'Golden Globe'
) ENGINE=InnoDB;

-- Individual ceremonies (by year and/or number)
CREATE TABLE Award_Ceremonies (
  ceremony_id     INT AUTO_INCREMENT PRIMARY KEY,
  award_show_id   INT NOT NULL,
  ceremony_year   VARCHAR(9)   NOT NULL,         -- e.g. '2025' or '1927/28'
  ceremony_number INT          NULL,             -- (e.g. 97th Academy Awards)
  ceremony_date   DATE         NULL,
  UNIQUE KEY uq_show_year (award_show_id, ceremony_year),
  FOREIGN KEY (award_show_id)
    REFERENCES Award_Shows(award_show_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- Categories per show
CREATE TABLE Award_Categories (
  category_id    INT AUTO_INCREMENT PRIMARY KEY,
  award_show_id  INT NOT NULL,
  category_name  VARCHAR(255) NOT NULL,           -- e.g. 'Best Director'
  UNIQUE KEY uq_show_category (award_show_id, category_name),
  FOREIGN KEY (award_show_id)
    REFERENCES Award_Shows(award_show_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- The nominations 
CREATE TABLE Award_Nominations (
  nomination_id  INT AUTO_INCREMENT PRIMARY KEY,
  ceremony_id    INT   NOT NULL,
  category_id    INT   NOT NULL,
  movie_id       INT   NULL,
  director_id    INT   NULL,
  star_id        INT   NULL,
  won            BOOLEAN NOT NULL DEFAULT FALSE,


  FOREIGN KEY (ceremony_id)
    REFERENCES Award_Ceremonies(ceremony_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (category_id)
    REFERENCES Award_Categories(category_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (movie_id)
    REFERENCES Movies(movie_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  FOREIGN KEY (director_id)
    REFERENCES Directors(director_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  FOREIGN KEY (star_id)
    REFERENCES Stars(star_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;


