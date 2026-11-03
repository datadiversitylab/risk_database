library(tidyverse)
library(readxl)
library(wesanderson)
library(viridis)

load(file = "output/overall_accuracies.rda")

acc <- acc %>% 
  filter(!model %in% c("SPGC", "rCAT", "ConR"))

ggplot()+
  geom_bar(data = acc, aes(y = model,
                               x = accuracy, 
                               fill = features),
           position = "dodge", 
           stat = "identity")+
  scale_fill_viridis(discrete = TRUE, 
                     name = "Features included")+
  xlab("Overall accuracy")+
  theme_bw()+
  theme(legend.position = "bottom",
        axis.title.y = element_blank())+
  facet_grid(scale~.)

ggsave("output/supplementary_figure_feature_types.jpg", height = 10, width = 8)
