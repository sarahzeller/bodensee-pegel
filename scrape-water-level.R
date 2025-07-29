library(rvest)
library(dplyr)
library(testthat)

url <- "https://www.hnd.bayern.de/pegel/iller_lech/lindau-20001001/tabelle?methode=seewasserstand&begin=01.01.2023&setdiskr=15"
lake_constance_zero <- 391.84


# read in old -------------------------------------------------------------

old_levels <- read.csv("water_level.csv") |> 
  mutate(date = as.POSIXct(date, format= "%Y-%m-%d %H:%M")) |> 
  filter(date < as.POSIXct("2025-07-29"))


# read in new -------------------------------------------------------------

new_levels <- read_html(url) |> 
  html_table(dec = ",") %>%
  `[[`(1) |> 
  setNames(c("date", "water_level_m_nhn")) |> 
  mutate(date = as.POSIXct(date, format = "%d.%m.%Y %H:%M")) |> 
  filter(!is.na(date)) |> 
  summarize(water_level_m_nhn = mean(water_level_m_nhn),
            .by = date) |> 
  mutate(water_level_cm_lake = (water_level_m_nhn - lake_constance_zero) * 100) |> 
  mutate(water_level_cm_lake = as.integer(water_level_cm_lake))


# merge -------------------------------------------------------------------

levels <- old_levels |> 
  bind_rows(new_levels) |> 
  distinct()

test_that("All dates only exist once",
          expect_equal(levels$date |> unique() |> length(), 
                       nrow(levels)))

# export ------------------------------------------------------------------

write.csv(levels,
          "water_level.csv",
          row.names = FALSE)
