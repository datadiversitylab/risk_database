library(tidyverse)
library(here)
library(IUCNN)

folder <- "05-orchids"

#Load data
training_occ <- read.csv(here("input", folder, "training_occ.csv"))
training_labels <- read.csv(here("input", folder, "training_labels.csv"))
prediction_occ <- read.csv(here("input", folder, "prediction_occ.csv"))

# 1. Feature and label preparation
features <- iucnn_prepare_features(training_occ) # Training features
labels_train <- iucnn_prepare_labels(x = training_labels,
                                     y = features) # Training labels
features_predict <- iucnn_prepare_features(prediction_occ) # Prediction features

# 2. Model training
m1 <- iucnn_train_model(x = features, lab = labels_train, path_to_output = "C:/risk_database/output/05-orchids/model_01")

summary(m1)
plot(m1)

# 3. Prediction
pred <- iucnn_predict_status(x = features_predict,
                     model = m1)

write.csv(pred, here("output", folder, "training_occ.csv"))
