library(tidyverse)
library(raster)

load("data/stacks/tmax_stack.RData")
load("data/stacks/tmin_stack.RData")
load("data/stacks/ppt_stack.RData")

population_raster <- raster("data/census/uspop10.tif")

pop_raster <- population_raster %>% 
    aggregate(5, fun = "sum") %>% 
    resample(tmax_stack, method = "ngb")

tmax_threshold <- 35
tmin_threshold <- 0
ppt_threshold <- 25.4


extremes_df <- tibble(
    tmax_rs = as.list(tmax_stack),
    tmin_rs = as.list(tmin_stack),
    ppt_rs = as.list(ppt_stack),
) %>% 
    mutate(
        tmax_value = map_dbl(tmax_rs, ~sum((values(.) > tmax_threshold) * values(pop_raster), na.rm = TRUE)),
        tmin_value = map_dbl(tmin_rs, ~sum((values(.) < tmin_threshold) * values(pop_raster), na.rm = TRUE)),
        ppt_value = map_dbl(ppt_rs, ~sum((values(.) > ppt_threshold) * values(pop_raster), na.rm = TRUE)),
        label_tmax = map_chr(tmax_rs, labels),
        date = str_extract(label_tmax,"20\\d\\d\\d\\d\\d\\d"),
        date = lubridate::ymd(date)
    ) %>% 
    dplyr::select(date, tmax_value, tmin_value, ppt_value) %>% 
    arrange(date)

save(extremes_df, file = "extreme.RData")
