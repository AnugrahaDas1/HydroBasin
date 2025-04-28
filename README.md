
<!-- README.md is generated from README.Rmd. Run `devtools::build_readme()` after edits. -->

# HydroBasin <img src="man/figures/logo.png" align="right" height="120" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check](https://github.com/AnugrahaDas1/HydroBasin/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/AnugrahaDas1/HydroBasin/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/HydroBasin)](https://CRAN.R-project.org/package=HydroBasin)
<!-- badges: end -->

## Overview

`HydroBasin` is an R package that automates two labor-intensive
hydrology tasks:

1.  **Watershed delineation** from a study-area polygon or shapefile
    using WhiteboxTools via the *SAiVE* wrapper
2.  **Monthly water-balance/runoff estimation** from TerraClim climate
    grids (precipitation and actual evapotranspiration)

The package helps hydrologists, environmental scientists, and water
resource managers quickly analyze watershed characteristics and water
availability without extensive GIS preprocessing or complex climate data
handling.

Developed as the final project for the “Introduction to Programming”
course in the *Master of Earth Observation and Geoanalysis (EAGLE)*
program at the University of Würzburg.

------------------------------------------------------------------------

## Installation

### CRAN (coming soon)

``` r
install.packages("HydroBasin")
```

### Development version (GitHub)

``` r
# install.packages("devtools")
remotes::install_github("AnugrahaDas1/HydroBasin")
```

### Dependencies

HydroBasin relies on several key packages: - **SAiVE/WhiteboxTools**:
For terrain analysis and watershed delineation - **climateR**: For
accessing TerraClim climate data - **sf/terra**: For spatial data
handling - **ggplot2**: For visualization

These will be installed automatically when you install HydroBasin.

------------------------------------------------------------------------

## Quick start

``` r
library(HydroBasin)

# Path to demo AOI (area of interest) shipped with the package
shp <- system.file("extdata/aoi_example.shp", package = "HydroBasin")

# 1. Delineate the basin
# An interactive map will open allowing you to pick the outlet (pour point)
basin <- delineate_basin(shp)

# 2. Calculate monthly water balance & runoff for 2020
runoff <- calculate_runoff(basin,
                           start_date  = "2020-01-01",
                           end_date    = "2020-12-31",
                           return_plot = TRUE)

# Examine the results
head(runoff$data)  # Monthly water balance data
runoff$plot        # Visualize the time series
```

<details>

<summary>

First rows of the resulting tibble
</summary>

</details>

------------------------------------------------------------------------

## Key Functions

### `delineate_basin()`

``` r
delineate_basin(aoi,                   # sf polygon or path to shapefile
                out_dir = "basin_work", # output directory for intermediate files
                dem_zoom = 12,          # DEM resolution (12 ≈ 30m, 13 ≈ 10m)
                pour_pt = NULL,         # supply a point or pick interactively
                snap_dist = 500,        # distance (m) to snap pour point to stream
                quiet = TRUE)           # suppress processing messages
```

### `calculate_runoff()`

``` r
calculate_runoff(basin,                # sf polygon or path to basin boundary
                 start_date,           # yyyy-mm-dd start date
                 end_date,             # yyyy-mm-dd end date
                 ppt_var = "ppt",      # precipitation variable name
                 aet_var = "aet",      # actual evapotranspiration variable name
                 save_csv = NULL,      # optional path to save data as CSV
                 return_plot = FALSE,  # return a ggplot visualization
                 quiet = TRUE)         # suppress download messages
```

------------------------------------------------------------------------

## Detailed Documentation

- **Vignette** – Run `vignette("HydroBasin-workflow")` for a complete
  workflow example using the provided demo data.
- **Function reference** – <https://AnugrahaDas1.github.io/HydroBasin/>
  (pkgdown site, if enabled).
- **Help pages** – Access detailed documentation with `?delineate_basin`
  or `?calculate_runoff`

------------------------------------------------------------------------

## Use Cases

HydroBasin is designed for:

- **Rapid watershed delineation** without extensive GIS preprocessing
- **Water availability assessments** at monthly time scales
- **Hydrological research** requiring basin water balance components
- **Educational purposes** to demonstrate hydrological concepts
- **Initial scoping** of water resource projects

------------------------------------------------------------------------

## Example Workflow

``` r
# 1. Define an area of interest (or load your own shapefile)
aoi <- system.file("extdata/aoi_example.shp", package = "HydroBasin")

# 2. Delineate the watershed (interactive pour point selection)
basin <- delineate_basin(aoi, out_dir = "my_basin")

# 3. Save the basin boundary for future use
sf::st_write(basin, "my_watershed.shp")

# 4. Calculate monthly water balance for two years
runoff <- calculate_runoff(basin, 
                          start_date = "2020-01-01", 
                          end_date = "2021-12-31",
                          return_plot = TRUE,
                          save_csv = "watershed_runoff.csv")

# 5. Visualize the results
print(runoff$plot)

# 6. Analyze the data
annual_summary <- runoff$data %>%
  dplyr::group_by(year) %>%
  dplyr::summarize(
    annual_precip_m3 = sum(ppt_vol_m3),
    annual_aet_m3 = sum(aet_vol_m3),
    annual_runoff_m3 = sum(runoff_vol_m3)
  )
```

------------------------------------------------------------------------

## Citation

If you use **HydroBasin** in academic work, please cite:

> Das, A. (2025). *HydroBasin: Toolbox for Automated Basin Water-Balance
> Analysis* (v0.9.0). <https://github.com/AnugrahaDas1/HydroBasin>

------------------------------------------------------------------------

## Contributing / Issues

Bug reports and pull requests are welcome on [GitHub
Issues](https://github.com/AnugrahaDas1/HydroBasin/issues). Please
follow the tidyverse code style and write unit tests for new features.

### Future Development

- Support for additional climate data sources
- Integration with streamflow gauge data
- Enhanced visualization options
- Water balance model calibration tools
