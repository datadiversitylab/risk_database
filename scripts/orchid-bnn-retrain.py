import sys
import argparse
import numpy as np
import numpy as np
from concurrent.futures import ProcessPoolExecutor
np.set_printoptions(suppress=True, precision=3)
import pandas as pd

# load BNN modules
import np_bnn as bn

# set random seed

p = argparse.ArgumentParser()
p.add_argument('-r', type=int, help='seed', default = 1234)
p.add_argument('-w', type=int, help='', default = [64], nargs="+")
p.add_argument('-f', type=int, help='', default = [], nargs="+")
# p.add_argument('-cv', type=int, help='', default = 0)
p.add_argument('-l', type=str, help='', default = 0)



args = p.parse_args()
rseed = args.r
# cross_validation_batch = args.cv

np.random.seed(rseed)

if len(args.f):
    feat_indx = args.f
else:
    feat_indx = None
print(feat_indx)

# load data (2 files: features and labels)
f = "data/features_training_with_epiphytic.txt"
l = args.l
w = args.w


try:
    no_features = len(feat_indx)
except:
    no_features = 0

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
                  testsize=0,
                  all_class_in_testset=1,
                  header=1, # input data has a header
                  feature_indx = feat_indx,
                  instance_id=0, # input data includes names of instances
                  from_file=False)






# set up model architecture and priors
prior = 1  # 0) uniform, 1) normal, 2) Cauchy, 3) Laplace
p_scale = 1  # std for Normal, scale parameter for Cauchy and Laplace, boundaries for Uniform
use_class_weight = 0  # set to 1 to use class weights for unbalanced classes
# get nodes list and initial weights from tensorflow model
n_nodes_list = w
activation_function = bn.ActFun(fun="genReLU", trainable=False, prm=np.zeros(len(n_nodes_list)))

# set up the BNN model
bnn_model = bn.npBNN(dat,
                     n_nodes=n_nodes_list,
                     use_class_weights=use_class_weight,
                     actFun=activation_function,
                     use_bias_node=1,
                     prior_f=prior,
                     p_scale=p_scale,
                     seed=rseed,
                     init_std=0.1)

# set up the MCMC environment
mcmc = bn.MCMC(bnn_model,
               update_f=[0.005, 0.025, 0.1],
               update_ws=[0.05, 0.05, 0.1],
               temperature=1,
               update_function=bn.UpdateNormal,
               n_iteration=50000000,
               sampling_f=1000,
               print_f=5000,
               n_post_samples=5000,
               likelihood_tempering=1)
               
print(mcmc._update_n)

# initialize output files
if "broad" in l:
    out_file_name = "bnnBIN_alldata_feat_%s" % (no_features)
else:
    out_file_name = "bnn_alldata_feat_%s" % (no_features)
logger = bn.postLogger(bnn_model, filename=out_file_name, log_all_weights=0)

# run MCMC
bn.run_mcmc(bnn_model, mcmc, logger)







