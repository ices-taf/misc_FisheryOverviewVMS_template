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


# surface abrasion map plot

# sum up over all gears
vms_sub <-
  vms %>%
    mutate(
      area = csquare_area(c_square)
    ) %>%
    group_by(c_square, year) %>%
      summarise(
        surface_sar = sum(surface / area, na.rm = TRUE),
        subsurface_sar = sum(subsurface / area, na.rm = TRUE)
      ) %>%
    ungroup() %>%
    group_by(c_square) %>%
    summarise(
      surface_sar = mean(surface_sar, na.rm = TRUE),
      subsurface_sar = mean(subsurface_sar, na.rm = TRUE)
    ) %>%
  ungroup() %>%
    mutate(
      lat = sfdSAR::csquare_lat(c_square),
      lon = sfdSAR::csquare_lon(c_square)
    ) %>%
  filter(
    surface_sar > 0
  )

# make an all feild
vms_sub$all_gears <- "all"

png("report/surface_sar.png",
    width = 8.4, height = 8.4,
    res = 400, units = "cm", pointsize = 5)

plotPages(vms_sub$surface_sar,
          vms_sub[c("lon", "lat")],
          vms_sub$all_gears,
          ecoregion,
          glue("Average surface swept area ratio {config$year - 3}-{config$year}"),
          "Surface SweptArea Ratio",
          c("all" = "All gears"),
          breaks = c(0, 0.5, 1, 2, 5, 10, 20, 50, Inf),
          digits = 1)

dev.off()


vms_subsub <-
  vms_sub %>%
  filter(
    subsurface_sar > 0
  )

png("report/subsurface_sar.png",
    width = 8.4, height = 8.4,
    res = 400, units = "cm", pointsize = 5)

plotPages(vms_subsub$subsurface_sar,
          vms_subsub[c("lon", "lat")],
          vms_subsub$all_gears,
          ecoregion,
          glue("Average subsurface swept area ratio {config$year - 3}-{config$year}"),
          "Subsurface SweptArea Ratio",
          c("all" = "All gears"),
          breaks = c(0, 0.5, 1, 2, 5, 10, 20, 50, Inf) / 10,
          digits = 2)

dev.off()


# save a summary of the data
vms_sub_lat <-
  vms_sub %>%
    group_by(lat) %>%
    summarise(
      surface_sar = sum(surface_sar, na.rm = TRUE),
      subsurface_sar = sum(subsurface_sar, na.rm = TRUE)
    ) %>%
    ungroup

vms_sub_lon <-
  vms_sub %>%
    group_by(lon) %>%
    summarise(
      surface_sar = sum(surface_sar, na.rm = TRUE),
      subsurface_sar = sum(subsurface_sar, na.rm = TRUE)
    ) %>%
    ungroup

write.taf(vms_sub_lat, "report/surface_subsurface_sar_by_latitude.csv")
write.taf(vms_sub_lon, "report/surface_subsurface_sar_by_longitude.csv")

