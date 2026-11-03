# A script to visualize the trade of between overall target accuracy and species evaluated

library(tidyverse)
library(readxl)
library(viridis)

# line plots
inp <- read_csv("input/target_accuracy_vs_spnum_class_detail_plus_bnn_cnn.csv") %>% 
  filter(target_accuracy != 0) %>% 
  mutate(detail = recode(detail, detailed = "IUCN categories",
                         broad = "Not Threatened v. Possibly Threatened"))

ggplot()+
  geom_line(data = inp, aes(x = target_accuracy, y = spnum, color = type))+
  geom_point(data = inp, aes(x = target_accuracy, y = spnum, color = type))+
  scale_color_viridis(discrete = 1, name = "Model", alpha = 1)+
  scale_y_continuous(breaks = c(0,2500, 5000, 7500, 10000, 12500))+
  ylab("Number of species evaluated")+
  xlab("Target accuracy threshold")+
  theme_bw()+
  theme(panel.grid = element_line(size = 0.1))+
  facet_grid(~detail)

ggsave(file = "output/figure_threshold_v_numberspecies.pdf", height = 5, width = 8)
