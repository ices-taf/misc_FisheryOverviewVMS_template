## Preprocess data, write TAF data tables

## Before:
## After:


# packages
#install_github("ices-tools-dev/sfdSAR")
devtools::load_all("../../ices-tools-dev/sfdSAR/")
library(icesTAF)
library(sfdSAR)
library(dplyr)

# make folder
mkdir("data")

# read in raw vms - NOTE ADD PRIVICY to dataset
vms <- read.taf("bootstrap/data/vms.csv")

# load data
data(gear_widths)
data(metier_lookup)

# join widths and lookup
aux_lookup <-
  gear_widths %>%
  right_join(metier_lookup, by = c("benthis_met" = "Benthis_metiers"))

# add aux data to vms
vms <-
  aux_lookup %>%
  right_join(vms, by = c("LE_MET_level6", "LE_MET_level6"))

vms$gearWidth_model <-
  predict_gear_width(vms$gear_model, vms$gear_coefficient, vms)

# do the fillin:
# select provided average gear width, then modelled gear with, then benthis
# average if no kw or aol supplied
vms$gearWidth_filled <-
  with(vms,
    ifelse(!is.na(avg_gearWidth), avg_gearWidth / 1000,
      ifelse(!is.na(gearWidth_model), gearWidth_model / 1000,
        gearWidth)
    ))

# calculate surface contact
vms$surface <-
  predict_surface_contact(vms$contact_model,
                          vms$fishing_hours,
                          vms$gearWidth_filled,
                          vms$ICES_avg_fishing_speed)

# compute summaries over groups - can we divide by area afterwards...?
output <-
  vms %>%
    mutate(
      mw_fishinghours = kw_fishinghours / 1000
    ) %>%
    group_by(c_square, Fishing_category_FO) %>%
    summarise(
      mw_fishinghours = sum(mw_fishinghours) / 4,
      surface_sar = sum(surface / area) / 4,
      subsurface_sar = sum(surface * subsurface_prop / area) / 400
    ) %>%
  ungroup %>%
  filter(!is.na(Fishing_category_FO)) %>%
  mutate(
    lat = sfdSAR::csquare_lat(c_square),
    lon = sfdSAR::csquare_lon(c_square)
  )

# write out data
write.taf(output, "data/fishing_activity.csv")
