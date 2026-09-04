library(dplyr)

load("01-amphibians/data/raw/full_data/df_ml_v2")

amphibians_df <- df_ml %>% 
  filter(toupper(class) == "AMPHIBIA") 

train_test_data <- amphibians_df %>% 
  filter(category != "DD" & category != "Data Deficient")

prediction_dd_data <- amphibians_df %>% 
  filter(category == "DD" | category == "Data Deficient")

train_test_data <- train_test_data %>%
  mutate(threat_status = ifelse(category %in% c("CR", "EN", "VU"), 
                                "Threatened", "Not_Threatened"))

train_test_data$threat_status <- as.factor(train_test_data$threat_status)

cat("\n--- FILTERING SUMMARY ---\n")
cat("Total amphibians for model training:", nrow(train_test_data), "\n")
cat("Total Data Deficient amphibians for prediction:", nrow(prediction_dd_data), "\n")

saveRDS(train_test_data, "amphibians_train.rds")
saveRDS(prediction_dd_data, "amphibians_dd.rds")