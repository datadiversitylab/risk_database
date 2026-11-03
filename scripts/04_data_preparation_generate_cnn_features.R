library(IUCNN)
library(terra)

#load occurrence recods
load(file = "output/orchid_original_training_occurrences.rda")
load(file = "output/orchid_original_prediction_occurrence.rda")
load(file = "output/original_orchid_training_labels.rda")

# preaare raster for rasterization
# find the minimum latitude and longitude values for the extent of the raster
min_lon <- min(c(min(training_occs$decimallongitude), 
                 min(prediction_occs$decimallongitude)))
max_lon <- max(c(max(training_occ$decimallongitude), 
                 max(prediction_occs$decimallongitude)))
min_lat <- min(c(min(training_occs$decimallatitude), 
                 min(prediction_occs$decimallatitude)))
max_lat <- max(c(max(training_occs$decimallatitude), 
                 max(prediction_occs$decimallatitude)))
## set the coordinate reference system
ras <- rast(crs = "+proj=longlat +datum=WGS84")
## set raster extent
ext(ras) <- c(min_lon,
              max_lon, 
              min_lat, 
              max_lat)
## set raster resolution
res(ras) <- 1 # the resolution in CRS units, in this case degrees lat/lon

# get cnn features and labels
cnn_training_features <- iucnn_cnn_features(x = training_occs,
                                            y = ras,
                                            species = "canonical_name")

cnn_labels <- iucnn_prepare_labels(x = train_lab,
                                   y = cnn_training_features) # Training labels detailed
cnn_labels_broad <- iucnn_prepare_labels(x = train_lab,
                                   y = cnn_training_features,
                                   level = "broad") # Training labels broad

cnn_predict_features <- iucnn_cnn_features(x = prediction_occs, 
                                           y = ras,
                                           species = "canonical_name")

# save to disk
save(cnn_training_features,
     file = "output/cnn_training_features.rda")

save(cnn_predict_features,
     file = "output/cnn_predict_features.rda")

save(cnn_labels,
     file = "output/cnn_labels.rda")

save(cnn_labels_broad,
     file = "output/cnn_labels_broad.rda")
