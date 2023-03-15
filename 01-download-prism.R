library(tidyverse)
library(prism)

prism_set_dl_dir("data/prism/tmax")
get_prism_dailys(type = "tmax", minDate = "2004-01-01",
                 maxDate = "2022-12-31", keepZip=FALSE)

tmax_stack <- prism_stack(prism_archive_subset(
  "tmax",
  "daily",
  minDate = "2004-01-01",
  maxDate = "2022-12-31"
))

save(tmax_stack, file = "tmax_stack_data.RData")

prism_set_dl_dir("data/prism/tmin")
get_prism_dailys(type = "tmin", minDate = "2004-12-27",
                 maxDate = "2022-12-31", keepZip=FALSE)

tmin_stack <- prism_stack(prism_archive_subset(
  "tmin",
  "daily",
  minDate = "2004-01-01",
  maxDate = "2022-12-31"
))

save(tmin_stack, file = "tmin_stack_data.RData")

prism_set_dl_dir("data/prism/ppt")
get_prism_dailys(type = "ppt", minDate = "2004-01-01",
                 maxDate = "2022-12-31", keepZip=FALSE)

ppt_stack <- prism_stack(prism_archive_subset(
  "ppt",
  "daily",
  minDate = "2004-01-01",
  maxDate = "2022-12-31"
))

save(ppt_stack, file = "ppt_stack.RData")

