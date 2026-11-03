library(tidyverse)

#load data
inp <- list.files("input/class_error_testsets_results/", pattern = "rel_error")
dat <- lapply(paste("input/class_error_testsets_results/", inp, sep = ""), "read_delim",
              delim = " ", 
              col_names = FALSE)
nums <- read_csv("input/species_per_category_relative_error.csv") %>% 
  mutate(x = 1.6)  %>% 
  mutate(bf = factor(bf, levels = c(1, 0.66, 0.33, 0)))

# add identifiers
for(i in 1:length(dat)){
  dat[[i]]$bf <-  parse_number(inp[[i]])
  dat[[i]]$model <- gsub(".txt", "", str_split_fixed(inp[[i]], n = 7, pattern = "_")[,7])
}

dat <- bind_rows(dat) %>% 
  filter(model != "nn-class-balanced") %>%
  filter(model != "nn-reg-balanced") %>% 
  pivot_longer(contains("X"), values_to = "error", names_to = "category") %>% 
  mutate(category = recode(category, 
                           X1 = "LC",
                           X2 = "NT", 
                           X3 = "VU",
                           X4 = "EN",
                           X5 = "CR")) %>% 
  mutate(category = factor(category, 
                           levels = c("LC", "NT", "VU", "EN", "CR")))  %>% 
  mutate(bf = factor(bf, levels = c(1, 0.66, 0.33, 0)))

# plot
ggplot()+
  geom_vline(xintercept = 0, linetype = "dashed")+
  geom_boxplot(data = dat, aes(y = category, x = error, fill = category), size = 0.1, outlier.size = 0.9)+
  scale_fill_manual(values = c("#60C659",
                               "#CCE226",
                               "#F9E814",
                               "#FC7F3F",
                               "#D81E05"))+
  geom_text(data = nums,
            aes(y = category, x = x, label = n),
            adj = 1)+
  xlab("Relative error")+
  facet_grid(bf ~ model)+
  theme_bw()+
  theme(panel.grid.minor.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "bottom",
        legend.title = element_blank())

ggsave("output/figure_mean_error_categories.pdf", height = 10, width = 8)
