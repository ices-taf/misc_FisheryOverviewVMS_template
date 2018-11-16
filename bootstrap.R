
# packages
library(RODBC)
library(icesTAF)
library(icesVocab)
library(glue)
library(jsonlite)
library(sp)
library(sfdMaps)
library(rgeos)

# settings
config <- read_json("config.json")

# create directories
mkdir("bootstrap/data")

# get Ecoregion list ----

ecoregion_table <- icesVocab::getCodeList("Ecoregion")

ecoregion_table <- ecoregion_table[c("Key", "Description")]

ecoregion_table$Description <-
  gsub(" Ecoregion", "", ecoregion_table$Description)

# save data
write.taf(ecoregion_table, file = "bootstrap/data/ecoregion_table.csv")



# fetch vms ----

dbConnection <- 'Driver={SQL Server};Server=SQL06;Database=VMS;Trusted_Connection=yes'
sqlq <- glue("select year, c_square, LE_MET_level6,
                     kw_fishinghours,
                     avg_oal, avg_kw, avg_gearWidth,
                     fishing_hours, ICES_avg_fishing_speed
              from {config$table}
              where (year > {config$year - 4}) and (year < {config$year + 1})")
conn <- odbcDriverConnect(connection = dbConnection)
vms <- sqlQuery(conn, sqlq)
odbcClose(conn)

# subset vms by ecoregion ----

# get centre coordinates of each unique c_square
loc <- data.frame(c_square = unique(vms$c_square))
loc$x <- sfdSAR::csquare_lon(loc$c_square)
loc$y <- sfdSAR::csquare_lat(loc$c_square)

# get ecoregion
ecoregion_name <-
  ecoregion_table$Description[ecoregion_table$Key == config$ecoregion]
data("ices_ecoregions")
ecoregion <- ices_ecoregions[ices_ecoregions$Ecoregion == ecoregion_name,]

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
write.taf(vms, file = "bootstrap/data/vms.csv")
