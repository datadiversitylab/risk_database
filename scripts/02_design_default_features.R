library(tidyverse)
library(IUCNN)
library(lcvplants)

# load data
load(file = 'output/orchid_original_training_occurrences.rda')
load(file = 'output/orchid_original_prediction_occurrence.rda')
load(file = "output/original_orchid_training_labels.rda")

# Training features
occs <- training_occs %>% select(species = canonical_name, decimallongitude, decimallatitude)
features <-  iucnn_prepare_features(occs, 
                                    download_folder = "output/feature_extraction")
save(features, 
     file = "output/features.rda")

# Prediction features
occs <- prediction_occs %>% select(species = scientificname, 
                                   decimallongitude, 
                                   decimallatitude)
features_pred = iucnn_prepare_features(occs,
                                       download_folder = "output/feature_extraction")
save(features_pred, 
     file = "output/features_pred.rda")

#Training labels
## taxonomic matching features labels
labels_train_detail <- iucnn_prepare_labels(x = train_lab,
                                            y = features,
                                            level = 'detail')
labels_train_broad <- iucnn_prepare_labels(x = train_lab,
                                           y = features,
                                           level = 'broad')
save(labels_train_detail, 
     file = "output/label_train_detail.rda")
save(labels_train_broad, 
     file = "output/label_train_broad.rda")
write_delim(labels_train_detail$labels, 
            file = "output/label_train_detail.txt", delim = "\t")
write_delim(labels_train_broad$labels, 
            file = "output/label_train_broad.txt", delim = "\t")
