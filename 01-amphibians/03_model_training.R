library(dplyr)
library(randomForest)

train_data <- readRDS("amphibians_train.rds")
important_features <- readRDS("amphibians_important_features.rds")

model_data <- train_data %>%
  select(all_of(important_features), threat_status)

model_data$threat_status <- as.factor(model_data$threat_status)

set.seed(123)
rf_model <- randomForest(
  threat_status ~ ., 
  data = model_data, 
  ntree = 500, 
  importance = TRUE
)

print(rf_model)

saveRDS(rf_model, "amphibians_rf_model.rds")