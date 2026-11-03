import sys, os
import numpy as np
import pandas as pd
from concurrent.futures import ProcessPoolExecutor
np.set_printoptions(suppress=True, precision=3)

# load BNN modules
import np_bnn as bn

feat_ind = [[0,1,2,3,4,5,6,7,8],
            [0,1,2,3,4,5,6,7,8,37,38,39,40,41,42,43,44],
             None]


model_list = ["_cv", "BIN_cv"]
model = 1
feat_list = ["feat_9","feat_17","feat_0"]
feat = 2

summary_res = []

conf_matrices = []
# loop over the 5 cross validations
for cv in range(5):
    rseed = 1234
    np.random.seed(rseed)
    # load data
    f = "./features_training_with_epiphytic.txt"
    if "BIN" in model_list[model]:
        l = "./label_train_broad.txt"
    else:
        l = "./label_train_detail.txt"
        
    f_dat = pd.read_table(f, delimiter="\t")
    l_dat = pd.read_table(l, delimiter="\t")
    is_NaN = f_dat.isnull()
    row_has_NaN = is_NaN.any(axis=1)
    # rows_with_NaN = f_dat[row_has_NaN]
    indx_nan = np.where(np.array(row_has_NaN) > 0)[0]
    f_dat = f_dat.drop(index=indx_nan)
    l_dat = l_dat.drop(index=indx_nan)
        
        
        
    dat = bn.get_data(f_dat.drop(columns='species'),
                      l_dat.drop(columns='species'),
                      seed=rseed,
                      testsize=0.2,  # 10% test set
                      all_class_in_testset=1,
                      header=1,  # input data has a header
                      cv=cv,
                      feature_indx=feat_ind[feat],
                      instance_id=0,
                      from_file=False)


    # load results
    pkl_file = "./orchid_training/bnn%s%s_%s_p1_h0_l20_s1_binf_%s.pkl" % (model_list[model], cv, feat_list[feat], rseed)

    # predict
    post_pr_test = bn.predictBNN(dat['test_data'],
                                  pickle_file=pkl_file,
                                  test_labels=dat['test_labels'],
                                  instance_id=dat['id_test_data'],
                                  fname=dat['file_name'],
                                  post_summary_mode=1,
                                  threshold=0.95)

    conf_matrices.append(post_pr_test['confusion_matrix'])

    # CALC TRADEOFFS
    res = post_pr_test['post_prob_predictions']
    labels=dat['test_labels']
    
    ppt = bn.get_posterior_threshold(pkl_file,
                                     target_acc=0.8,
                                     post_summary_mode=1,
                                     output_file=(pkl_file+"_thr.txt"))
    
    ppt = np.insert(ppt, 0,  post_pr_test['mean_accuracy'])
    summary_res.append(ppt)
    

summary_res = np.array(summary_res)
avg_threshold = np.mean(summary_res[:,1]) # 0.76

print("\nMean test acc.", np.round(np.mean(summary_res[:,0]),3),"sd:", np.round(np.std(summary_res[:,0]),3),"min", np.round(np.min(summary_res[:,0]),3),"max",np.round(np.max(summary_res[:,0]),3))
print("Selected threshold:",np.round(avg_threshold, 3))
print("Mean retained instances:",np.round(np.mean(summary_res[:,3]),3))


conf_matrices = np.array(conf_matrices)
# rm last column & last row
conf_matrices_s = conf_matrices[:,:-1,:-1] 
print("CM:\n", np.einsum('abc->bc',conf_matrices_s))



###########################################################################
#                             GET ACC THRESAHOLDS                         # 
###########################################################################
wd = './orchid_training'

targets = np.array([.6,.7,.8,.9,1])

# BINARY
th_list = []
for cv in range(5):
    f = 'bnnBIN_cv%s_feat_9_p1_h0_l20_s1_binf_1234.pkl_thr.txt' % cv
    tbl = np.loadtxt(os.path.join(wd, f), skiprows=1) 
    tbl = tbl[tbl[:,0] >= 0.5,:]
    th = []
    for i in targets:
        min_acc_diff = np.argmin(np.round(np.abs(tbl[:,1] - i),1))
        print(i, min_acc_diff)
        th.append(tbl[min_acc_diff,0])
    
    th_list.append(th)

th_list = np.array(th_list)
avg_thresholds = np.mean(th_list, 0)

tbl = pd.read_csv('./predictions/bin_geo_features.txt', delimiter='\t')
pred = np.array(tbl.iloc[:,1:3])

sampled = []
for i in range(len(avg_thresholds)):
    max_prob = np.max(pred,1)
    sampled.append([targets[i], len(max_prob[max_prob >= avg_thresholds[i]])])
    
print( np.array(sampled))


# 5-CLASS
th_list = []
for cv in range(5):
    f = 'bnn_cv%s_feat_9_p1_h0_l20_s1_binf_1234.pkl_thr.txt' % cv
    tbl = np.loadtxt(os.path.join(wd, f), skiprows=1) 
    th = []
    for i in targets:
        min_acc_diff = np.argmin(np.round(np.abs(tbl[:,1] - i),1))
        print(i, min_acc_diff)
        th.append(tbl[min_acc_diff,0])
    
    th_list.append(th)

th_list = np.array(th_list)
avg_thresholds = np.mean(th_list, 0)


tbl = pd.read_csv('./predictions/detail_geo_features.txt', delimiter='\t')
pred = np.array(tbl.iloc[:,1:3])

sampled = []
for i in range(len(avg_thresholds)):
    max_prob = np.max(pred,1)
    sampled.append([targets[i], len(max_prob[max_prob >= avg_thresholds[i]])])
    
print( np.array(sampled))




###########################################################################
#                               PREDICT FULL DATA                         # 
###########################################################################
model_list = ["", "BIN"]
model = 1

feat_ind = [[0,1,2,3,4,5,6,7,8],
            [0,1,2,3,4,5,6,7,8,37,38,39,40,41,42,43,44],
             None]


feat_list = ["feat_9","feat_17","feat_0"]
feat = 2

for feat in range(3):
    #combine MCMCs
    comb_file = "./all_data/bnn%s_alldata_%s_p1_h0_l20_s1_binf_1234.pkl" % (model_list[model], feat_list[feat])


    pred_file = "./features_prediction_with_epiphytic.txt"

    f_dat = pd.read_table(pred_file, delimiter="\t")
    is_NaN = f_dat.isnull()
    row_has_NaN = is_NaN.any(axis=1)
    indx_nan = np.where(np.array(row_has_NaN) > 0)[0]
    f_dat = f_dat.drop(index=indx_nan)
    
    
    
    dat = bn.get_data(f_dat.drop(columns='species'),
                      seed=1234,
                      testsize=0,
                      header=1,  # input data has a header
                      feature_indx=feat_ind[feat],
                      instance_id=0,
                      from_file=False)

    dat['id_data'] = np.array(f_dat['species'] )
    dat['label_dict'] = ["CR","EN","VU","NT","LC", "DD"]

    post_pr_test = bn.predictBNN(dat['data'],
                                      pickle_file=comb_file,
                                      instance_id=dat['id_data'],
                                      fname='',
                                      post_summary_mode=1)



prob_file = "./all_data/bnn_bnn%s_alldata_%s_p1_h0_l20_s1_binf_1234_pred_mean_pr.txt" % (model_list[model], feat_list[feat])
tmp = np.genfromtxt(prob_file, skip_header=False, dtype=str)
probs = tmp[:,1:].astype(float)
sp_names = tmp[:,0].astype(str)


# check how many lost data points with threshold
indx_supported = np.where(np.max(probs, axis=1) > avg_threshold)[0]
print(len(indx_supported)/len(sp_names))
print(len(indx_supported))

pred_status = np.argmax(probs[indx_supported], axis=1)
np.unique(pred_status, return_counts=True)



# load posterior samples and count species per class
post_est = np.load('./all_data/bnn_bnn%s_alldata_%s_p1_h0_l20_s1_binf_1234_pred_pr.npy' % (model_list[model], feat_list[feat]))
lab = ["\nCR","EN","VU","NT","LC", "DD"]

# load posterior samples and count species per class ONLY SUPPORTED SPECIES
supported_species = post_est[:,indx_supported,:]

counts_per_status = np.zeros((len(supported_species),6))
counter = 0
for i in supported_species:
    a = np.argmax(i, axis=1)
    u = np.unique(a, return_counts=True)
    counts_per_status[counter,u[0]] = u[1]
    counts_per_status[counter,5] = len(sp_names)-len(indx_supported)
    counter += 1
 
m = np.round(np.mean(counts_per_status, axis=0))
for i in range(6):
    print(lab[i], m[i], bn.calcHPD(counts_per_status[:, i], 0.95))


# get counts per classes whenever P(argmax) above threshold
counts_per_status = np.zeros((len(post_est),6)) # <- 6th class is for below threshold
counter = 0
for i in post_est:
    a = np.argmax(i, axis=1)
    m = np.max(i, axis=1)
    a[m < avg_threshold] = 5
    u = np.unique(a, return_counts=True)
    counts_per_status[counter,u[0]] = u[1]
    counter += 1
 
m = np.round(np.mean(counts_per_status, axis=0))
for i in range(6):
    print(lab[i], m[i], bn.calcHPD(counts_per_status[:, i], 0.95))



