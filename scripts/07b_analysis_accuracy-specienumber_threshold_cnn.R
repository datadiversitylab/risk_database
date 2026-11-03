# A script to get the number of species predicted at different levels of target overall accuracy

library(tidyverse)
library(IUCNN)

#load best geo feature models and prediction features
load(file = "output/cnn_training_features.rda")
load(file = "output/cnn_predict_features.rda")
load(file = "output/cnn_labels.rda")
load(file = "output/cnn_labels_broad.rda")

#CNN
load(file = "output/trained_model_broad_cnnclass.rda")
cnn_broad <- iucnn_cnn_train(cnn_training_features,
                             cnn_labels_broad,
                             path_to_output = "output/production/cnnbroad",
                             overwrite = TRUE,
                             production_model = trained_model_broad,
                             optimize_for = "accuracy")


load(file = "output/trained_model_detail_cnnclass.rda")
cnn_detail <- iucnn_cnn_train(cnn_training_features,
                             cnn_labels,
                             path_to_output = "output/production/cnndetail",
                             overwrite = TRUE,
                             production_model = trained_model_broad,
                             optimize_for = "accuracy")

thrs <- c(0, seq(0.6, 1, by = 0.1))

for(i in 1:length(thrs)){
  print(paste(i, "/", length(thrs), sep = ""))
  sub_cb <- iucnn_predict_status(cnn_predict_features,
                                 cnn_broad,
                                 target_acc = thrs[i], 
                                 dropout_reps = 30)
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_cnn_broad_", thrs[i], ".pdf", sep = "" ))
  plot(sub_cb)
  dev.off()
  
  cb_out <- c(type = "cnn-class",
              detail = "broad",
              table(sub_cb$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_cb$class_predictions)),
              spnum = sum(!is.na(sub_cb$class_predictions)),
              model = "cnn class",
              scale = "broad")
  
  
  
  sub_cd <- iucnn_predict_status(cnn_predict_features,
                                 cnn_detail,
                                 target_acc = thrs[i], 
                                 dropout_reps = 30)
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_cnn_detailed_", thrs[i], ".pdf", sep = "" ))
  plot(sub_cd)
  dev.off()
  
  cd_out <- c(type = "cnn-class",
              detail = "detailed",
              table(sub_cd$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_cd$class_predictions)),
              spnum = sum(!is.na(sub_cd$class_predictions)),
              model = "cnn class",
              scale = "detail")
  
  out <- bind_rows(cb_out,cd_out)
  
  # write to disk
  if(i == 1){
    write_csv(out, "output/target_accuracy_vs_spnum_class_detail_cnn.csv")
  }else{
    write_csv(out, "output/target_accuracy_vs_spnum_class_detail_cnn.csv", append = TRUE)
  }
}

