test_that("delineate_basin() returns an sf polygon", {
  skip_on_cran()
  skip_if_offline("aws.amazon.com")

  aoi <- system.file("extdata/aoi_example.shp", package = "HydroBasin")
  pp  <- system.file("extdata/pourpoint_WuMain.shp", package = "HydroBasin")

  ws <- delineate_basin(aoi,
                        pour_pt = pp,
                        out_dir  = tempdir(),
                        quiet    = TRUE)

  expect_s3_class(ws, "sf")
  expect_true(sf::st_geometry_type(ws, by_geometry = FALSE) == "POLYGON")
  expect_equal(nrow(ws), 1)
})
