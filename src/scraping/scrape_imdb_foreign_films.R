# Web scraping module: IMDB Top 100 Best Foreign Films
# Uses rvest for CSS selector-based extraction and tidyverse for data cleaning

library(rvest)
library(tidyverse)
library(stringr)
library(lubridate)
library(readr)

#' Extract text from IMDB movie elements using CSS selectors
#'
#' Creates a reusable function that maps CSS selectors over a list of movie DOM nodes.
#' Handles missing elements gracefully by returning NA rather than erroring.
#'
#' @param movie_data A list of rvest html_elements (one per movie)
#' @param css A CSS selector string targeting the desired element
#'
#' @return A character vector of text values (NA where element missing)
#'
get_imdb_text <- function(movie_data, css) {
  movie_data |>
    map(\(x) {
      node <- html_element(x, css)
      if (!is.na(node) && length(node) > 0) html_text2(node) else NA_character_
    }) |>
    unlist()
}

#' Scrape IMDB foreign films page
#'
#' Loads HTML (live or cached), extracts movie elements, and applies CSS selectors
#' to harvest rank, title, year, runtime, rating, metascore, IMDB rating, votes, plot, country.
#'
#' @param html_file Path to IMDB HTML file (static snapshot or live download)
#'
#' @return A tibble with 10 columns and 25+ rows (one row per movie listed on page)
#'
scrape_imdb_movies <- function(html_file) {
  page <- read_html(html_file)

  # Extract all movie container elements
  movie_data <- page |>
    html_elements(".ipc-metadata-list-summary-item")

  # Define CSS selectors for each data field
  my_vars <- c("number_title", "year_run_rating_meta",
               "star_rating", "votes", "plot", "country")

  my_css <- c(
    ".ipc-title a h3",
    ".dli-title-metadata",
    ".ipc-rating-star--rating",
    ".ipc-rating-star--voteCount",
    ".title-description-plot-container .ipc-html-content-inner-div",
    ".ipc-bq .ipc-html-content-inner-div"
  )

  # Map over variables and selectors to build tibble
  movies_raw <- map2(my_vars, my_css,
    \(v_name, css) tibble(
      get_imdb_text(movie_data, css),
      .name_repair = ~v_name
    )
  ) |>
    list_cbind()

  movies_raw
}

#' Clean and tidy IMDB data
#'
#' Separates combined fields (e.g., rank and title), extracts numeric values,
#' handles missing data, and converts columns to appropriate types.
#'
#' @param movies_raw Raw tibble from scrape_imdb_movies()
#'
#' @return A tidy tibble with 10 columns: Rank, Title, Year, Run_time, MPAA_rating,
#'         Metascore, Star_rating, Votes, Plot, Country
#'
clean_imdb_movies <- function(movies_raw) {
  movies_raw |>
    # Separate rank from title
    separate_wider_delim(
      number_title,
      delim = ". ",
      names = c("Rank", "Title"),
      too_few = "align_start"
    ) |>
    mutate(Rank = parse_number(Rank)) |>

    # Extract year, runtime, MPAA rating, metascore from combined field
    mutate(
      year_run_rating_meta = str_squish(
        str_remove_all(year_run_rating_meta, "[\\r\\n\\t]")
      )
    ) |>
    mutate(
      Year = parse_number(str_extract(year_run_rating_meta, "^\\d{4}")),
      Run_time = str_extract(year_run_rating_meta, "(?<=\\d{4})\\d{1,2}h\\s*\\d{0,2}m"),
      MPAA_rating = str_extract(year_run_rating_meta,
        "R|PG-13|PG|G|Not Rated|Unrated"
      ),
      Metascore = parse_number(str_extract(year_run_rating_meta, "(?<=\\D)\\d{2}(?=Metascore)"))
      ) |>
    select(-year_run_rating_meta) |>

    # Clean ratings and votes
    mutate(
      Star_rating = parse_number(star_rating),
      Votes = votes |>
        str_remove_all("[^0-9K]") |>
        str_replace("K$", "000") |>
        parse_number(),
      Country = str_remove(country, "^From\\s+")
    ) |>
    select(-star_rating, -votes, -country) |>
    rename(Plot = plot) |>

    # Reorder columns
    select(Rank, Title, Year, Run_time, MPAA_rating, Metascore,
           Star_rating, Votes, Plot, Country)
}
