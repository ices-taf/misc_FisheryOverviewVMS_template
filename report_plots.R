

library(icesTAF)
library(jsonlite)
library(glue)

# read in config
config <- read_json("bootstrap/initial/data/config.json")

# read in data
ecoregion_table <- read.taf("bootstrap/data/ecoregion_table/ecoregion_table.csv")

# get ecoregion shape
ecoregion_name <-
  ecoregion_table$Description[ecoregion_table$Key == config$ecoregion]

ecoregion_name <- gsub(" ", "_", ecoregion_name)

# run markdown
fname <-  glue("{ecoregion_name}_{config$year}_fisheries_maps.docx")
rmarkdown::render("report_plots.Rmd", output_file = fname)
cp(fname, "report", move = TRUE)

# save data
fname <-  glue("{ecoregion_name}_{config$year}_fisheries_maps.csv")
