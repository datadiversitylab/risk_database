library(IUCNN)
library(tidyverse)

# load data
load(file = "output/cnn_training_features.rda")
load(file = "output/cnn_labels.rda")
load(file = "output/cnn_labels_broad.rda")

trained_model_detailed = iucnn_cnn_train(cnn_training_features,
                                         cnn_labels,
                                         cv_fold=5,
                                         path_to_output = 'output/modeltest_cnnclass_detailed',
                                         overwrite = TRUE,
                                         dropout=0.1,
                                         optimize_for = "accuracy")


plot(trained_model_detailed)
summary(trained_model_detailed)
save(trained_model_detailed, file = "output/trained_model_detail_cnnclass.rda")

out <- data.frame(trained_model_detailed$confusion_matrix)
names(out) <- c("LC", "NT", "VU", "EN", "CR")
out$features <- "all"
out$model <- "cnn-class"
out$classes = c("LC", "NT", "VU", "EN", "CR")
write_csv(out, file = "output/model_testing_results_detail.csv", append = TRUE)

trained_model_broad = iucnn_cnn_train(cnn_training_features,
                                      cnn_labels_broad,
                                      cv_fold=5,
                                      path_to_output = 'output/modeltest_cnnclass_broad',
                                      overwrite = TRUE,
                                      dropout=0.1,
                                      optimize_for = "accuracy")

trained_model_broad$input_data$lookup.labels = c('Threatened', 'Not Threatened')
trained_model_broad$input_data$lookup.lab.num.z = c(0,1)

plot(trained_model_broad)
summary(trained_model_broad)
save(trained_model_broad, file = "output/trained_model_broad_cnnclass.rda")

# get CM and write to file 
out <- data.frame(trained_model_broad$confusion_matrix)
names(out) <- c("Threatened", "Not Threatened")
out$features <- "all"
out$model <- "cnn-class"
out$classes = c("Threatened", "Not Threatened")
write_csv(out, file = "output/model_testing_results_broad.csv", append = TRUE)