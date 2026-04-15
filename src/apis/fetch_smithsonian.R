# Fetch and parse data from the Smithsonian Open Access API
# Handles pagination, nested JSON extraction, and credential management

library(httr2)
library(jsonlite)
library(tidyverse)
library(keyring)

#' Search the Smithsonian Open Access API
#'
#' @param req An httr2 request object pointing to the Smithsonian search endpoint
#' @param q Search query phrase (e.g., "artificial intelligence")
#' @param rows Number of rows per page (default 10, max 1000 for pagination stability)
#'
#' @return A tibble with extracted metadata: id, title, link, object_type, date, name, data_source
#'
smith_search <- function(req, q, rows = 10) {
  req |>
    req_url_query(
      api_key = keyring::key_get("API_KEY_DATA-GOV"),
      q = q,
      rows = rows
    ) |>
    req_perform() |>
    resp_body_json() |>
    purrr::pluck("response", "rows") |>
    tibble(resp_list = _) |>
    hoist(
      resp_list,
      id = "id",
      title = "title",
      content = "content"
    ) |>
    hoist(
      content,
      link = c("descriptiveNonRepeating", "record_link"),
      object_type = c("indexStructured", "object_type"),
      data_source = "data_source",
      unitCode = "unitCode",
      record_ID = "record_ID"
    )
}

#' Paginate through Smithsonian API results
#'
#' Uses httr2::req_perform_iterative() to handle offset-based pagination.
#' Respects the 1000 request/hour rate limit and 1000-row max per request.
#'
#' @param base_req An httr2 request object with query params already set (excluding start/rows)
#' @param q Search query
#' @param max_pages Maximum number of pages to fetch (each 1000 rows)
#'
#' @return A list of httr2 response objects (one per page)
#'
paginate_smithsonian <- function(base_req, q, max_pages = 5) {
  base_req |>
    req_url_query(
      start = 0,
      rows = 1000
    ) |>
    req_perform_iterative(
      next_req = \(resp, req) {
        current_start <- as.numeric(
          resp$request$url |>
            stringr::str_extract("(?<=start=)\\d+")
        )
        next_start <- current_start + 1000
        req |>
          req_url_query(
            start = next_start,
            api_key = keyring::key_get("API_KEY_DATA-GOV"),
            q = q,
            rows = 1000
          )
      },
      max_reqs = max_pages
    )
}

#' Convert paginated API responses to a single tibble
#'
#' Handles nested JSON structure: response$rows contains the records.
#' Each record's content field may have nested lists (object_type, etc.).
#'
#' @param response_list A list of httr2 response objects
#'
#' @return A tibble with flattened record metadata and unnested object types
#'
flatten_paginated_smithsonian <- function(response_list) {
  response_list |>
    purrr::map(\(el) {
      resp_body_json(el)$response$rows
    }) |>
    purrr::list_flatten() |>
    purrr::map(\(el) {
      purrr::map_if(el, is.list, list)
    }) |>
    purrr::map(\(el) {
      as_tibble(el)
    }) |>
    purrr::list_rbind() |>
    tidyr::unnest_wider(content, names_sep = "_")
}
