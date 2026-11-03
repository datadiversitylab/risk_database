import csv, sys
import os,glob
import time
import argparse
import numpy as np
from numpy import *
import multiprocessing
import subprocess


lab_files = ["data/label_train_broad.txt", "data/label_train_detail.txt"]

run = 1

# geo = 1:10
# biome = 11:26
# bioclim = 27:36
# hfp = 37:44
# epiphytic = 45


models = ["-w 20 -f 0 1 2 3 4 5 6 7 8 ",
          "-w 20 -f 0 1 2 3 4 5 6 7 8 37 38 39 40 41 42 43 44 ",
          "-w 20 "]


rseed = 1234

def my_job(arg):
    [i, lab_file] = arg

    cmd = [
        r"C:\Users\Julia Dias\AppData\Local\Programs\Python\Python37\python.exe",
        r"scripts\orchid-bnn-retrain.py"
    ]

    cmd.extend(i.split())
    cmd.extend(["-r", str(rseed), "-l", lab_file])

    if run:
        subprocess.run(cmd)
    else:
        print(" ".join(cmd))
        



list_args = []
for i in models:
    for lab in lab_files:
        list_args.append([i,lab])
            



# print(list_args)

if __name__ == '__main__': 
    pool = multiprocessing.Pool(len(list_args))
    pool.map(my_job, list_args)
    pool.close()
