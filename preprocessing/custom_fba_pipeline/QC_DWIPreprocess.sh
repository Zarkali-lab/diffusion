#!/bin/bash

### QC DWI Preprocess outputs

### First need to copy masks and upsampled dwi out of HPC
#rsync -avz --no-p --no-g --chmod=ug=rwx <SOURCE> <DESTINATION> 

# Location of FINAL files
subject=$1

cd $subject/FINAL

# Check the b0 pair for artifacts
mrview b0_pair.mif

# Check response function - toggle right and left arrows to check across increasing b-values
shview wm.txt # should be doughnut shaped
shview gm.txt # should be circle
shview csf.txt # should be circle that colapses quickly

# Check voxel assignment - Red CSF, blue GM and green WM
mrview dwi_den_unr_preproc_unbiased_upsampled.mif -overlay.load voxels.mif

## View brain mask
mrview dwi_mask_upsampled.mif

# ## If mask needs to be hand drawn then need to resize this to fit the upsampled image (if drawn against b0_pain).
# mrgrid dwi_mask_upsampled_new.mif regrid -size 169,169,111 dwi_mask_upsampled_new.mif -interp nearest -datatype bit -force