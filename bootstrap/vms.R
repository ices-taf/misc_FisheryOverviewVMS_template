#' @Misc{vms,
#'   originator  = {},
#'   year        = {2019},
#'   title       = {},
#'   period      = {},
#'   source      = {script},
#'   data_policy = {vms}
#' }


# packages
library(RODBC)
library(icesTAF)
library(icesVocab)
library(glue)
library(jsonlite)
library(sp)
library(sfdMaps)
library(rgeos)
library(raster)

# settings
config <- read_json("../../initial/data/config.json")

# fetch vms ----
msg("downloading vms data from DB")

# get ecoregion shape to improve SQL query
layer <- tools::file_path_sans_ext(dir("../ICES_ecoregions/", pattern = "*.dbf"))
msg("reading ICES ecorgions layer: ", layer, "")
ices_ecoregions <- rgdal::readOGR("../ICES_ecoregions", layer)

ecoregion_name <-
  ecoregion_table$Description[ecoregion_table$Key == config$ecoregion]
ecoregion <- ices_ecoregions[ices_ecoregions$Ecoregion == ecoregion_name,]

# get ecoregion extent, and make a raster with 0.05 resolution
x <- as(extent(ecoregion), "SpatialPolygons")
r <- make_raster(rep(0, 4), x@polygons[[1]]@Polygons[[1]]@coords)

# get the coordinates and calculate the unique largest scale c-squares
coords <- coordinates(r)
lon <- coords[,"x"]
lat <- coords[,"y"]

csquare_quad <- ( 4 - (((2 *
                           floor(1 + (lon/200))) - 1) * ((2 * floor(1 + (lat/200))) +
                                                           1))    ) * 1000 + floor(abs(lat)/10) * 100 + floor(abs(lon)/10)

csquare_quad <- unique(csquare_quad)

# format into an sql clause
csquare_text <-
  paste0("substring(c_square, 1, 4) in ('", paste(csquare_quad, collapse = "', '"), "')")

# query the DB
dbConnection <- 'Driver={SQL Server};Server=SQL06;Database=VMS;Trusted_Connection=yes'
sqlq <- glue("select year, c_square, LE_MET_level6,
                     kw_fishinghours,
                     avg_oal, avg_kw, avg_gearWidth,
                     fishing_hours, ICES_avg_fishing_speed
              from {config$table}
              where (year > {config$year - 4}) and (year < {config$year + 1}) and {csquare_text} and country != 'esp'")
conn <- odbcDriverConnect(connection = dbConnection)
vms <- sqlQuery(conn, sqlq)
odbcClose(conn)

# do a finer subset by ecoregion ----
msg("subsetting vms data to ecoregion.")

# get centre coordinates of each unique c_square
loc <- data.frame(c_square = unique(vms$c_square))
loc$x <- sfdSAR::csquare_lon(loc$c_square)
loc$y <- sfdSAR::csquare_lat(loc$c_square)

# filter coursely on bounding box first
bb <- bbox(ecoregion)
loc <- loc[loc$x >= bb["x", "min"] & loc$x <= bb["x", "max"] &
             loc$y >= bb["y", "min"] & loc$y <= bb["y", "max"], ]

# now use a spatial method
coordinates(loc) <- ~ x + y
proj4string(loc) <- CRS("+init=epsg:4326")
id <- rgeos::gIntersects(loc, ecoregion, byid = TRUE)[1,]
loc <- loc[which(id),]

# subset vms data based on c_squares inside ecoregion
vms <- vms[vms$c_square %in% loc$c_square,]

# add area of c_square
vms$area <- sfdSAR::csquare_area(vms$c_square)

# save data
msg("saving vms data")
write.taf(vms)
