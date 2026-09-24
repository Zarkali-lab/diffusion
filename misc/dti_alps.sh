##!/bin/bash

export NIFTYREG_INSTALL=~/Scratch/niftyreg/niftyreg_install/
PATH=${PATH}:${NIFTYREG_INSTALL}/bin
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${NIFTYREG_INSTALL}/lib
export PATH
export LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=${LD_LIBRARY_PATH}

float=../../atlases/MNI152_T1_1mm.nii.gz

rois="alps/ROIs_JHU_ALPS/L_SCR.nii.gz,alps/ROIs_JHU_ALPS/R_SCR.nii.gz,alps/ROIs_JHU_ALPS/L_SLF.nii.gz,alps/ROIs_JHU_ALPS/R_SLF.nii.gz"

for j in  `awk '{print $1}' Participants_Session1.txt` ; do

cd VIPD_LongDiffusion/SESSION1/${j}

# FIT TENSOR
dwi2tensor -mask mask.mif dwi_processed.mif tensor.mif -force
tensor2metric tensor.mif -fa fa.mif -mask mask.mif -force

#### extract the dxx, dyy, dzz tensors (first 3 of the resulting tensor)
mrconvert tensor.mif dxx.nii.gz -coord 3 0 -force
mrconvert tensor.mif dyy.nii.gz -coord 3 1 -force
mrconvert tensor.mif dzz.nii.gz -coord 3 2 -force
dxx="dxx.nii.gz"
dyy="dyy.nii.gz"
dzz="dzz.nii.gz"

# REGISTER TO JHU using niftyreg
mrconvert fa.mif fa.nii.gz
reg_aladin -ref fa.nii.gz -flo ${float} -aff JHU_dif.txt -res JHUnative_space.nii.gz

for r in $(echo $rois | tr -s ',' ' '); do
reg_resample -ref fa.nii.gz -flo ../../../${r} -aff JHU_dif.txt -res "$(basename ${r} .nii.gz)_native.nii.gz"
done

proj_L="$(basename "$(echo "${rois}" | cut -d ',' -f1)" .nii.gz)"_native.nii.gz
proj_R="$(basename "$(echo "${rois}" | cut -d ',' -f2)" .nii.gz)"_native.nii.gz
assoc_L="$(basename "$(echo "${rois}" | cut -d ',' -f3)" .nii.gz)"_native.nii.gz
assoc_R="$(basename "$(echo "${rois}" | cut -d ',' -f4)" .nii.gz)"_native.nii.gz

# GATHER STATS
mkdir -p "alps.stat"
echo "id,x_proj_L,x_assoc_L,y_proj_L,z_assoc_L,x_proj_R,x_assoc_R,y_proj_R,z_assoc_R,alps_L,alps_R,alps" > "alps.stat/alps.csv"
x_proj_L="$(fslstats "${dxx}" -k "${proj_L}" -m)"
x_assoc_L="$(fslstats "${dxx}" -k "${assoc_L}" -m)"
y_proj_L="$(fslstats "${dyy}" -k "${proj_L}" -m)"
z_assoc_L="$(fslstats "${dzz}" -k "${assoc_L}" -m)"
x_proj_R="$(fslstats "${dxx}" -k "${proj_R}" -m)"
x_assoc_R="$(fslstats "${dxx}" -k "${assoc_R}" -m)"
y_proj_R="$(fslstats "${dyy}" -k "${proj_R}" -m)"
z_assoc_R="$(fslstats "${dzz}" -k "${assoc_R}" -m)"
alps_L=`echo "(($x_proj_L+$x_assoc_L)/2)/(($y_proj_L+$z_assoc_L)/2)" | bc -l` #proj1 and assoc1 are left side, bc -l needed for decimal printing results
alps_R=`echo "(($x_proj_R+$x_assoc_R)/2)/(($y_proj_R+$z_assoc_R)/2)" | bc -l` #proj2 and assoc2 are right side, bc -l needed for decimal printing results
alps=`echo "($alps_R+$alps_L)/2" | bc -l`
echo "${j},${x_proj_L},${x_assoc_L},${y_proj_L},${z_assoc_L},${x_proj_R},${x_assoc_R},${y_proj_R},${z_assoc_R},${alps_L},${alps_R},${alps}" >> "alps.stat/alps.csv"

cd ../../../

done
