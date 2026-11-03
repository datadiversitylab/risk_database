# This is a script to prepare the example input data on orchids, from the supplementary data of this publication https://doi.org/10.1111/cobi.13616.
library(tidyverse)

in1 <- read_delim("input/1_main_iucn_full_clean_detailed_features_fullds.txt", delim = "\t", col_names = FALSE)
in2 <- read_delim("input/1_main_iucn_full_clean_detailed_labels_fullds.txt", delim = "\t", col_names = FALSE)
in3 <- read_delim("input/1_main_iucn_full_clean_detailed_speciesid_fullds.txt", delim = "\t", col_names = FALSE)
in4 <- read_delim("input/2_main_iucn_full_clean_broad_features_fullds.txt", delim = "\t", col_names = FALSE)
in5 <- read_delim("input/2_main_iucn_full_clean_broad_labels_fullds.txt", delim = "\t", col_names = FALSE)
in6 <- read_delim("input/2_main_iucn_full_clean_broad_speciesid_fullds.txt", delim = "\t", col_names = FALSE)

# check if the species ids are the same
sum(!in3$X1 %in% in6$X1)
sum(!in6$X1 %in% in3$X1)

# check if the features are the same
dim(in1)
dim(in4)
head(in1)
head(in4)

# training features
train_feat <- bind_cols(in3, in1)
names(train_feat)[1] <- "species"
write_csv(train_feat, "output/original_orchid_training_features.csv")

#training labels
#labels are: CR = "1", EN = "2", VU = "3", NT = "4", LC = "5"
train_lab <- bind_cols(in3, in2) %>%
  mutate(labels = recode(X1...2,
                        `1` = "CR",
                        `2` = "EN",
                        `3` = "VU",
                        `4` = "NT",
                        `5` = "LC")) %>%
  select(species = X1...1, labels)
write_csv(train_lab, file = "output/original_orchid_training_labels.csv")

# prediction features
in7 <- read_delim("input/prediction_full_dataset_features.txt", delim = "\t", col_names = FALSE)
in8 <- read_delim("input/prediction_full_dataset_speciesid.txt", delim = "\t", col_names = FALSE)

prediction_features <- in8 %>%
  rename(species = X1) %>%
  bind_cols(in7) %>%
  write_csv("output/original_orchid_prediction_features.csv")

# occurrences
load("input/orchids_filtered_occurrences.rda")

## training occurrences
training_occs <- orch_filt %>%
  filter(canonical_name %in% train_lab$species)

save(training_occs, file = "output/orchid_original_training_occurrences.rda")

prediction_occs <- orch_filt %>%
  filter(canonical_name %in% prediction_features$species)
  
save(prediction_occs, file = "output/orchid_original_prediction_occurrence.rda")


save(train_lab, file = "output/original_orchid_training_labels.rda")
