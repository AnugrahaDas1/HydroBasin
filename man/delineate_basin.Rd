% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/delineate_basin.R
\name{delineate_basin}
\alias{delineate_basin}
\title{Delineate a watershed (basin) from an area-of-interest polygon}
\usage{
delineate_basin(
  aoi,
  out_dir = "basin_work",
  dem_zoom = 12,
  pour_pt = NULL,
  snap_dist = 500,
  quiet = TRUE
)
}
\arguments{
\item{aoi}{An \code{sf} polygon \strong{or} a filepath to a vector layer
(shp/geojson/etc.) representing the study area.}

\item{out_dir}{Directory where intermediate Whitebox/SAiVE files are
written.  Default \code{"basin_work"}.}

\item{dem_zoom}{AWS Terrain zoom level (12 ≈ 30 m, 13 ≈ 10 m).}

\item{pour_pt}{Optional pour-point.  Supply either an \code{sf} point,
a filepath, or \code{NULL} to choose interactively.}

\item{snap_dist}{Distance (m) within which the pour-point is snapped
to the nearest stream.}

\item{quiet}{Logical. Suppress WhiteboxTools console chatter.}
}
\value{
\code{sf} polygon of the watershed boundary.
}
\description{
Downloads a DEM that covers the AOI, derives stream networks with
\strong{SAiVE/WhiteboxTools}, lets you specify or interactively pick the outlet
(pour-point), and returns the basin boundary as an \code{sf} polygon.
}
\examples{
\dontrun{
ws <- delineate_basin("inst/extdata/aoi_example.shp",
                      out_dir = tempdir())
}
}
