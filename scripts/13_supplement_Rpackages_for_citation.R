# A script to extract the R-packages used during analyses for citation in the mansucript. 

library(knitr)

pkgs <- c("magrittr",
              "curl",
              "dplyr",
              "rCAT",
              "raster",
              "readr",
              "reticulate",
              "sf",
              "stats",
              "tidyr",
              "tidyselect",
              "checkmate",
              "sampbias",
              "covr",
              "testthat",
              "spelling",
              "knitr",
              "rmarkdown")

knitr::write_bib(pkgs, "output/Rpackages_for_citation.bib")
