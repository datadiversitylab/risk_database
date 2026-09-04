library(dplyr)
library(Boruta)

train_data <- readRDS("amphibians_train.rds")

feature_data <- train_data %>% 
  select(32:ncol(train_data)) %>%
  mutate(across(everything(), ~ suppressWarnings(as.numeric(as.character(.))))) %>%
  mutate(threat_status = as.factor(train_data$threat_status))

feature_data <- feature_data %>%
  mutate(across(where(is.numeric), ~ ifelse(is.infinite(.), NA, .))) %>%
  select(where(~ !any(is.na(.)))) %>%
  select(where(~ n_distinct(.) > 1))

set.seed(123)
boruta_model <- Boruta(
  threat_status ~ ., 
  data = feature_data, 
  doTrace = 2,
  maxRuns = 100
)

selected_features <- getSelectedAttributes(boruta_model, withTentative = FALSE)

cat("Number of important features selected:", length(selected_features), "\n")

saveRDS(selected_features, "amphibians_important_features.rds")