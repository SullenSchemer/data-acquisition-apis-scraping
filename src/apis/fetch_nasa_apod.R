# Fetch data from NASA's Astronomy Picture of the Day API
# Handles date-range queries and credential management

library(httr2)
library(tidyverse)
library(keyring)

#' Fetch APOD data for a date range
#'
#' Queries NASA's Astronomy Picture of the Day API for multiple days.
#' Uses httr2 for HTTP request handling and keyring for API key storage.
#'
#' @param start_date Start date (YYYY-MM-DD format)
#' @param end_date End date (YYYY-MM-DD format)
#' @param thumbs Include thumbnail URLs (TRUE/FALSE)
#'
#' @return A list of APOD records (parsed JSON)
#'
fetch_apod <- function(start_date, end_date, thumbs = FALSE) {
  request("https://api.nasa.gov/planetary/apod") |>
    req_url_query(
      api_key = keyring::key_get("API_KEY_NASA"),
      start_date = start_date,
      end_date = end_date,
      thumbs = tolower(as.character(thumbs))
    ) |>
    req_perform() |>
    resp_body_json()
}

#' Convert APOD list to a tidy tibble
#'
#' Maps over the list of APOD records and creates a single tibble.
#' Handles optional fields (copyright, hdurl) that may not exist for all records.
#'
#' @param apod_list List of APOD records from fetch_apod()
#'
#' @return A tibble with columns: date, title, media_type, explanation, url, hdurl, copyright
#'
apod_to_tibble <- function(apod_list) {
  apod_list |>
    purrr::map_df(as_tibble)
}

#' Clean and prepare APOD data for analysis
#'
#' Converts date strings, computes text metrics, and selects columns of interest.
#'
#' @param apod_df Raw APOD tibble from apod_to_tibble()
#'
#' @return A tibble with date (Date), title, media_type (factor), text lengths, copyright flag, URLs
#'
clean_apod <- function(apod_df) {
  apod_df |>
    mutate(
      date = as.Date(date),
      title_length = nchar(title),
      explanation_length = nchar(explanation),
      media_type = as.factor(media_type),
      has_copyright = !is.na(copyright)
    ) |>
    select(date, title, media_type, title_length, explanation_length,
           has_copyright, url, hdurl, copyright)
}
