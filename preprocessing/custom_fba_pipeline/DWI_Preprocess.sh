#!/bin/bash

#### This script completes all DWI preprocessing of visit 1 data. 
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

# prepare sub directories
cd $home_dir
mkdir ${ID}
cd ${subject_path}

# Extract tar files
mkdir AP
mkdir PA
tar -xvf ../tars/M*${ID}.${tar_AP}.tar -C AP/ 
tar -xvf ../tars/M*${ID}.${tar_PA}.tar -C PA/

# Convert dicoms to .mif
mrconvert AP/ dwi_raw.mif -force
mrconvert PA/ dwi_PA.mif -force
mkdir FINAL
mv *.mif FINAL/

# Denoise
cd FINAL/
#denoise data and create residual map
dwidenoise -noise noise.mif dwi_raw.mif dwi_den.mif -force

#remove gibbs ringing artefacts
mrdegibbs dwi_den.mif dwi_den_unr.mif -axes 0,1 -force

# Motion and distortion correction
## Calculate mean AP b0
dwiextract dwi_den_unr.mif - -bzero | mrmath - mean mean_AP_b0.mif -axis 3 -force
## Calculate mean PA b0
dwiextract dwi_PA.mif - -bzero | mrmath - mean mean_PA_b0.mif -axis 3 -force
## Concatenate b0 images
mrcat mean_AP_b0.mif mean_PA_b0.mif -axis 3 b0_pair.mif 

## Run dwi_preproc
dwifslpreproc dwi_den_unr.mif dwi_den_unr_preproc.mif -pe_dir AP -rpe_pair -se_epi b0_pair.mif -force  -eddy_options " --slm=quadratic"

# Correct Bias field
dwibiascorrect -bias bias.mif -ants dwi_den_unr_preproc.mif dwi_den_unr_preproc_unbiased.mif -force

# Upscale to 1.3mm voxel - necessary for FBA (recommended is 1.25 but kept as 1.3 to keep comparable with VIPD data)
mrgrid dwi_den_unr_preproc_unbiased.mif regrid -vox 1.3 dwi_den_unr_preproc_unbiased_upsampled.mif

# Compute upsampled brain masks
dwi2mask dwi_den_unr_preproc_unbiased_upsampled.mif dwi_mask_upsampled.mif

# Dilate masks
maskfilter dwi_mask_upsampled.mif dilate -npass 5 dwi_mask_upsampled_new.mif -force

# Generate individual response function
dwi2response dhollander -voxels voxels.mif dwi_den_unr_preproc_unbiased_upsampled.mif wm.txt gm.txt csf.txt
