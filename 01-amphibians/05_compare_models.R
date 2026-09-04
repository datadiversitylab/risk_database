library(dplyr)
library(ggplot2)

my_preds <- read.csv("01-amphibians/data/processed/amphibians_final_predictions.csv") 
original_preds <- read.csv("01-amphibians/data/processed/dd_predictions.txt") 

original_amphibians <- original_preds %>%
  filter(binomial %in% my_preds$binomial)

comparison_df <- my_preds %>%
  inner_join(original_amphibians, by = "binomial", suffix = c("", "_original")) %>%
  mutate(diff_prob = prob_threatened - threatened)

summary_table <- comparison_df %>%
  summarise(
    n_species = n(),
    mean_diff = mean(diff_prob, na.rm = TRUE),
    sd_diff = sd(diff_prob, na.rm = TRUE),
    max_diff = max(abs(diff_prob), na.rm = TRUE)
  )

print(summary_table)

ggplot(comparison_df, aes(x = diff_prob)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  labs(
    title = "Comparison of Threat Probabilities (Amphibians)",
    x = "Difference (Mine - Original)",
    y = "Count"
  ) +
  theme_minimal()