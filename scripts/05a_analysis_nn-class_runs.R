library(tidyverse)
library(IUCNN)

# load data
load(file = "output/label_train_detail.rda")
load(file = "output/label_train_broad.rda")
load(file = "output/features_with_epiphytic.rda")

# select features
feats <- c("all", "geo+hf", "geo")

for(i in 3:length(feats)){
  
  if(feats[i] == "geo"){
    selected_features <- features[,c(1:10)]
    id <- "geo"
  }else if(feats[i] == "geo+hf"){
    selected_features <- features[,c(1:10, 39:46)]
    id <- "geo_hf"
  }else{
    selected_features <-  features
    id <- "all"
  }
  
  
  # 1. TRAINING___________________________________________________________________
  # 1.1 DETAILED LABELS________________
  # define logfile to store info of different runs
  logfile_detail_class = paste0("output/model_testing_detailed_nn_class_",id,".txt")
  model_testing_results_detail_class = iucnn_modeltest(selected_features,
                                                       labels_train_detail,
                                                       logfile_detail_class,
                                                       model_outpath = paste("output/modeltest_nnclass_detail_", id, sep = ""),
                                                       seed = 1234,
                                                       dropout_rate = c(0.,0.1,0.3),
                                                       n_layers = c('30','40_20','50_30_10'),
                                                       cv_fold = 5,
                                                       test_fraction = 0,
                                                       mode = 'nn-class',
                                                       init_logfile = TRUE,
                                                       recycle_settings = FALSE)
  
  #model_testing_results_detail_class = read.csv(logfile_detail_class,sep='\t')
  # evaluate best model
  best_model_detail_class = iucnn_best_model(model_testing_results_detail_class,
                                             criterion = "val_acc",
                                             require_dropout = TRUE)
  save(best_model_detail_class, file = paste("output/best_model_detail_nnclass_", id, ".rda", sep = ""))
  # get prediction accuracy and other stats
  summary(best_model_detail_class)
  # # train final model on all data
  # iucnn_results_detail_class = iucnn_train_model(selected_features,
  #                                                labels_train_detail,
  #                                                path_to_output = paste0('output/iucnn_orchid_nn_class_detail_',id),
  #                                                production_model = best_model_detail_class,
  #                                                overwrite = TRUE)
  # get CM and write to file 
  out <- data.frame(best_model_detail_class$confusion_matrix)
  names(out) <- c("LC", "NT", "VU", "EN", "CR")
  out$features <- feats[i]
  out$model <- "nn-class"
  out$classes = c("LC", "NT", "VU", "EN", "CR")
  
  if(i == 1){
    write_csv(out, file = "output/model_testing_results_detail.csv")
  }else{
    write_csv(out, file = "output/model_testing_results_detail.csv", append = TRUE)
  }
  
  
  # 1.2 BROAD LABELS________________
  # 1.2.1 CLASS________
  # define logfile to store info of different runs
  logfile_broad_class = paste0("output/model_testing_broad_nn_class_", id,".txt")
  model_testing_results_broad_class = iucnn_modeltest(selected_features,
                                                      labels_train_broad,
                                                      logfile_broad_class,
                                                      model_outpath = paste("output/modeltest_nnclass_broad_", id, sep = ""),
                                                      seed = 1234,
                                                      dropout_rate = c(0.,0.1,0.3),
                                                      n_layers = c('30','40_20','50_30_10'),
                                                      cv_fold = 5,
                                                      test_fraction = 0,
                                                      mode = 'nn-class',
                                                      init_logfile = TRUE,
                                                      recycle_settings = FALSE)
  
  #model_testing_results_broad_class = read.csv(logfile_broad_class,sep='\t')
  # evaluate best model
  best_model_broad_class = iucnn_best_model(model_testing_results_broad_class,
                                            criterion = "val_acc",
                                            require_dropout = TRUE)
  save(best_model_broad_class, file = paste("output/best_model_broad_nnclass_", id, ".rda", sep = ""))

  # get prediction accuracy and other stats
  summary(best_model_broad_class)
  # # train final model on all data
  # iucnn_results_broad_class = iucnn_train_model(selected_features,
  #                                               labels_train_broad,
  #                                               path_to_output = paste0('output/iucnn_orchid_nn_class_broad_',id),
  #                                               production_model = best_model_broad_class,
  #                                               overwrite = TRUE)
  
  # get CM and write to file 
  out <- data.frame(best_model_broad_class$confusion_matrix)
  names(out) <- c("Not_threatened", "Threatened")
  out$features <- feats[i]
  out$model <- "nn-class"
  out$classes = c("Not_threatened", "Threatened")
  
  if(i == 1){
    write_csv(out, file = "output/model_testing_results_broad.csv")
  }else{
    write_csv(out, file = "output/model_testing_results_broad.csv", append = TRUE)
  }
}
