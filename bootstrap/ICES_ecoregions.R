library(icesTAF)
taf.library(icesFO)

ecoregion <- icesFO::load_ecoregion("Greater North Sea")

sf::st_write(ecoregion, "ecoregion.csv", layer_options = "GEOMETRY=AS_WKT")
