library(tidyverse)
library(here)
#library(remotes)
#install_github("IUCNN/IUCNN")
library(IUCNN)
library(reticulate)

use_condaenv("r-reticulate", required = TRUE)

args <- commandArgs(trailingOnly = TRUE)

max_epochs_bnn <- if (length(args) > 0) {
  as.integer(args[1])
} else {
  1000000L
}

# Large files need more than the default 60 s
options(timeout = max(3600, getOption("timeout")))

# WWF terrestrial ecoregions
wwf_source <- here("input", "official")
wwf_temp <- file.path(tempdir(), "WWF_ecoregions", "official")

# Same source as IUCNN::iucnn_biome_features, the zip unpacks into official/
if (!file.exists(file.path(wwf_source, "wwf_terr_ecos.shp"))) {
  wwf_zip <- file.path(tempdir(), "wwf_ecoregions.zip")
  download.file(
    "https://files.worldwildlife.org/wwfcmsprod/files/Publication/file/6kcchn7e3u_official_teow.zip",
    destfile = wwf_zip,
    mode = "wb"
  )
  unzip(wwf_zip, exdir = here("input"))
  file.remove(wwf_zip)
}

dir.create(wwf_temp, recursive = TRUE, showWarnings = FALSE)

stopifnot(dir.exists(wwf_source))

stopifnot(all(file.copy(
  list.files(wwf_source, full.names = TRUE),
  wwf_temp,
  overwrite = TRUE
)))

stopifnot(file.exists(
  file.path(wwf_temp, "wwf_terr_ecos.shp")
))

# Human Footprint
footprint_source <- here("input", "human_footprint")
footprint_temp <- file.path(tempdir(), "landuse")

dir.create(footprint_temp, recursive = TRUE, showWarnings = FALSE)

# Same source as IUCNN::iucnn_footprint_features, geodata saves into tempdir()/landuse
footprint_names <- paste0("wildareas-v3-", c(1993, 2009), "-human-footprint_geo.tif")

if (!all(file.exists(file.path(footprint_source, footprint_names)))) {
  for (year in c(1993, 2009)) {
    stopifnot(!is.null(geodata::footprint(year = year, path = tempdir())))
  }
  dir.create(footprint_source, recursive = TRUE, showWarnings = FALSE)
  stopifnot(all(file.copy(
    file.path(footprint_temp, footprint_names),
    footprint_source,
    overwrite = TRUE
  )))
}

footprint_files <- list.files(
  footprint_source,
  pattern = "\\.tif$",
  full.names = TRUE
)

stopifnot(length(footprint_files) == 2)

stopifnot(all(file.copy(
  footprint_files,
  footprint_temp,
  overwrite = TRUE
)))

# Input folders with all three data files
required_files <- c("training_occ.csv", "training_labels.csv", "prediction_occ.csv")

input_dirs <- list.dirs(here("input"), recursive = FALSE, full.names = FALSE)

has_data <- vapply(
  input_dirs,
  function(d) all(file.exists(here("input", d, required_files))),
  logical(1)
)

folders <- input_dirs[has_data]

stopifnot(length(folders) > 0)

for (folder in folders) {
  
  message("Running ", folder)
  
  dir.create(here("output", folder), recursive = TRUE, showWarnings = FALSE)
  
  #Load data
  training_occ <- read.csv(here("input", folder, "training_occ.csv"))
  training_labels <- read.csv(here("input", folder, "training_labels.csv"))
  prediction_occ <- read.csv(here("input", folder, "prediction_occ.csv"))
  
  # 1. Feature and label preparation
  features <- iucnn_prepare_features(training_occ) # Training features
  labels_train <- iucnn_prepare_labels(x = training_labels,
                                       y = features) # Training labels
  features_predict <- iucnn_prepare_features(prediction_occ) # Prediction features
  
  # 2. Model training and prediction
  models <- c("nn-class", "nn-reg", "bnn-class")
  
  for (i in seq_along(models)) {
    
    model_type <- models[i]
    model_path <- here("output", folder, model_type)
    
    # Train model
    m1 <- iucnn_train_model(
      x = features,
      lab = labels_train,
      mode = model_type,
      path_to_output = model_path,
      max_epochs = if (model_type == "bnn-class") max_epochs_bnn else 1000,
      overwrite = FALSE
    )
    
    summary(m1)
    plot(m1)
    
    # 3. Prediction
    if (model_type == "nn-reg") {
      m1$mc_dropout <- FALSE
    }
    pred <- iucnn_predict_status(
      x = features_predict,
      model = m1
    )
    
    # 4. Save predictions
    
    species_names <- if (model_type == "bnn-class") {
      features_predict$species
    } else {
      pred$names
    }
    
    stopifnot(
      length(species_names) == length(pred$class_predictions)
    )
    
    results <- data.frame(
      species = species_names,
      predicted_status = pred$class_predictions
    )
    
    # Confidence (when available)
    probs <- NULL
    
    if (!is.null(pred$posterior_probs)) {
      probs <- as.matrix(pred$posterior_probs)
    } else if (!is.null(pred$mc_dropout_probs)) {
      probs <- as.matrix(pred$mc_dropout_probs)
    }
    
    results$confidence <- NA_real_
    
    if (!is.null(probs) &&
        nrow(probs) == nrow(results) &&
        ncol(probs) > 0 &&
        all(is.finite(probs)) &&
        all(probs >= 0 & probs <= 1)) {
      
      results$confidence <- apply(probs, 1, max)
    }
    
    # Save CSV
    write.csv(
      results,
      here("output", folder,
           paste0("predictions_", model_type, ".csv")),
      row.names = FALSE
    )
    
    # Save complete predictions
    saveRDS(
      pred,
      here("output", folder,
           paste0("predictions_", model_type, ".rds"))
    )
  }
}