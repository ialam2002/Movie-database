# 🎬 IMDb-Inspired Movie Database (SQL Project)

A robust relational database project for movies and awards, inspired by the structure of IMDb. This project models movies, people (directors, stars, producers, composers), genres, companies, awards, and their interconnections, using advanced SQL design and normalization.

---

## 🗂️ Schema Overview

### Core Tables

| Table                     | Purpose / Key Fields                                                                                                                                                     |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Movies**                | Each film: `movie_id` (PK), `title`, `release_year`, `certificate_id`, `runtime_minutes`, `imdb_rating`, `overview`, `meta_score`, `gross`, `poster_link`, `director_id` |
| **Certificates**          | Rating/certification for movies: `certificate_id` (PK), `certificate`                                                                                                    |
| **Directors**             | Movie directors: `director_id` (PK), `name`, `birth_date`                                                                                                                |
| **Stars**                 | Leading actors/actresses: `star_id` (PK), `name`, `birth_date`                                                                                                           |
| **Producers**             | Film producers: `producer_id` (PK), `name`                                                                                                                               |
| **Composers**             | Music composers: `composer_id` (PK), `name`                                                                                                                              |
| **Genres**                | Movie genres: `genre_id` (PK), `genre_name`                                                                                                                              |
| **Production\_Companies** | Studios/companies: `production_company_id` (PK), `name`                                                                                                                  |
| **Votes**                 | IMDb vote counts: `movie_id` (PK, FK), `no_of_votes`                                                                                                                     |

### Relationship Tables (for Many-to-Many Relations)

| Table                            | Relationship                  | Key Fields                                               |
| -------------------------------- | ----------------------------- | -------------------------------------------------------- |
| **Movie\_Stars**                 | Movies ↔ Stars                | `movie_id` (PK, FK), `star_id` (PK, FK), `billing_order` |
| **Movie\_Genres**                | Movies ↔ Genres               | `movie_id` (PK, FK), `genre_id` (PK, FK)                 |
| **Movie\_Producers**             | Movies ↔ Producers            | `movie_id` (PK, FK), `producer_id` (PK, FK)              |
| **Movie\_Composers**             | Movies ↔ Composers            | `movie_id` (PK, FK), `composer_id` (PK, FK)              |
| **Movie\_Production\_Companies** | Movies ↔ Production Companies | `movie_id` (PK, FK), `production_company_id` (PK, FK)    |

### Awards Schema

| Table                  | Purpose / Key Fields                                                                                                                                |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Award\_Shows**       | Awards shows (e.g., Oscars): `award_show_id` (PK), `show_name`                                                                                      |
| **Award\_Ceremonies**  | Specific ceremonies: `ceremony_id` (PK), `award_show_id` (FK), `ceremony_year`, `ceremony_number`, `ceremony_date`                                  |
| **Award\_Categories**  | Award categories: `category_id` (PK), `award_show_id` (FK), `category_name`                                                                         |
| **Award\_Nominations** | Nominations & wins: `nomination_id` (PK), `ceremony_id` (FK), `category_id` (FK), `movie_id` (FK), `director_id` (FK), `star_id` (FK), `won` (bool) |


## 🖥️ Streamlit User Interface

An interactive Streamlit web application is provided for browsing, searching, and managing your movie database.
This dashboard connects directly to the MySQL backend and supports both data visualization and entry.

✨ Key Features
Catalog & Search:
Browse movies in a responsive grid, filter by title, year, genre, director, cast, and more.

Sorting & Pagination:
Sort movies by title, year, rating, or vote count; view results with clean pagination.

Movie Details:
View detailed movie pages with poster, stats, genres, cast, crew, production companies, and overview.

High-Resolution Posters:
Optional integration with TMDB API to fetch high-res movie posters.

Add New Movies:
Fill out a form to add a new movie with associated genres, cast, crew, and production info.
All necessary join-table records (e.g., Movie_Stars, Movie_Genres, etc.) are created automatically.

Modern Look:
Custom CSS styling for a clean, modern dashboard appearance.

🚀 How It Works
Backend:

Connects to the MySQL database using mysql-connector-python.

Supports full CRUD for movies (currently, UI enables adding movies and viewing all details).

Ensures all many-to-many relationships (genres, stars, producers, composers, companies) are correctly handled.

Frontend:

Written entirely in Python with Streamlit, no HTML/JS required.

Instant UI updates with cache invalidation after data changes.

Sidebar for navigation, filters, and sorting controls.
