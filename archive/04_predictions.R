library(dplyr)
library(randomForest)

rf_model <- readRDS("amphibians_rf_model.rds")
important_features <- readRDS("amphibians_important_features.rds")
prediction_data <- readRDS("amphibians_dd.rds")

pred_features <- prediction_data %>%
  select(all_of(important_features)) %>%
  mutate(across(everything(), ~ suppressWarnings(as.numeric(as.character(.)))))

predictions <- predict(rf_model, newdata = pred_features, type = "response")
probabilities <- predict(rf_model, newdata = pred_features, type = "prob")

final_predictions <- prediction_data %>%
  mutate(
    predicted_status = predictions,
    prob_threatened = probabilities[, "Threatened"]
  )

table(final_predictions$predicted_status)

saveRDS(final_predictions, "amphibians_final_predictions.rds")
write.csv(final_predictions, "amphibians_final_predictions.csv", row.names = FALSE)