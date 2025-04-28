#' Calculate monthly precipitation, evapotranspiration, and run-off volumes
#'
#' Downloads TerraClim monthly **ppt** (precipitation) and **aet**
#' (actual evapotranspiration) stacks for a watershed, converts them to
#' volumetric totals inside the basin, and (optionally) writes a CSV and/or
#' returns a ggplot.
#'
#' @param basin       `sf` polygon **or** filepath to a basin-boundary vector
#'                    (e.g. the output from `delineate_basin()`).
#' @param start_date  `"YYYY-MM-DD"` string (inclusive).
#' @param end_date    `"YYYY-MM-DD"` string (inclusive).
#' @param ppt_var     Name of the precipitation variable (TerraClim default `"ppt"`).
#' @param aet_var     Name of the evapotranspiration variable (default `"aet"`).
#' @param save_csv    Optional filepath.  If supplied, a CSV is written there.
#' @param return_plot Logical.  `TRUE` → return a `ggplot` object along with
#'                    the data frame.
#' @param quiet       Suppress verbose download messages.
#'
#' @return A `tibble` with one row per month and columns:
#'         `date`, `ppt_vol_m3`, `aet_vol_m3`, `runoff_vol_m3`,
#'         `year`, `month`.  If `return_plot = TRUE`, the result is a list
#'         containing `data` and `plot`.
#' @export
#' @examples
#' \dontrun{
#' ws <- system.file("extdata/basin_polygon.shp", package = "HydroBasin")
#' df <- calculate_runoff(ws, "2020-01-01", "2024-03-31")
#' }


calculate_runoff <- function(basin,
                             start_date,
                             end_date,
                             ppt_var     = "ppt",
                             aet_var     = "aet",
                             save_csv    = NULL,
                             return_plot = FALSE,
                             quiet       = TRUE) {

  # -- 1. Read / validate the basin ------------------------------------------
  if (inherits(basin, "character"))
    basin <- sf::st_read(basin, quiet = quiet)

  ## ---- 2. Download TerraClim monthly stacks --------------------------------
  ppt_list <- climateR::getTerraClim(
    AOI       = basin,
    varname   = ppt_var,
    startDate = start_date,
    endDate   = end_date,
    verbose   = !quiet
  )
  if (length(ppt_list) == 0)
    stop("TerraClim returned zero layers for precipitation; check dates or internet connection.", call. = FALSE)

  aet_list <- climateR::getTerraClim(
    AOI       = basin,
    varname   = aet_var,
    startDate = start_date,
    endDate   = end_date,
    verbose   = !quiet
  )
  if (length(aet_list) == 0)
    stop("TerraClim returned zero layers for AET; check dates or internet connection.", call. = FALSE)

  ppt_stack <- terra::rast(ppt_list)   # mm per month
  aet_stack <- terra::rast(aet_list)   # mm per month

  ## ---- 3. Re-project basin to match stack CRS ------------------------------
  basin_vect <- terra::vect(
    sf::st_transform(basin, terra::crs(ppt_stack))
  )

  ## ---- 4. Mask the rasters to the basin -----------------------------------
  ppt_stack <- terra::mask(ppt_stack, basin_vect)
  aet_stack <- terra::mask(aet_stack, basin_vect)

  ## ---- 5. Cell-area raster (m²) -------------------------------------------
  cell_area <- terra::cellSize(ppt_stack[[1]], unit = "m")

  ## ---- 6. Monthly volumes (m³) --------------------------------------------
  mm_to_m  <- 1/1000
  ppt_vol <- terra::global((ppt_stack * mm_to_m) * cell_area,
                           fun = "sum", na.rm = TRUE)[, 1]
  aet_vol <- terra::global((aet_stack * mm_to_m) * cell_area,
                           fun = "sum", na.rm = TRUE)[, 1]
  runoff_vol <- ppt_vol - aet_vol     # m³

  ## ---- 7. Robust dates from layer names ------------------------------------
  date_strings <- sub(
    pattern = "^.*?(\\d{4})[-_](\\d{2})[-_](\\d{2}).*$",
    replacement = "\\1-\\2-\\3",
    x = names(ppt_stack)
  )
  dates <- as.Date(date_strings)

  ## ---- 8. Assemble data-frame ----------------------------------------------
  vol_df <- dplyr::tibble(
    date          = dates,
    ppt_vol_m3    = ppt_vol,
    aet_vol_m3    = aet_vol,
    runoff_vol_m3 = runoff_vol
  ) |>
    dplyr::mutate(
      year  = as.integer(format(date, "%Y")),
      month = as.integer(format(date, "%m"))
    )

  ## ---- 9. Optional CSV ------------------------------------------------------
  if (!is.null(save_csv))
    readr::write_csv(vol_df, save_csv)

  ## ---- 10. Optional plot ----------------------------------------------------
  if (isTRUE(return_plot)) {
    plt <- ggplot2::ggplot(vol_df, ggplot2::aes(x = date)) +
      ggplot2::geom_line(ggplot2::aes(y = ppt_vol_m3 / 1e6,   colour = "PPT")) +
      ggplot2::geom_line(ggplot2::aes(y = aet_vol_m3 / 1e6,   colour = "AET")) +
      ggplot2::geom_line(ggplot2::aes(y = runoff_vol_m3 / 1e6, colour = "Runoff")) +
      ggplot2::labs(
        title = "Monthly Basin Water-Balance Volumes",
        x     = "Date",
        y     = expression("Volume (10"^6*" m"^3*")"),
        colour = NULL
      ) +
      ggplot2::scale_colour_manual(values = c("PPT" = "steelblue",
                                              "AET" = "darkgreen",
                                              "Runoff" = "firebrick")) +
      ggplot2::theme_minimal()

    return(list(data = vol_df, plot = plt))
  }

  return(vol_df)
}

