# Data Acquisition: APIs and Web Scraping

## Problem

Extracting structured data from external sources—REST APIs with pagination and nested JSON, plus HTML pages with semantic structure—and transforming them into tidy R data frames for analysis. Two complementary patterns: stateful API pagination with credential management, and CSS selector-based DOM traversal.

## Approach

Two modules integrated within one project:

**APIs Module** (`src/apis/`):
- Smithsonian Open Access API: demonstrates pagination with offset-based indexing, httr2 request building, keyring credential storage, and hoist/unnest for JSON flattening.
- NASA APOD: demonstrates simple query-based API calls, list-to-tibble conversion, and text metric extraction.

**Scraping Module** (`src/scraping/`):

> Note: the IMDB script is a demonstration of scraping technique. It is not intended for production use or for redistribution of scraped content. Review IMDB's Terms of Service before running against a live page.

- IMDB Top 100 Foreign Films: demonstrates CSS selector strategy, mapping selectors over DOM elements, handling missing fields, and multi-step data cleaning (field separation, type conversion, text parsing).

Both modules emphasize reusable helper functions (smith_search, scrape_imdb_movies, clean_imdb_movies) and tidyverse conventions.

## Results

**Smithsonian**: Pagination query for "artificial intelligence" returns 10 records across Smithsonian departments. Sample extraction yields tibble with id, title, link, object_type (unnested), data_source, unitCode, record_ID, content and resp_list.

**NASA APOD**: Jan 2023 sample (10 days) yields 10 records with date, title, media_type (image/video), title_length, has_copyright flag, URLs and copyright. Demonstrates weak relationship between title length and explanation length.

**IMDB Foreign Films**: 25-row snapshot with Rank, Title, Year, Run_time (period), MPAA_rating, Metascore, Star_rating (numeric 0-10), Votes (numeric counts), Plot, Country. Ready for modeling (Star_rating vs. Metascore shows no significant relationship in sample).

## Data Sources

- **Smithsonian Open Access API**: https://api.si.edu/openaccess/api/v1.0/search (Public, requires API key from https://api.data.gov/signup/)
- **NASA Astronomy Picture of the Day**: https://api.nasa.gov/planetary/apod (Public, free key at https://api.nasa.gov/)
- **IMDB Top 100 Best Foreign Films**: https://www.imdb.com/list/ls062615147/ (Note: see Limitations)

## Project Structure

```
.
├── README.md
├── LICENSE
├── .gitignore
├── src/
│   ├── apis/
│   │   ├── fetch_smithsonian.R
│   │   └── fetch_nasa_apod.R
│   └── scraping/
│       └── scrape_imdb_foreign_films.R
├── examples/
│   ├── demo_apis.R
│   └── demo_scraping.R
└── data_raw/
    └── imdb_html_25-09-17.html

```

## Usage

**R Version**: 4.0+

**Required Packages**:
```r
install.packages(c("tidyverse", "httr2", "jsonlite", "rvest", "keyring", "lubridate", "readr", "stringr"))
```

**API Key Setup**:

1. **Smithsonian**: Obtain free API key from https://api.data.gov/signup/
   ```r
   keyring::key_set("API_KEY_DATA-GOV", prompt = FALSE)
   # Then paste your key when prompted
   ```

2. **NASA APOD**: Obtain free API key from https://api.nasa.gov/
   ```r
   keyring::key_set("API_KEY_NASA", prompt = FALSE)
   # Then paste your key when prompted
   ```
**Reset a key** (if entered incorrectly):
```r
keyring::key_delete("API_KEY_NASA")
keyring::key_set("API_KEY_NASA", prompt = "Enter NASA API key:")
```

**Entry Scripts**:

Smithsonian single query:
```r
source("src/apis/fetch_smithsonian.R")
req <- request("https://api.si.edu/openaccess/api/v1.0/search")
results <- smith_search(req, q = "artificial intelligence", rows = 20)
```

Smithsonian pagination:
```r
source("src/apis/fetch_smithsonian.R")
req <- request("https://api.si.edu/openaccess/api/v1.0/search")
resp_list <- paginate_smithsonian(req, q = "elephant", max_pages = 5)
df_all <- flatten_paginated_smithsonian(resp_list)
```

NASA APOD:
```r
source("src/apis/fetch_nasa_apod.R")
apod_raw <- fetch_apod("2023-01-01", "2023-04-30")
apod_df <- apod_to_tibble(apod_raw)
apod_clean <- clean_apod(apod_df)
```

IMDB:
```r
source("src/scraping/scrape_imdb_foreign_films.R")
movies_raw <- scrape_imdb_movies("path/to/imdb_html.html")
movies_clean <- clean_imdb_movies(movies_raw)
```

## Tech Stack

- **Language**: R 4.0+
- **HTTP & JSON**: httr2, jsonlite
- **Web Scraping**: rvest
- **Data Wrangling**: tidyverse (dplyr, tidyr, stringr, purrr, readr, lubridate)
- **Credential Management**: keyring
- **Functional Patterns**: Anonymous functions (\(x) ...), map/map2, pipe (|>)

## Limitations

**API Rate Limits**:
- Smithsonian: 1000 requests/hour (enforced by api.data.gov)
- NASA: 1000 requests/hour (with API key)
- Pagination loops configured conservatively (max_pages = 5) to respect limits

**Scraping ToS & Data**:
- IMDB scraping may violate their Terms of Service (check https://www.imdb.com/conditions)
- This project scrapes only the static first-page snapshot for educational purposes
- IMDB HTML snapshot is provided in data_raw/ for reproducibility; live scraping not automated
- Scraped IMDB data should not be redistributed without permission

**Schema Drift**:
- CSS selectors are brittle to DOM restructuring (IMDB updates frequently)
- Smithsonian API search semantics vary with quotation marks in queries (confirmed quirk)
- Smithsonian row limits >1000 exhibit inconsistent truncation behavior

**Data Completeness**:
- IMDB: Only ~25 movies on first page; full 100 requires browser-based scrolling (chromote required)
- Metascore: Missing for many IMDB films (returns NA)
- APOD copyright: Optional field; NULL for public-domain images

**Data Completeness**:
- IMDB: Only ~25 movies on first page; full 100 requires browser-based scrolling (chromote required)
- Metascore: Missing for many IMDB films (returns NA)
- APOD copyright: Optional field; NULL for public-domain images
- Smithsonian: Fields like object_type, data_source, unitCode, and record_ID return NA for library/archive records where those metadata paths do not exist in the JSON response

## License

MIT
