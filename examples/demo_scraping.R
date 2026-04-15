# Demonstration script: Web scraping module in action
# Shows CSS selector strategy for IMDB foreign films list

library(tidyverse)
library(rvest)
library(here)

# Source the scraping module
source(here::here("src/scraping/scrape_imdb_foreign_films.R"))
# ============================================================================
# IMDB SCRAPING EXAMPLE
# ============================================================================

cat("=== IMDB TOP FOREIGN FILMS SCRAPING ===\n")

# For demo, use a cached HTML snapshot (if available in data_raw/)
html_path <- here::here("data_raw", "imdb_html_25-09-17.html")

if (file.exists(html_path)) {
  # Parse cached HTML
  movies_raw <- scrape_imdb_movies(html_path)

  cat("Raw extraction:\n")
  cat("Columns:", ncol(movies_raw), "\n")
  cat("Rows:", nrow(movies_raw), "\n")
  glimpse(movies_raw)

  # Clean and prepare for analysis
  movies_clean <- clean_imdb_movies(movies_raw)

  cat("\n=== CLEANED DATA ===\n")
  cat("Columns:", ncol(movies_clean), "\n")
  cat("Rows:", nrow(movies_clean), "\n")
  glimpse(movies_clean)

  # Show data samples
  cat("\nFirst 5 movies:\n")
  movies_clean |>
    select(Rank, Title, Year, Star_rating, Country) |>
    head(5) |>
    print()

  # Summary stats
  cat("\nRating statistics:\n")
  movies_clean |>
    summarize(
      Mean_Star_Rating = mean(Star_rating, na.rm = TRUE),
      Median_Metascore = median(Metascore, na.rm = TRUE),
      Max_Votes = max(Votes, na.rm = TRUE)
    ) |>
    print()

  # Show missing data pattern
  cat("\nMissing data:\n")
  movies_clean |>
    summarize(across(everything(), ~sum(is.na(.)))) |>
    print()

} else {
  cat("HTML file not found at", html_path, "\n")
  cat("To run this demo, provide a cached IMDB HTML snapshot in data_raw/\n")
}

cat("\n=== STRATEGY NOTES ===\n")
cat("1. CSS selectors target container elements (.ipc-metadata-list-summary-item)\n")
cat("2. get_imdb_text() maps selectors over movie list, handles missing fields\n")
cat("3. clean_imdb_movies() uses separate_wider_delim() and parse_number() for type conversion\n")
cat("4. Result is analysis-ready: numeric types, factored ratings, date parsing\n")
