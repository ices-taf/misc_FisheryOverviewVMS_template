## Prepare plots/tables for report

## Before:
## After:

# libraries
#install_github("ices-tools-dev/sfdMaps")
#library(sfdMaps)
devtools::load_all("../../ices-tools-dev/sfdMaps/")
library(icesTAF)
library(dplyr)
library(glue)
library(jsonlite)

# make dir
mkdir("report")

# read in config
config <- read_json("config.json")

# load data
data("ices_ecoregions")
data("coastline")

# read in data
vms <- read.taf("data/fishing_activity.csv")
ecoregion_table <- read.taf("bootstrap/data/ecoregion_table.csv")

# get ecoregion shape
ecoregion_name <-
  ecoregion_table$Description[ecoregion_table$Key == config$ecoregion]
ecoregion <- ices_ecoregions[ices_ecoregions$Ecoregion == ecoregion_name,]


# fishing effort map text

label_1 <-
"Figure X Spatial distribution of average annual fishing effort
 (mW fishing hours) in the {ecoregion_name} during
 {config$year - 3}-{config$year}, by gear type. Fishing effort data are
 only shown for vessels >12 m having vessel monitoring systems (VMS)."

label_1 <- glue(gsub("\n", "", label_1))

# fishing effort map plot

# subset data
vms_sub <-
  vms %>%
  filter(Fishing_category_FO %in% names(config$effort_map))


mfrow <- layout(length(config$effort_map))
png("report/effort_maps.png",
    width = mfrow[2]*5.6 + 3, height = mfrow[1]*5.6,
    res = 400, units = "cm", pointsize = 10)

# plot effort data
plotPages(vms_sub$mw_fishinghours,
          vms_sub[c("lon", "lat")],
          vms_sub$Fishing_category_FO,
          ecoregion,
          glue("Average mW Fishing hours {config$year - 3}-{config$year}"),
          "mW Fishing hours",
          unlist(config$effort_map),
          breaks = c(0, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000))

dev.off()


plot(make_raster(vms_sub$mw_fishinghours, vms_sub[c("lon", "lat")], 0.05))

