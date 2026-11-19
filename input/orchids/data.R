library(IUCNN)
library(here)

#load example data 
data("training_occ") #geographic occurrences of species with IUCN assessment
data("training_labels")# the corresponding IUCN assessments
data("prediction_occ") #occurrences from Not Evaluated species to prdict

#export data from IUCNN
write.csv(training_occ, here("input", "orchids", "training_occ.csv"))
write.csv(training_labels, here("input", "orchids", "training_labels.csv"))
write.csv(prediction_occ, here("input", "orchids", "prediction_occ.csv"))
