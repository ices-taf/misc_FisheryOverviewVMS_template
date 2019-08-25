#' @Misc{ecoregion_table,
#'   originator = {},
#'   year       = {2019},
#'   title      = {},
#'   period     = {},
#'   source     = {script},
#' }

# packages
library(icesTAF)
library(icesVocab)

# get Ecoregion list ----
msg("Reading ecosystem information from ices vocab.")

ecoregion_table <- icesVocab::getCodeList("Ecoregion")

ecoregion_table <- ecoregion_table[c("Key", "Description")]

ecoregion_table$Description <-
  gsub(" Ecoregion", "", ecoregion_table$Description)

# save data
write.taf(ecoregion_table)
