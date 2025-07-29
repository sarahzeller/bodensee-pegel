library(rvest)
library(dplyr)

url <- "https://www.hnd.bayern.de/pegel/iller_lech/lindau-20001001/tabelle?methode=seewasserstand&begin=01.01.2023&setdiskr=15"
lake_constance_zero <- 391.84


# read in old -------------------------------------------------------------

old_levels <- arrow::read_parquet("water_level.parquet")

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

dates_are_unique <- levels$date |> unique() |> length() == nrow(levels)
if(!dates_are_unique){stop("Dates are not unique")}

# export ------------------------------------------------------------------

write_parquet(levels, "water_level.parquet")
