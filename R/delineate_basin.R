#' Delineate a watershed (basin) from an area-of-interest polygon
#'
#' Downloads a DEM that covers the AOI, derives stream networks with
#' **SAiVE/WhiteboxTools**, lets you specify or interactively pick the outlet
#' (pour-point), and returns the basin boundary as an `sf` polygon.
#'
#' @param aoi      An `sf` polygon **or** a filepath to a vector layer
#'                 (shp/geojson/etc.) representing the study area.
#' @param out_dir  Directory where intermediate Whitebox/SAiVE files are
#'                 written.  Default `"basin_work"`.
#' @param dem_zoom AWS Terrain zoom level (12 ≈ 30 m, 13 ≈ 10 m).
#' @param pour_pt  Optional pour-point.  Supply either an `sf` point,
#'                 a filepath, or `NULL` to choose interactively.
#' @param snap_dist Distance (m) within which the pour-point is snapped
#'                  to the nearest stream.
#' @param quiet     Logical. Suppress WhiteboxTools console chatter.
#' @return `sf` polygon of the watershed boundary.
#' @export
#' @examples
#' \dontrun{
#' ws <- delineate_basin("inst/extdata/aoi_example.shp",
#'                       out_dir = tempdir())
#' }
delineate_basin <- function(aoi,
                            out_dir   = "basin_work",
                            dem_zoom  = 12,
                            pour_pt   = NULL,
                            snap_dist = 500,
                            quiet     = TRUE) {

  # --- 1. Read AOI ----------------------------------------------------------
  if (inherits(aoi, "character")) aoi <- sf::st_read(aoi, quiet = quiet)

  ## ---- create working directory -------------------------------------------
  out_dir <- fs::path_abs(out_dir)          # full path for safety
  fs::dir_create(out_dir)

  ## ---- 2. Download DEM -----------------------------------------------------
  dem_path <- fs::path(out_dir, "dem.tif")

  if (!fs::file_exists(dem_path)) {
    dem_raw <- elevatr::get_elev_raster(
      locations = aoi,
      z         = dem_zoom,
      src       = "aws"
    )
    terra::writeRaster(terra::rast(dem_raw),
                       dem_path,
                       overwrite = TRUE)
  }

  ## ---- 3. Run SAiVE::drainageBasins() --------------------------------------
  ## All intermediate files will live directly in `out_dir`
  saive_out <- SAiVE::drainageBasins(
    DEM         = dem_path,
    streams     = NULL,
    breach_dist = 10000,
    threshold   = 1000,
    overwrite   = TRUE,
    save_path   = out_dir,           # <-- write straight into work dir
    snap        = "nearest",
    snap_dist   = snap_dist,
    burn_dist   = 10,
    n.cores     = max(1L, parallel::detectCores() - 1L),
    silent_wbt  = quiet
  )

  ## ---- 4. Locate key outputs ----------------------------------------------
  streams_rast <- fs::path(out_dir, "streams_derived.tif")
  d8_pointer   <- fs::path(out_dir, "D8pointer.tif")

  if (!fs::file_exists(streams_rast) || !fs::file_exists(d8_pointer)) {
    stop("Expected SAiVE outputs not found in ", out_dir, call. = FALSE)
  }

  ## ---- 5. Raster → vector streams (for the interactive map) ---------------
  streams_vec <- fs::path(out_dir, "stream_network.shp")
  whitebox::wbt_raster_streams_to_vector(
    streams = streams_rast,
    d8_pntr = d8_pointer,
    output  = streams_vec,
    verbose = !quiet
  )
  streams_sf <- sf::st_read(streams_vec, quiet = TRUE)

  dem_crs <- terra::crs(terra::rast(dem_path))   # proj string of the DEM
  sf::st_crs(streams_sf) <- dem_crs

  ## ---- 6. Prepare / obtain the pour-point ----------------------------------
  #> helper to persist an sf point layer on disk  -----------------------------
  write_pp <- function(pt, fname) {
    suppressWarnings(                  # hush harmless field-name notes
      sf::st_write(
        pt,
        dsn          = fname,
        delete_dsn   = TRUE,           # overwrite if it exists
        quiet        = TRUE
      )
    )
  }

  pp_path <- fs::path(out_dir, "pour_point.shp")

  if (is.null(pour_pt)) {
    # ---- interactive mode ---------------------------------------------------
    # make sure a base map is present
    mapview::mapviewOptions(
      basemaps = c("OpenStreetMap", "CartoDB.Positron")
    )

    m <- mapview::mapview(
      streams_sf,
      layer.name = "Streams",
      homebutton = FALSE
    )

    # user drops exactly ONE point
    pour_pt <- mapedit::drawFeatures(
      m,
      markers     = TRUE,   # only the point tool is enabled
      polylines   = FALSE,
      polygons    = FALSE,
      rectangles  = FALSE,
      circles     = FALSE
    )
  } else if (inherits(pour_pt, "character")) {
    # treat character input as a path on disk
    pour_pt <- sf::st_read(pour_pt, quiet = quiet)

    if (is.na(sf::st_crs(pour_pt))) {
      sf::st_crs(pour_pt) <- sf::st_crs(streams_sf)   # just set it
    } else if (sf::st_crs(pour_pt) != sf::st_crs(streams_sf)) {
      pour_pt <- sf::st_transform(pour_pt, sf::st_crs(streams_sf))
    }
  }
  # (if pour_pt is already an sf object, we do nothing)

  write_pp(pour_pt, pp_path)

  ## ---- 7. Watershed raster --------------------------------------------------
  ws_r_path <- fs::path(out_dir, "watershed.tif")
  whitebox::wbt_watershed(
    d8_pntr  = d8_pointer,
    pour_pts = pp_path,
    output   = ws_r_path,
    verbose  = !quiet
  )
  ws_r <- terra::rast(ws_r_path)

  ## ---- 8. Raster → dissolved polygon & return ------------------------------
  ws_poly <- terra::as.polygons(ws_r, dissolve = TRUE)
  terra::crs(ws_poly) <- terra::crs(ws_r)

  return(sf::st_as_sf(ws_poly))
}
