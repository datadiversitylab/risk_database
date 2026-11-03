library(tidyverse)

detail <- read_csv("output/model_testing_results_detail.csv")
broad <- read_csv("output/model_testing_results_broad.csv")
# calculate overall accuracies
## detailed
sel <- detail %>% 
  select(features, model) %>% 
  distinct()

out <- list()

for(i in 1:nrow(sel)){
  sub <- detail %>%  filter(features == sel[i,]$features & model == sel[i,]$model)
  acc <- sum(diag(as.matrix(sub[, 1:5])) / sum(as.matrix(sub[, 1:5])))
  out_sub <- data.frame(features = sel$features[i],
                        model = sel$model[i],
                        accuracy = acc)
  out[[i]] <- out_sub
}
acc_detail <- bind_rows(out)

#broad
sel <- broad %>% 
  select(features, model) %>% 
  distinct()

out <- list()

for(i in 1:nrow(sel)){
  sub <- broad %>%  filter(features == sel[i,]$features & model == sel[i,]$model)
  acc <- sum(diag(as.matrix(sub[, 1:2])) / sum(as.matrix(sub[, 1:2])))
  out_sub <- data.frame(features = sel$features[i],
                        model = sel$model[i],
                        accuracy = acc)
  out[[i]] <- out_sub
}
acc_broad <- bind_rows(out)

# old paper accuracies
#broad
load("input/zizka2020_accuracies/table_cm_index_based_broad.rda")
broad <- broad %>% 
  filter(type == "absolute") %>% 
  filter(id == "full")


out <- list()
li <- unique(broad$method)
for(i in 1:length(li)){
  sub <- broad %>% filter(method == li[i])
  acc <- sum(diag(as.matrix(sub[, 4:5])) / sum(as.matrix(sub[, 4:5])))
  out_sub <- data.frame(features = "Geographic only",
                        model = li[i],
                        accuracy = acc)
  out[[i]] <- out_sub
}

acc_broad_index <- bind_rows(out)

#detail
load("input/zizka2020_accuracies/table_cm_index_based_detail.rda")
detail <-  detail %>% 
  filter(type == "absolute") %>% 
  filter(id == "full")

out <- list()
li <- unique(detail$method)

for(i in 1:length(li)){
  sub <- detail %>% filter(method == li[i])
  acc <- sum(diag(as.matrix(sub[, 4:7])) / sum(as.matrix(sub[, 4:7])))
  out_sub <- data.frame(features = "Geographic only",
                        model = li[i],
                        accuracy = acc)
  out[[i]] <- out_sub
}

acc_detail_index <- bind_rows(out)

# write to disk
acc <- bind_rows(acc_broad, acc_detail, acc_broad_index, acc_detail_index, .id = "scale")%>% 
  mutate(accuracy = accuracy * 100) %>% 
  mutate(scale = recode(scale, 
                        `1` = "Not Threatened v. Possibly Threatened (2 classes)",
                        `2` = "IUCN categories (4/5 classes)",
                        `3` = "Not Threatened v. Possibly Threatened (2 classes)",
                        `4` = "IUCN categories (4/5 classes)")) %>% 
  mutate(features = recode(features, 
                           all = "All",
                           geo = "Geographic only",
                           `geo+hf` = "Geographic and human footprint")) %>% 
  mutate(model = recode(model,
                        conr = "ConR",
                        spgc = "SPGC",
                        `bnn` = "bnn-class")) %>% 
  mutate(model = factor(.$model, 
                        levels = c("ConR",
                                   "rCAT",
                                   "SPGC",
                                   "cnn-class",
                                   "nn-reg",
                                   "bnn-class", 
                                   "nn-class")))

save(acc, file = "output/overall_accuracies.rda")
