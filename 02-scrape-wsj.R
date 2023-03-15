library(rvest)

get_meta <- function(p) {

  n_times_try({
    if (is.character(p)) {
      p <- read_html(p)
    }

    article_headline <- p |>
      html_nodes(".WSJTheme--headlineText--He1ANr9C") |>
      html_text() |>
      unique()

    time <- p |>
      html_nodes(".WSJTheme--timestamp--22sfkNDv") |>
      html_text() |>
      head(length(article_headline))

    article_url <- p |>
      html_nodes("a") |>
      html_attr("href") |>
      keep(str_detect, "com/articles/") |>
      unique() |>
      head(length(article_headline)) # most popular news > unrelevant add

    tibble(time, article_headline, article_url)
  }, print_message = FALSE, sleep_times = c(1, 1, 5, 1, 1, 5), otherwise = {
    info("Downloading failed.", "warning")
    tibble(time = NA_character_, article_headline = NA_character_, article_url = NA_character_)
  })

}

get_meta_from_date <- function(d) {

  closeAllConnections()
  p <- read_html(paste0("https://www.wsj.com/news/archive/", format(d, "%Y/%m/%d")))

  n_page <- p |>
    html_nodes(".WSJTheme--pagepicker-total--Kl350I1l") |>
    html_text() |>
    parse_number()

  if (n_page > 1) {
    meta_pages <- paste0("https://www.wsj.com/news/archive/", format(d, "%Y/%m/%d"), "?page=", 2:n_page)

    bind_rows(
      get_meta(p),
      map(meta_pages, get_meta)
    ) |>
      mutate(date = d, .before = 1)
  } else {
    get_meta(p) |>
      mutate(date = d, .before = 1)
  }

}

get_text <- function(x) {
  text <- n_times_try({
    closeAllConnections()
    Sys.sleep(.2)
    read_html(x) %>%
      html_nodes("p") %>%
      html_text() %>%
      str_flatten(" ")
  },
  sleep_times = c(rep(c(3, 3, 15), 5), rep(180, 3), rep(15, 4)),
  otherwise = {
    info("Failed to download {x}")
    as.character(NA)
  }
  )

  tibble(article_url = x, text)
}

dir.create("wsj", showWarnings = FALSE)

downloaded_dates <- list.files("wsj") |>
  str_remove(".rds") |>
  as.Date()

month_to_download <- seq.Date(from = as.Date("1998-08-01"), to = as.Date("2023-02-01"), by = "1 month") |>
  discard(~ . %in% downloaded_dates) |>
  rev() |>
  as.Date()

walk(month_to_download, \(m) {
  m <<- m # for the info printing

  days_to_download <- seq.Date(from = m, to = m + months(1) - 1, by = "1 day")

  info("Collecting links for {format(m, '%Y-%m')}")

  meta_df <<- map_dfr(days_to_download, get_meta_from_date, .progress = TRUE)

  n_error <- meta_df |>
    filter(date != lag(date), date != lead(date)) |>
    nrow()

  if (n_error >= 3) {
    info("3 errors in a row!", "warning")
    print(meta_df, n = Inf)
    notification("You should change the VPN. 3 errors in a row!")
    stop()
  } else {
    info("Links collected succesfully", "ok")
  }

  info("Downloading {nrow(meta_df)} articles.", add_time = FALSE)

  text_df <- meta_df |>
    pull(article_url) |>
    map_dfr(get_text, .progress = TRUE)

  meta_df |>
    left_join(text_df, by = join_by(article_url)) |>
    write_rds(paste0("wsj/", m, ".rds"))

  info("Data saved for {format(m, '%Y-%m')}", "ok")

})

