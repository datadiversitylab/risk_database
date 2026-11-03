library(tidyverse)
library(IUCNN)

# load data
load(file = "output/label_train_detail.rda")
load(file = "output/label_train_broad.rda")
load(file = "output/features_with_epiphytic.rda")

# select features
feats <- c("all", "geo+hf", "geo")

for(i in 1:length(feats)){
  
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
  logfile_detail = paste0("output/model_testing_detailed_nn_reg_",id,".txt")
  model_testing_results_detail = iucnn_modeltest(selected_features,
                                                     labels_train_detail,
                                                     logfile_detail,
                                                     model_outpath = paste("output/modeltest_nnreg_detail_", id, sep = ""),
                                                     seed = 1234,
                                                     dropout_rate = c(0.,0.1,0.3),
                                                     n_layers = c('30','40_20','50_30_10'),
                                                     cv_fold = 5,
                                                     test_fraction = 0,
                                                     mode = 'nn-reg',
                                                     act_f_out = c('tanh','sigmoid'),
                                                     label_stretch_factor = c(0.8,1.0,1.2),
                                                     label_noise_factor = 0.0,
                                                     init_logfile = TRUE,
                                                     recycle_settings = FALSE)
  
  #model_testing_results_detail_ = read.csv(logfile_detail_,sep='\t')
  # evaluate best model
  best_model_detail = iucnn_best_model(model_testing_results_detail,
                                             criterion = "val_acc",
                                             require_dropout = TRUE)
  save(best_model_detail, file = paste("output/best_model_detail_nnreg_", id, ".rda", sep = ""))
  # get prediction accuracy and other stats
  summary(best_model_detail)
  # # train final model on all data
  # iucnn_results_detail = iucnn_train_model(selected_features,
  #                                                labels_train_detail,
  #                                                path_to_output = paste0('output/iucnn_orchid_nn_reg_detail_',id),
  #                                                production_model = best_model_detail,
  #                                                overwrite = TRUE)
  # get CM and write to file 
  out <- data.frame(best_model_detail$confusion_matrix)
  names(out) <- c("LC", "NT", "VU", "EN", "CR")
  out$features <- feats[i]
  out$model <- "nn-reg"
  out$classes = c("LC", "NT", "VU", "EN", "CR")
  
  write_csv(out, file = "output/model_testing_results_detail.csv", append = TRUE)

  
  # 1.2 BROAD LABELS________________
  # define logfile to store info of different runs
  logfile_broad = paste0("output/model_testing_broad_nn_reg_", id,".txt")
  model_testing_results_broad = iucnn_modeltest(selected_features,
                                                    labels_train_broad,
                                                    logfile_broad,
                                                    model_outpath = paste("output/modeltest_nnreg_broad_", id, sep = ""),
                                                    seed = 1234,
                                                    dropout_rate = c(0.1,0.3),
                                                    n_layers = c('30','40_20','50_30_10'),
                                                    cv_fold = 5,
                                                    test_fraction = 0,
                                                    mode = 'nn-reg',
                                                    act_f_out = c('tanh','sigmoid'),
                                                    label_stretch_factor = c(0.8,1.0,1.2),
                                                    label_noise_factor = 0.0,
                                                    init_logfile = TRUE,
                                                    recycle_settings = FALSE)

  #model_testing_results_broad = read.csv(logfile_broad,sep='\t')
  # evaluate best model
  best_model_broad = iucnn_best_model(model_testing_results_broad,
                                            criterion = "val_acc",
                                            require_dropout = TRUE)
  save(best_model_broad, file = paste("output/best_model_broad_nnreg_", id, ".rda", sep = ""))
  
  # get prediction accuracy and other stats
  summary(best_model_broad)
  # # train final model on all data
  # iucnn_results_broad = iucnn_train_model(selected_features,
  #                                               labels_train_broad,
  #                                               path_to_output = paste0('output/iucnn_orchid_nn_reg_broad_',id),
  #                                               production_model = best_model_broad,
  #                                               overwrite = TRUE)
  
  # get CM and write to file 
  out <- data.frame(best_model_broad$confusion_matrix)
  names(out) <- c("Not_threatened", "Threatened")
  out$features <- feats[i]
  out$model <- "nn-reg2"
  out$es = c("Not_threatened", "Threatened")
  
  write_csv(out, file = "output/model_testing_results_broad.csv", append = TRUE)
}