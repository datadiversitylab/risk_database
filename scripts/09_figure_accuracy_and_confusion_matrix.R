# a script to visualize the overall accuracy of different nn models in comparison to the index based methods run in Zizka 2020 (https://doi.org/10.1111/cobi.13616.) 

library(tidyverse)
library(readxl)
library(viridis)
library(cowplot)

#load data
load(file = "output/overall_accuracies.rda")

plo_detail<- read_csv("output/model_testing_results_detail.csv") %>% 
  filter(features == "geo") %>% 
  pivot_longer(LC:CR, names_to = "reference_class",
               values_to = "value") %>%
  group_by(classes, model) %>% 
  mutate(percent = value / sum(value) * 100) %>% 
  ungroup() %>% 
  mutate(classes = factor(.$classes, 
                          levels = rev(c("LC", "NT", "VU", "EN", "CR"))))%>% 
  mutate(reference_class = factor(.$reference_class, 
                          levels = c("LC", "NT", "VU", "EN", "CR"))) %>% 
  mutate(model = factor(.$model,
                        levels = c("nn-class","bnn-class", "nn-reg", "cnn-class")))

plo_broad <- read_csv("output/model_testing_results_broad.csv")%>% 
  filter(features == "geo") %>% 
  pivot_longer(Not_threatened:Threatened, names_to = "reference_class",
               values_to = "value") %>%
  mutate(classes = recode(classes,
                          Not_threatened = "Not\nThreatened",
                          Threatened = "Possibly\nThreatened"))%>%
  mutate(reference_class = recode(reference_class,
                          Not_threatened = "Not Threatened",
                          Threatened = "Possibly Threatened")) %>% 
  group_by(classes, model) %>% 
  mutate(percent = value / sum(value) * 100) %>% 
  ungroup() %>% 
  mutate(classes = factor(.$classes, 
                          levels = rev(c("Not\nThreatened", "Possibly\nThreatened"))))%>% 
  mutate(reference_class = factor(.$reference_class, 
                                  levels = c("Not Threatened", "Possibly Threatened"))) %>% 
  mutate(model = factor(.$model,
                        levels = c("nn-class","bnn-class", "nn-reg", "cnn-class")))

# Accuracies
plo <- acc %>% filter(features == "Geographic only" )

fig_a <- ggplot()+
  geom_bar(data = plo, aes(x = model, y = accuracy , fill = model), stat = "identity", color = "black")+
  scale_fill_brewer(palette = "Set2")+
  ylab("Accuracy [%]")+
  ylim(0,85)+
  theme_bw()+
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_text(size = 8),
    legend.position = "none"
  )+
  facet_wrap(.~scale)
  
# confusion matrices
fig_b <- ggplot()+
  geom_tile(data = plo_detail, 
            aes(y = classes, 
                x = reference_class, 
                fill = percent))+
  scale_fill_viridis(name = "Per class\npercentage")+
  geom_text(data = plo_detail, aes(y = classes,
                                   x = reference_class, 
                                   label = value))+#paste(value, "/", percent, "%", sep = "")))+
  theme_bw()+
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_text(angle = 90, hjust = 0.5, vjust = 0)
  )+
  facet_wrap(model~., ncol = 2)

fig_c <- ggplot()+
  geom_tile(data = plo_broad, 
            aes(y = classes, 
                x = reference_class, 
                fill = percent))+
  scale_fill_viridis(name = "Per class\npercentage")+
  geom_text(data = plo_broad, aes(y = classes,
                                   x = reference_class, 
                                   label = value))+
  theme_bw()+
  theme(
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_text(angle = 90, hjust = 0.5, vjust = 0)
  )+
  facet_wrap(model~., ncol = 2)


figure <- plot_grid(fig_a, 
                    fig_b, 
                    fig_c,
                    labels = c('A', 'B', 'C'),
                    ncol = 1, 
                    rel_heights = c(1, 2, 2))

ggsave(figure, file = "output/figure_results_empirical.pdf", height = 10, width = 8)
