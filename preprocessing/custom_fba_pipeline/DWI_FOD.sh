#!/bin/bash

#### This script calculates fods and normalises these. 
#### This should be done in HPC environment (preferred Myriad)
#### Script to be called with parameters like: 
#### $ ./DWI_Preprocess.sh <subject id> <home directory>
#### Author: A. Zarkali
#### Date last update/checked: 10/01/2025
#### MRTRIX version 3.0.4

#### Parameters
ID=$1 # the subject you want to process
home_dir=$2 # the directory where data is stored for example "home/skgtaza/Scratch/SESSION3"
tar_AP="S4"
tar_PA="S6"

subject_path=$home_dir/${ID}/
# Move to directory
## Run with ${ID} parameter as previously
ID=$1
home_dir=$2
subject_path=$home_dir/${ID}/
path_FINAL="/home/skgtaza/Scratch/DWI/${ID}/NODDI/FINAL"

cd ${path_FINAL}

# FOD estimation using the average response function
dwi2fod msmt_csd dwi_den_unr_preproc_unbiased_upsampled.mif -mask dwi_mask_upsampled_new.mif ../../../group_average_response_wm.txt wmfod.mif ../../../group_average_response_gm.txt gm.mif  ../../../group_average_response_csf.txt csf.mif

# Joint bias field correction and intensity normalisation
mtnormalise wmfod.mif wmfod_norm.mif gm.mif gm_norm.mif csf.mif csf_norm.mif -mask dwi_mask_upsampled_new.mif