

taf.library("icesVMS")

vms_effort <- icesVMS::get_effort_map("Greater North Sea")

# convert to sf
vms_effort$wkt <- sf::st_as_sfc(vms_effort$wkt)
vms_effort <- sf::st_sf(vms_effort, sf_column_name = "wkt", crs = 4326)

sf::st_write(vms_effort, "vms_effort.csv", layer_options = "GEOMETRY=AS_WKT")
