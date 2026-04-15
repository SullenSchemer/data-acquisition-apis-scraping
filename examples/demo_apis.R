# Demonstration script: API modules in action
# This script shows typical usage patterns for Smithsonian and NASA APOD APIs

library(tidyverse)
library(httr2)
library(keyring)
library(here)

# Source the API modules
source(here::here("src/apis/fetch_smithsonian.R"))
source(here::here("src/apis/fetch_nasa_apod.R"))

# ============================================================================
# SMITHSONIAN OPEN ACCESS API EXAMPLE
# ============================================================================

cat("=== SMITHSONIAN SINGLE-PAGE QUERY ===\n")

# Create base request object
smith_req <- request("https://api.si.edu/openaccess/api/v1.0/search")

# Query for "artificial intelligence" (small page, 10 results)
smith_results <- smith_search(smith_req, q = "artificial intelligence", rows = 10)

cat("Columns in result:", ncol(smith_results), "\n")
cat("Rows in result:", nrow(smith_results), "\n")
glimpse(smith_results)

# Extract distinct object types (showing hoist/unnest benefit)
smith_results |>
  select(object_type) |>
  drop_na() |>
  distinct() |>
  pull()

# ============================================================================
# NASA APOD EXAMPLE
# ============================================================================

cat("\n=== NASA APOD QUERY ===\n")

# Fetch APOD data for a date range
apod_raw <- fetch_apod(
  start_date = "2023-01-01",
  end_date = "2023-01-10"  # Small sample for demo
)

cat("Records fetched:", length(apod_raw), "\n")

# Convert to tibble and clean
apod_df <- apod_to_tibble(apod_raw)
apod_clean <- clean_apod(apod_df)

glimpse(apod_clean)

# Quick analysis: media type distribution
cat("\nMedia types in sample:\n")
apod_clean |>
  count(media_type)

# ============================================================================
# OUTPUT SUMMARY
# ============================================================================

cat("\n=== SUMMARY ===\n")
cat("Smithsonian API: Demonstrated pagination setup, JSON hoist/unnest\n")
cat("NASA APOD: Demonstrated simple query, list-to-tibble conversion\n")
cat("Both use keyring for credential management (keys stored securely)\n")
