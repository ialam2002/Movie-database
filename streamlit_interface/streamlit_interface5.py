import streamlit as st
import mysql.connector
from mysql.connector import errorcode
import decimal
import requests
from math import ceil


# Configuration: update these with your MySQL credentials
DB_CONFIG = {
    "host": "localhost",
    "user": "iftekhar",
    "password": "asteros9120",
    "database": "imdb_db2"
}
# TMDB API (for high-resolution posters)
TMDB_API_KEY = "6e03ae736325bef159b060dfab982efe"  # Get from https://www.themoviedb.org/
TMDB_SEARCH_URL = "https://api.themoviedb.org/3/search/movie"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p/w500"
ITEMS_PER_PAGE = 12

# --- Database Helpers ---
def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def get_or_create(table, id_col, name_col, value):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(f"SELECT {id_col} FROM {table} WHERE {name_col}=%s", (value,))
    row = cur.fetchone()
    if row:
        cur.close()
        conn.close()
        return row[0]
    cur.execute(f"INSERT INTO {table} ({name_col}) VALUES (%s)", (value,))
    conn.commit()
    new_id = cur.lastrowid
    cur.close()
    conn.close()
    return new_id

# Insert full movie with related entities
def add_full_movie(data):
    conn = get_connection()
    cur = conn.cursor()

    # 1) Insert base movie record
    cur.execute(
        """
        INSERT INTO Movies
          (title, release_year, runtime_minutes, imdb_rating,
           overview, meta_score, gross, poster_link)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        (data['title'], data['year'], data['runtime'], data['rating'],
         data['overview'], data['meta_score'], data['gross'], data['poster_url'])
    )
    movie_id = cur.lastrowid

    # 2) Initialize votes row
    cur.execute(
        "INSERT INTO Votes (movie_id, no_of_votes) VALUES (%s, 0)",
        (movie_id,)
    )

    # 3) Certificate & director
    if data['certificate']:
        cert_id = get_or_create('Certificates', 'certificate_id', 'certificate', data['certificate'])
        cur.execute(
            "UPDATE Movies SET certificate_id = %s WHERE movie_id = %s",
            (cert_id, movie_id)
        )
    if data['director']:
        dir_id = get_or_create('Directors', 'director_id', 'name', data['director'])
        cur.execute(
            "UPDATE Movies SET director_id = %s WHERE movie_id = %s",
            (dir_id, movie_id)
        )

    # 4) Helpers for linking M–N tables
    def link_with_order(join_table, ref_table, id_col, join_fk, items, name_col):
        """Use billing_order for Movie_Stars only."""
        for order, item in enumerate(items, start=1):
            if item:
                ent_id = get_or_create(ref_table, id_col, name_col, item)
                cur.execute(
                    f"INSERT INTO {join_table} (movie_id, {join_fk}, billing_order) "
                    "VALUES (%s, %s, %s)",
                    (movie_id, ent_id, order)
                )

    def link_simple(join_table, ref_table, id_col, join_fk, items, name_col):
        """Plain two-column insert for other join tables."""
        for item in items:
            if item:
                ent_id = get_or_create(ref_table, id_col, name_col, item)
                cur.execute(
                    f"INSERT INTO {join_table} (movie_id, {join_fk}) VALUES (%s, %s)",
                    (movie_id, ent_id)
                )

    # 5) Link genres (no order), stars (with order), producers, composers, companies
    link_simple(
        'Movie_Genres', 'Genres',
        'genre_id', 'genre_id',
        data['genres'], 'genre_name'
    )
    link_with_order(
        'Movie_Stars', 'Stars',
        'star_id', 'star_id',
        data['stars'], 'name'
    )
    link_simple(
        'Movie_Producers', 'Producers',
        'producer_id', 'producer_id',
        data['producers'], 'name'
    )
    link_simple(
        'Movie_Composers', 'Composers',
        'composer_id', 'composer_id',
        data['composers'], 'name'
    )
    link_simple(
        'Movie_Production_Companies', 'Production_Companies',
        'production_company_id', 'production_company_id',
        data['companies'], 'name'
    )

    # 6) Commit & clean up
    conn.commit()
    cur.close()
    conn.close()
    
# --- Caching & Data Loading ---
@st.cache_data(ttl=600)
def load_all_movies():
    conn = get_connection()
    cursor = conn.cursor()
    query = """
    SELECT
      m.movie_id, m.title, m.release_year, m.poster_link,
      CAST(m.imdb_rating AS CHAR), v.no_of_votes,
      c.certificate, d.name AS director,
      m.overview, m.meta_score, m.gross,
      GROUP_CONCAT(DISTINCT g.genre_name) AS genres,
      GROUP_CONCAT(DISTINCT s.name ORDER BY ms.billing_order) AS stars,
      GROUP_CONCAT(DISTINCT p.name) AS producers,
      GROUP_CONCAT(DISTINCT comp.name) AS composers,
      GROUP_CONCAT(DISTINCT pc.name) AS companies
    FROM Movies m
    LEFT JOIN Votes v ON m.movie_id=v.movie_id
    LEFT JOIN Certificates c ON m.certificate_id=c.certificate_id
    LEFT JOIN Directors d ON m.director_id=d.director_id
    LEFT JOIN Movie_Genres mg ON m.movie_id=mg.movie_id
    LEFT JOIN Genres g ON mg.genre_id=g.genre_id
    LEFT JOIN Movie_Stars ms ON m.movie_id=ms.movie_id
    LEFT JOIN Stars s ON ms.star_id=s.star_id
    LEFT JOIN Movie_Producers mp ON m.movie_id=mp.movie_id
    LEFT JOIN Producers p ON mp.producer_id=p.producer_id
    LEFT JOIN Movie_Composers mc ON m.movie_id=mc.movie_id
    LEFT JOIN Composers comp ON mc.composer_id=comp.composer_id
    LEFT JOIN Movie_Production_Companies mpc ON m.movie_id=mpc.movie_id
    LEFT JOIN Production_Companies pc ON mpc.production_company_id=pc.production_company_id
    GROUP BY m.movie_id;
    """
    cursor.execute(query)
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    movies = []
    for row in rows:
        mid, title, year, poster, rating, votes, cert, director, overview, metascore, gross, genres, stars, producers, composers, companies = row
        rating = float(rating or 0)
        votes = int(votes or 0)
        metascore = int(metascore) if metascore is not None else None
        gross = int(gross) if gross is not None else None
        split = lambda x: x.split(',') if x else []
        movies.append({
            'id': mid, 'title': title, 'year': year,
            'poster': poster, 'rating': rating, 'votes': votes,
            'certificate': cert, 'director': director,
            'overview': overview, 'meta_score': metascore, 'gross': gross,
            'genres': split(genres), 'stars': split(stars),
            'producers': split(producers), 'composers': split(composers), 'companies': split(companies)
        })
    return movies

@st.cache_data(ttl=86400)
def get_high_res_poster_tmdb(title, year):
    try:
        resp = requests.get(
            TMDB_SEARCH_URL,
            params={"api_key":TMDB_API_KEY, "query":title, "year":year},
            timeout=5
        )
        data = resp.json()
        results = data.get('results') or []
        if results:
            path = results[0].get('poster_path')
            return f"{TMDB_IMAGE_BASE}{path}" if path else None
    except:
        return None

# --- Streamlit Setup ---
st.set_page_config(page_title="🎥 Movie Dashboard", layout="wide")
st.markdown(
    """
<style>
  /* App and Sidebar Background */
  [data-testid="stAppViewContainer"] {
    background: #f5f5f5 !important;
  }

  [data-testid="stSidebar"] {
    background: #fafafa !important;
  }

  /* Default Text Color */
  body,
  .stApp,
  .stApp * {
    color: #333 !important;
  }

  /* Button Styles */
  .stButton > button {
    background: #fff !important;
    border: 1px solid #ccc !important;
    color: #333 !important;
  }

  /* Input, Textarea, Select Fields */
  input,
  textarea,
  select {
    background-color: #fff !important;
    color: #333 !important;
  }

  /* Placeholder Text */
  input::placeholder,
  textarea::placeholder {
    color: #666 !important;
    opacity: 1 !important;
  }

  /* Combobox (Select/Multiselect) */
  div[role="combobox"] > div:first-of-type,
  div[role="combobox"] input {
    background-color: #fff !important;
    color: #333 !important;
  }

  /* Slider Track */
  input[type="range"] {
    background: #ddd !important;
  }

  /* Number Input (+/- Buttons) */
  .stNumberInput button {
    background-color: #fff !important;
    border: 1px solid #ccc !important;
    color: #333 !important;
  }

  /* Remove Default Shadows */
  .css-1lcbmhc,
  .css-ffhzg2 {
    box-shadow: none !important;
  }
</style>
    """,
    unsafe_allow_html=True
)

# --- Navigation ---
page = st.sidebar.radio("Navigation", ["Catalog", "Add Movie"])
all_movies = load_all_movies()

if page == "Catalog":
    # Filters & Sort
    st.sidebar.header("Filters & Sort")
    search = st.sidebar.text_input("Title contains...")
    year_min, year_max = st.sidebar.slider("Year range",1900,2100,(2000,2025))
    r_min, r_max = st.sidebar.slider("Rating range",0.0,10.0,(0.0,10.0),0.1)
    genres = st.sidebar.multiselect("Genres", sorted({g for m in all_movies for g in m['genres']}))
    directors = st.sidebar.multiselect("Directors", sorted({m['director'] for m in all_movies if m['director']}))
    stars = st.sidebar.multiselect("Stars", sorted({s for m in all_movies for s in m['stars']}))
    producers = st.sidebar.multiselect("Producers", sorted({p for m in all_movies for p in m['producers']}))
    composers = st.sidebar.multiselect("Composers", sorted({c for m in all_movies for c in m['composers']}))
    companies = st.sidebar.multiselect("Companies", sorted({c for m in all_movies for c in m['companies']}))
    sort_by = st.sidebar.selectbox("Sort by", ["Title A-Z","Newest","Highest Rating","Most Votes"])
    use_tmdb = st.sidebar.checkbox("High-res posters", value=False)
    st.sidebar.markdown("---")

    if st.session_state.get('selected_id'):
        # Detailed view
        details = next(m for m in all_movies if m['id']==st.session_state['selected_id'])
        st.header(f"{details['title']} ({details['year']})")
        cols = st.columns([1,3])
        poster = details['poster']
        if use_tmdb:
            poster = get_high_res_poster_tmdb(details['title'], details['year']) or poster
        if poster: cols[0].image(poster, use_column_width=True)
        cols[1].metric("Rating", details['rating'])
        cols[1].metric("Meta Score", details['meta_score'])
        cols[1].metric("Votes", details['votes'])
        cols[1].write(f"**Director:** {details['director']}")
        cols[1].write(f"**Certificate:** {details['certificate']}")
        cols[1].write(f"**Gross:** ${details['gross']:,}" if details['gross'] else "N/A")
        cols[1].expander("Stars").write(", ".join(details['stars']) or "N/A")
        cols[1].expander("Producers").write(", ".join(details['producers']) or "N/A")
        cols[1].expander("Composers").write(", ".join(details['composers']) or "N/A")
        cols[1].expander("Companies").write(", ".join(details['companies']) or "N/A")
        cols[1].expander("Genres").write(", ".join(details['genres']) or "N/A")
        cols[1].expander("Overview").write(details['overview'] or "No overview.")
        if st.button("← Back to catalog"): st.session_state['selected_id'] = None
    else:
        # Grid view
        filtered = [m for m in all_movies if (
            search.lower() in m['title'].lower()
            and year_min<=m['year']<=year_max
            and r_min<=m['rating']<=r_max
            and (not genres or any(g in m['genres'] for g in genres))
            and (not directors or m['director'] in directors)
            and (not stars or any(s in m['stars'] for s in stars))
            and (not producers or any(p in m['producers'] for p in producers))
            and (not composers or any(c in m['composers'] for c in composers))
            and (not companies or any(c in m['companies'] for c in companies))
        )]
        if sort_by=="Newest": filtered.sort(key=lambda x:x['year'], reverse=True)
        elif sort_by=="Highest Rating": filtered.sort(key=lambda x:x['rating'], reverse=True)
        elif sort_by=="Most Votes": filtered.sort(key=lambda x:x['votes'], reverse=True)
        else: filtered.sort(key=lambda x:x['title'])
        total = len(filtered)
        pages = ceil(total/ITEMS_PER_PAGE)
        page_num = int(st.sidebar.radio("Page",[str(i) for i in range(1, pages + 1)],index=0))
        subset = filtered[(page_num-1)*ITEMS_PER_PAGE:page_num*ITEMS_PER_PAGE]
        st.subheader(f"Showing {(page_num-1)*ITEMS_PER_PAGE+1}–{min(page_num*ITEMS_PER_PAGE,total)} of {total}")
        cols = st.columns(4)
        for idx,m in enumerate(subset):
            col = cols[idx%4]
            url = m['poster']
            if use_tmdb:
                url = get_high_res_poster_tmdb(m['title'], m['year']) or url
            if url: col.image(url, use_column_width=True)
            col.markdown(f"**{m['title']}** ({m['year']})")
            if col.button("Details", key=f"d{m['id']}"):
                st.session_state['selected_id'] = m['id']

elif page == "Add Movie":
    st.header("Add a New Movie")
    with st.form(key="add_movie_form", clear_on_submit=False):
        title = st.text_input("Title")
        year = st.number_input("Release Year", min_value=1880, max_value=2100, value=2025)
        runtime = st.number_input("Runtime (min)", min_value=1, value=90)
        rating = st.number_input("IMDB Rating", min_value=0.0, max_value=10.0, step=0.1, value=5.0)
        overview = st.text_area("Overview")
        meta_score = st.number_input("Meta Score", min_value=0, max_value=100, value=50)
        gross = st.number_input("Gross ($)", min_value=0, value=0)
        poster_url = st.text_input("Poster URL (optional)")
        certificate = st.text_input("Certificate")
        director = st.text_input("Director")
        stars_in = st.text_input("Stars (comma-separated)")
        genres_in = st.text_input("Genres (comma-separated)")
        producers_in = st.text_input("Producers (comma-separated)")
        composers_in = st.text_input("Composers (comma-separated)")
        companies_in = st.text_input("Production Companies (comma-separated)")
        submitted = st.form_submit_button("Add Movie")
        if submitted:
            data = {
                'title': title,
                'year': year,
                'runtime': runtime,
                'rating': rating,
                'overview': overview,
                'meta_score': meta_score,
                'gross': gross,
                'poster_url': poster_url or None,
                'certificate': certificate,
                'director': director,
                'stars': [s.strip() for s in stars_in.split(',') if s.strip()],
                'genres': [g.strip() for g in genres_in.split(',') if g.strip()],
                'producers': [p.strip() for p in producers_in.split(',') if p.strip()],
                'composers': [c.strip() for c in composers_in.split(',') if c.strip()],
                'companies': [c.strip() for c in companies_in.split(',') if c.strip()]
            }
            try:
                add_full_movie(data)
                st.cache_data.clear()
                st.success(f"✅ Added '{title}' successfully!")
            except mysql.connector.Error as e:
                st.error(f"Error adding movie: {e}")

# Footer
st.markdown("---")
st.markdown("<p style='text-align:center;'>Developed with 🛠️ & Streamlit</p>", unsafe_allow_html=True)





