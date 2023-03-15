req_dates <- seq.Date(from = as.Date("2004-01-01"),  by = "8 month", length.out = 29) |> # 8 month are allowed for daily frequency
  (\(x) paste(x, lead(x))) () |>
  str_replace("NA", as.character(Sys.Date()))

done <- list.files("gtrend") |>
  str_remove("[.]rds") # save continuously

dir.create("gtrend", showWarnings = FALSE)

n_error <- 0

for (ticker in tickers) {
  message("Download: ", crayon::blue(ticker))

  out <- tibble(time = as.Date("2004-01-01"), ticker, gtrend_hits = NA_character_)

  tryCatch({
    out <- gtrends(ticker, time = "2004-01-01 2023-01-01") |>
      pluck(1) |>
      tibble() |>
      transmute(
        time = ymd(date),
        ticker = keyword,
        gtrend_hits = as.character(hits)
      )

    n_error <<- 0
  }, error = \(e) {
    n_error <<- n_error + 1

    if (n_error > 5) {
      tryCatch({
        gtrends("APPL") # check whether connection is fine
      }, error = \(e) {
        Sys.sleep(20)
        granatlib::notification("You should change the VPN.", sound = TRUE)

        which(ticker == tickers) |>
          (\(x) paste0("gtrend/", tickers[(x - 4):(x - 1)], ".rds")) () |>
          walk(unlink)

        stop("You should change the VPN.", crayon::magenta("    (", Sys.time(), ")"))

      })
      n_error <<- 0
    }

  })

  write_rds(out, paste0("gtrend/", ticker, ".rds"))
}

gtrends_df <- list.files("gtrend", full.names = TRUE) |>
  map_dfr(read_rds)

pin_write(.board, gtrends_df, "gtrends_df")
