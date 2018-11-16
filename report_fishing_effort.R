## Prepare plots/tables for report

## Before:
## After:

# libraries
library(sfdMaps)
library(icesTAF)
library(dplyr)
library(glue)
library(jsonlite)
library(sp)
library(sfdSAR)

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

# fishing effort map plot

# format gear names
format_gear <- function(x) {
  x <- paste0(toupper(substring(x,1,1)), substring(x, 2))
  gsub("_", " ", x)
}
names(config$gears) <- sapply(names(config$gears), format_gear)
config$gears

# subset data
vms_sub <-
  vms %>%
  filter(Fishing_category_FO %in% names(config$gear))

# calculate annual averages
vms_sub <-
  vms_sub %>%
    group_by(c_square, Fishing_category_FO) %>%
    summarise(
      mw_fishinghours = mean(mw_fishinghours, na.rm = TRUE)
    ) %>%
  ungroup() %>%
    mutate(
      lat = sfdSAR::csquare_lat(c_square),
      lon = sfdSAR::csquare_lon(c_square)
    )


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
          unlist(config$gear),
          breaks = c(0, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000))

dev.off()
