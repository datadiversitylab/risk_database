# A script to get the number of species predicted at different levels of target overall accuracy

library(tidyverse)
library(IUCNN)

#load best geo feature models and prediction features
load(file = "output/features_prediction_with_epiphytic.rda")
load(file = "output/label_train_detail.rda")
load(file = "output/label_train_broad.rda")
load(file = "output/features_with_epiphytic.rda")
selected_features <- features[,c(1:10)]
features_pred <- features_pred[,c(1:10)]

## nnclass
load("output/best_model_broad_nnclass_geo.rda")
nnclass_broad <- iucnn_train_model(selected_features,
                                   labels_train_broad,
                                   production_model = best_model_broad_class,
                                   path_to_output = "output/production/nnclassbroad")



load("output/best_model_detail_nnclass_geo.rda")
nnclass_detail <- iucnn_train_model(selected_features,
                                    labels_train_detail,
                                    production_model = best_model_detail_class,
                                    path_to_output = "output/production/nnclassdetail") 

## nnreg
load("output/best_model_broad_nnreg_with_dropout_geo.rda")
nnreg_broad<- iucnn_train_model(selected_features,
                                labels_train_broad,
                                production_model = best_model_broad,
                                path_to_output = "output/production/nnregbroad")

load("output/best_model_detail_nnreg_geo.rda")
nnreg_detail<- iucnn_train_model(selected_features,
                                 labels_train_detail,
                                 production_model = best_model_detail,
                                 path_to_output = "output/production/nnregdetail")

#Start loop for predictions
## predict
thrs <- c(0, seq(0.6, 0.95, by = 0.05))

out <- list()

for(i in 1:length(thrs)){
  print(paste(i, "/", length(thrs), sep = ""))
  sub_cb <- iucnn_predict_status(features_pred,
                          nnclass_broad,
                          target_acc = thrs[i])
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_class_broad_", thrs[i], ".pdf", sep = "" ))
  plot(sub_cb)
  dev.off()
  
  cb_out <- c(type = "nn-class",
              detail = "broad",
              table(sub_cb$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_cb$class_predictions)),
              spnum = sum(!is.na(sub_cb$class_predictions)),
              model = "IUC-NN class",
              scale = "detail")
  
  
  
  sub_cd <- iucnn_predict_status(features_pred,
                          nnclass_detail,
                          target_acc = thrs[i])
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_class_detailed_", thrs[i], ".pdf", sep = "" ))
  plot(sub_cd)
  dev.off()
  
  cd_out <- c(type = "nn-class",
              detail = "detailed",
              table(sub_cd$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_cd$class_predictions)),
              spnum = sum(!is.na(sub_cd$class_predictions)),
              model = "IUC-NN class",
              scale = "detail")
  
  sub_rb <- iucnn_predict_status(features_pred,
                          nnreg_broad,
                          target_acc = thrs[i])
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_reg_broad_", thrs[i], ".pdf", sep = "" ))
  plot(sub_rb)
  dev.off()
  
  rb_out <- c(type = "nn-reg",
              detail = "broad",
              table(sub_rb$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_rb$class_predictions)),
              spnum = sum(!is.na(sub_rb$class_predictions)),
              model = "IUC-NN class",
              scale = "detail")
  
  sub_rd <- iucnn_predict_status(features_pred,
                          nnreg_detail,
                          target_acc = thrs[i])
  
  pdf(paste("output/plots_predictions_accuracy_threshold/", "plot_reg_detailed_", thrs[i], ".pdf", sep = "" ))
  plot(sub_rd)
  dev.off()
  
  rd_out <- c(type = "nn-reg",
              detail = "detailed",
              table(sub_rd$class_predictions), 
              target_accuracy = thrs[i], 
              DD = sum(is.na(sub_rd$class_predictions)),
              spnum = sum(!is.na(sub_rd$class_predictions)),
              model = "IUC-NN class",
              scale = "detail")
  
  
  out[[i]] <- bind_rows(cb_out,
                        cd_out,
                        rb_out,
                        rd_out)
}

# write_to_disk
out <- bind_rows(out)
write_csv(out, "output/target_accuracy_vs_spnum_class_detail_nnreg_nnclass.csv")
