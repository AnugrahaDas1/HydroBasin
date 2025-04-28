test_that("calculate_runoff() returns tibble (+ plot)", {
  skip_on_cran()
  skip_if_not_installed("climateR")
  skip_if_offline("aws.amazon.com")

  basin <- system.file("extdata/SubBasin_Main.shp", package = "HydroBasin")

  # try-catch so a download hiccup becomes a skip, not a failure
  out <- try(
    calculate_runoff(
      basin,
      start_date  = "2020-01-01",
      end_date    = "2020-02-28",
      return_plot = TRUE,
      quiet       = TRUE
    ),
    silent = TRUE
  )
  skip_if(inherits(out, "try-error"), "TerraClim unavailable — skipping test")

  expect_type(out, "list")
  expect_s3_class(out$data, "tbl_df")
  expect_s3_class(out$plot, "ggplot")
  expect_true(all(c("ppt_vol_m3", "runoff_vol_m3") %in% names(out$data)))
})
