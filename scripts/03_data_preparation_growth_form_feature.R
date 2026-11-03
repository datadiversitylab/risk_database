library(tidyverse)
library(lcvplants)

# load data
load(file = "output/features_pred.rda")
load(file = "output/features.rda")
epi <- read_delim("input/EpiList Final revised.csv", delim = ";", guess_max = 100000)

# prepare epiphyte data
epi <- epi %>% 
  filter(Family == "Orchidaceae") %>% 
  select(species = Species, 
         author = `Author(s)`)


# Training features
## taxonomic join
features <- as.data.frame(features)
class(features) <- "data.frame"
class(epi) <- "data.frame"
epi[3836,]$species <- "Demosthenesia mandonii"
epi[16285,]$species <- "Pleurothallis elegantula"

dat <- lcvp_join(x = features, 
                 y = epi,
                 sp_columns = c("species", "species"),
                 type = "left")

## generate growth form feature
features <- left_join(features, dat %>%  select(species = Species.List.1, 
                                                epiphytic = Species.List.2)) %>% 
  mutate(epiphytic = ifelse(is.na(epiphytic), 0, 1))

# save to disk
save(features, 
     file = "output/features_with_epiphytic.rda")

write_delim(features, file = "output/features_training_with_epiphytic.txt", delim = "\t")
# Prediction features
## taxonomic join
features_pred <- as.data.frame(features_pred)
class(features_pred) <- "data.frame"

dat <- lcvp_join(x = features_pred, 
                 y = epi,
                 sp_columns = c("species", "species"),
                 type = "left")

## generate growth form feature
features_pred <- left_join(features_pred, dat %>%  select(species = Species.List.1, 
                                                          epiphytic = Species.List.2)) %>% 
  mutate(epiphytic = ifelse(is.na(epiphytic), 0, 1))

# Adapt the order of columns to the trainings features
features_pred <- features_pred[, names(features)]

# save to disk
save(features_pred, 
     file = "output/features_prediction_with_epiphytic.rda")

write_delim(features_pred, file = "output/features_prediction_with_epiphytic.txt", delim = "\t")
