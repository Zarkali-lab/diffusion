#!/bin/bash

#### Use: generate a longitudinal population template for VIPD longitudinal analysis
#### Author: A. Zarkali
#### Date: 04/02/2023

# Participant IDs for template construction (STEP 1) come from a local text file,
# one ID per line. Blank lines and lines starting with # are ignored.
# This is the selected template subset, not necessarily all longitudinal participants.
PARTICIPANTS_FILE="${PARTICIPANTS_FILE:-participants.txt}"
if [[ ! -f "$PARTICIPANTS_FILE" ]]; then
    echo "Missing participant list: $PARTICIPANTS_FILE" >&2
    exit 1
fi
mapfile -t All < <(awk 'NF && $1 !~ /^#/ {print $1}' "$PARTICIPANTS_FILE")
if (( ${#All[@]} == 0 )); then
    echo "No participant IDs found in $PARTICIPANTS_FILE" >&2
    exit 1
fi

#### FBA pipeline for version 3.0.4 https://mrtrix.readthedocs.io/en/3.0.4/fixel_based_analysis/mt_fibre_density_cross-section.html 


####------------------------------------------------------------------------------------------- STEP 0 - Copy data ------------------------------------------------------------------------------------------------- 

#### Parameters

# STEP 0 uses a separate full-cohort list, not the STEP 1 template subset.
for j in `awk '{print $1}' Allparticipants_Session3.txt` ; do

cd ${j}

echo ${j}

#### Make directories
# HARD-CODED MYRIAD PATH: replace /home/skgtaza/Scratch/VIPD_LongDiffusion
# with your own cluster project directory before running this step.
mkdir /home/skgtaza/Scratch/VIPD_LongDiffusion/SESSION1/${j}
mkdir /home/skgtaza/Scratch/VIPD_LongDiffusion/SESSION2/${j}
mkdir /home/skgtaza/Scratch/VIPD_LongDiffusion/SESSION3/${j}

# HARD-CODED MYRIAD PATH: replace ~/Scratch/VIPD_LongDiffusion as needed.
cd ~/Scratch/VIPD_LongDiffusion

#### Copy data
# HARD-CODED STORAGE PATHS: replace ssh.rd.ucl.ac.uk and /rd/live/... with
# your current research-data location before running these transfers.
# session 1
scp -r ssh.rd.ucl.ac.uk:/rd/live/ritd-ag-project-rd00hy-rswei70/home_study_2017_data/AZ_Fixels/SESSION1/${j}/NODDI/FINAL/\{wmfod_norm.mif, mask_dwi_unbiased_upsampled.mif\} /SESSION1/${j}/
# session 2
scp -r ssh.rd.ucl.ac.uk:/rd/live/ritd-ag-project-rd00hy-rswei70/home_study_2017_data/AZ_Fixels/SESSION2/${j}/FINAL/\{wmfod_norm.mif, mask_dwi_unbiased_upsampled_new.mif\} /SESSION2/${j}/
# session 3
scp -r ssh.rd.ucl.ac.uk:/rd/live/ritd-ag-project-rd00hy-rswei70/home_study_2017_data/AZ_Fixels/SESSION3/${j}/FINAL/\{wmfod_norm.mif, mask_dwi_unbiased_upsampled_new.mif\} /SESSION3/${j}/

done

####------------------------------------------------------------------------------------------- STEP 1 - RIGID REGISTRATION of random subjects ------------------------------------------------------------------------------------------------ 

# Random subjects (10 controls, 10 PD low vis, 10 PD high vis)
# Template subset loaded from PARTICIPANTS_FILE above; do not embed subject IDs here.

mkdir TEMPLATE
mkdir TEMPLATE/FINAL
mkdir TEMPLATE/MASK

# Register all 3 visits
for t in "${All[@]}"
do

mkdir TEMPLATE/${t}
mkdir TEMPLATE/${t}/fod_input
mkdir TEMPLATE/${t}/mask_input
mkdir TEMPLATE/${t}/transformed_midway

#### COPY FILES
# cp -r SESSION1/${t}/wmfod_norm.mif TEMPLATE/${t}/fod_input/dwi_session1.mif
# cp -r SESSION2/${t}/wmfod_norm.mif TEMPLATE/${t}/fod_input/dwi_session2.mif
# cp -r SESSION3/${t}/wmfod_norm.mif TEMPLATE/${t}/fod_input/dwi_session3.mif

# cp -r SESSION1/${t}/mask_dwi_unbiased_upsampled.mif TEMPLATE/${t}/mask_input/dwi_session1.mif
# cp -r SESSION2/${t}/mask_dwi_unbiased_upsampled_new.mif TEMPLATE/${t}/mask_input/dwi_session2.mif
# cp -r SESSION3/${t}/mask_dwi_unbiased_upsampled_new.mif TEMPLATE/${t}/mask_input/dwi_session3.mif

###### FIRST OPTION - NIFTY REG
# declare the files
session1=TEMPLATE/${t}/fod_input/dwi_session1
session2=TEMPLATE/${t}/fod_input/dwi_session2
session3=TEMPLATE/${t}/fod_input/dwi_session3
session2to1=TEMPLATE/${t}/transformed_midway/session2to1
session1to2=TEMPLATE/${t}/transformed_midway/session1to2
session2to3=TEMPLATE/${t}/transformed_midway/session2to3
session3to2=TEMPLATE/${t}/transformed_midway/session3to2
session3to1=TEMPLATE/${t}/transformed_midway/session3to1
session1to3=TEMPLATE/${t}/transformed_midway/session1to3

mask1=TEMPLATE/${t}/mask_input/dwi_session1
mask2=TEMPLATE/${t}/mask_input/dwi_session2
mask3=TEMPLATE/${t}/mask_input/dwi_session3
mask2to1=TEMPLATE/${t}/transformed_midway/mask2to1
mask1to2=TEMPLATE/${t}/transformed_midway/mask1to2
mask2to3=TEMPLATE/${t}/transformed_midway/mask2to3
mask3to2=TEMPLATE/${t}/transformed_midway/mask3to2
mask3to1=TEMPLATE/${t}/transformed_midway/mask3to1
mask1to3=TEMPLATE/${t}/transformed_midway/mask1to3

mrconvert ${session1}.mif ${session1}.nii
mrconvert ${session2}.mif ${session2}.nii
mrconvert ${session3}.mif ${session3}.nii

reg_aladin -ref ${session1} -flo ${session2} -rigOnly -res ${session2to1}
reg_aladin -ref ${session1} -flo ${session3} -rigOnly -res ${session3to1}
reg_aladin -ref ${session2} -flo ${session1} -rigOnly -res ${session1to2}
reg_aladin -ref ${session2} -flo ${session3} -rigOnly -res ${session3to2}
reg_aladin -ref ${session3} -flo ${session2} -rigOnly -res ${session2to3}
reg_aladin -ref ${session3} -flo ${session1} -rigOnly -res ${session1to3}

mrconvert ${session2to1}.nii ${session2to1}.mif
mrconvert ${session2to3}.nii ${session2to3}.mif
mrconvert ${session1to2}.nii ${session1to2}.mif
mrconvert ${session1to3}.nii ${session1to3}.mif
mrconvert ${session3to1}.nii ${session3to1}.mif
mrconvert ${session3to2}.nii ${session3to2}.mif

mrmath ${session2to1}.mif ${session2to3}.mif ${session1to2}.mif ${session1to3}.mif ${session3to1}.mif ${session3to2}.mif -sum TEMPLATE/${t}/${t}_template.mif

# masks
mrconvert ${mask1}.mif ${mask1}.nii
mrconvert ${mask2}.mif ${mask2}.nii
mrconvert ${mask3}.mif ${mask3}.nii

reg_aladin -ref ${mask1} -flo ${mask2} -rigOnly -res ${mask2to1}
reg_aladin -ref ${mask1} -flo ${mask3} -rigOnly -res ${mask3to1}
reg_aladin -ref ${mask2} -flo ${mask1} -rigOnly -res ${mask1to2}
reg_aladin -ref ${mask2} -flo ${mask3} -rigOnly -res ${mask3to2}
reg_aladin -ref ${mask3} -flo ${mask2} -rigOnly -res ${mask2to3}
reg_aladin -ref ${mask3} -flo ${mask1} -rigOnly -res ${mask1to3}

mrconvert ${mask2to1}.nii ${mask2to1}.mif
mrconvert ${mask2to3}.nii ${mask2to3}.mif
mrconvert ${mask1to2}.nii ${mask1to2}.mif
mrconvert ${mask1to3}.nii ${mask1to3}.mif
mrconvert ${mask3to1}.nii ${mask3to1}.mif
mrconvert ${mask3to2}.nii ${mask3to2}.mif

mrmath ${mask2to1}.mif ${mask2to3}.mif ${mask1to2}.mif ${smaskto3}.mif ${mask3to1}.mif ${mask3to2}.mif -sum TEMPLATE/${t}/${t}_mask.mif

### SECOND OPTION  - MRTRIX POPULATION TEMPLATE SCRIPT
population_template TEMPLATE/${t}/fod_input -mask_dir TEMPLATE/${t}/mask_input/ TEMPLATE/${t}/${t}_template.mif -type rigid -voxel_size 1.3 -template_mask TEMPLATE/${t}/${t}_mask.mif 

### IN BOTH OPTIONS NEED TO REGRID USING MRTRIX 3.0.4 version
mrgrid TEMPLATE/${t}/${t}_template.mif regrid -template TEMPLATE/${t}/fod_input/dwi_session1.mif TEMPLATE/FINAL/${t}_template.mif
mrgrid TEMPLATE/${t}/${t}_mask.mif regrid -template TEMPLATE/${t}/mask_input/dwi_session1.mif TEMPLATE/MASK/${t}_mask.mif

done 

# create inter-subject template
population_template TEMPLATE/FINAL/ -mask_dir TEMPLATE/MASK wmfod_template_long.mif -voxel_size 1.3

# create tractogram on population template
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 wmfod_template_long.mif -seed_image wmfod_long_mask.mif -mask wmfod_long_mask.mif -select 20000000 -cutoff 0.06 tracks_20_million_long.tck
# Reduce biases in the tractogram
tcksift tracks_20_million_long.tck wmfod_template_long.mif tracks_2_million_sift_long.tck -term_number 2000000
# Generate fixel-fixel connectivity matrix
fixelconnectivity fixel_mask/ tracks_2_million_sift_long.tck matrix/
# Smooth fixel data
fixelfilter fd_SESSION1 smooth fd_smooth_SESSION1 -matrix matrix/
fixelfilter log_fc_SESSION1 smooth log_fc_smooth_SESSION1 -matrix matrix/
fixelfilter fdc_SESSION1 smooth fdc_smooth_SESSION1 -matrix matrix/

####------------------------------------------------------------------------------------------- STEP 2 - REGISTER ALL SUBJECTS TO THE TEMPLATE ------------------------------------------------------------------------------------------------ 
# Parameters
t=$1 # first argument when calling the script

# HARD-CODED MYRIAD PATH: replace ~/Scratch/VIPD_LongDiffusion as needed.
# Relative SESSION*/TEMPLATE/atlases paths below assume this project layout.
cd ~/Scratch/VIPD_LongDiffusion

session1=SESSION1/${ID}/wmfod_norm.mif
session2=SESSION2/${ID}/wmfod_norm.mif
session3=SESSION3/${ID}/wmfod_norm.mif
mask1=SESSION1/${ID}/dwi_mask_upsampled_new.mif
mask2=SESSION2/${ID}/dwi_mask_upsampled_new.mif
mask3=SESSION3/${ID}/dwi_mask_upsampled_new.mif

#### REGISTER TO THE TEMPLATE

# register all FODs to templates
mrregister ${session1} -mask ${mask1} TEMPLATE/wmfod_template_long.mif -nl_warp SESSION1/${t}/subject2template_warp.mif SESSION1/${t}/template2subject_warp.mif -force
mrregister ${session2} -mask ${mask2} TEMPLATE/wmfod_template_long.mif -nl_warp SESSION2/${t}/subject2template_warp.mif SESSION2/${t}/template2subject_warp.mif -force
mrregister ${session3} -mask ${mask3} TEMPLATE/wmfod_template_long.mif -nl_warp SESSION3/${t}/subject2template_warp.mif SESSION3/${t}/template2subject_warp.mif -force

# warp all masks to template space
mrtransform ${mask1} -warp SESSION1/${t}/subject2template_warp.mif -reorient_fod no -interp nearest -datatype bit SESSION1/${t}/dwi_mask_in_template_space.mif -force
mrtransform ${mask2} -warp SESSION2/${t}/subject2template_warp.mif -reorient_fod no -interp nearest -datatype bit SESSION2/${t}/dwi_mask_in_template_space.mif -force
mrtransform ${mask3} -warp SESSION3/${t}/subject2template_warp.mif -reorient_fod no -interp nearest -datatype bit SESSION3/${t}/dwi_mask_in_template_space.mif -force

### Warp FOD images to template space
#warp FOD image
mrtransform ${session1} -warp SESSION1/${t}/subject2template_warp.mif -reorient_fod no SESSION1/${t}/fod_in_template_space_NOT_REORIENTED.mif -force
mrtransform ${session2} -warp SESSION2/${t}/subject2template_warp.mif -reorient_fod no SESSION2/${t}/fod_in_template_space_NOT_REORIENTED.mif -force
mrtransform ${session3} -warp SESSION3/${t}/subject2template_warp.mif -reorient_fod no SESSION3/${t}/fod_in_template_space_NOT_REORIENTED.mif -force


# Create template mask
mrmath TEMPLATE/masks/*.mif min TEMPLATE/wmfod_long_mask.mif -datatype bit
# Create fixel mask for analysis
fod2fixel -mask TEMPLATE/wmfod_long_mask.mif -fmls_peak_value 0.06 TEMPLATE/wmfod_template_long.mif TEMPLATE/fixel_mask


#segment FOD image
fod2fixel -mask TEMPLATE/wmfod_long_mask.mif SESSION1/${t}/fod_in_template_space_NOT_REORIENTED.mif SESSION1/${t}/fixel_in_template_space_NOT_REORIENTED -afd SESSION1/${t}/fd.mif -force

# Reorient fixelsls 
fixelreorient SESSION1/${t}/fixel_in_template_space_NOT_REORIENTED SESSION1/${t}/subject2template_warp.mif SESSION1/${t}/fixel_in_template_space -force

#Assign subject fixels to template fixels
fixelconnectivity fixel_mask/ tracks_2_million_sift.tck matrix/
fixelcorrespondence SESSION1/${t}/fixel_in_template_space/fd.mif TEMPLATE/fixel_masks TEMPLATE/fd_session1 ${t}.mif -force

# Compute FC
warp2metric SESSION1/${t}/subject2template_warp.mif -fc TEMPLATE/fixel_mask TEMPLATE/fc_session1 ${t}.mif -force

cp TEMPLATE/fc_session1/index.mif TEMPLATE/fc_session1/directions.mif TEMPLATE/log_fc_session1

# Compute Log FC
mrcalc TEMPLATE/fc_session1/IN.mif -log TEMPLATE/log_fc_session1/${t}.mif

##Compute FDC ?ONLY once for all participants after above completed
mrcalc TEMPLATE/fd_session1/IN.mif TEMPLATE/fc/IN.mif -mult TEMPLATE/fdc_sesion1/${t}.mif


####### ROIs on new template

##### WITH NIFTI REG
reference=TEMPLATE/wmfod_template_long.nii.gz
float=atlases/MNI152_T1_1mm.nii.gz
affine=JHU_diff.txt
result_aff=atlases/JHU_template_space_aff.nii.gz
result_cpp=atlases/JHU_template_space_cpp.nii.gz
# Run rigid and affine registration
reg_aladin -ref ${reference} -flo ${float} -aff ${affine} -res ${result_aff}
# Resample JHU tracts to diffusion space
reg_resample -ref ${reference} -flo  atlases/JHU/JHU-ICBM-tracts-prob-1mm.nii.gz -aff ${affine} -res atlases/JHU_in_template_space.nii.gz  -NN
for roinum in {1..48}
do
	echo ${roinum}
	mkdir atlases/MasksIndividualROIs/${roinum}
	fslmaths atlases/JHU_in_template_space.nii.gz -thr ${roinum} -uthr ${roinum} -bin atlases/MasksIndividualROIs/${roinum}/${roinum}_bin
	mrconvert atlases/MasksIndividualROIs/${roinum}/${roinum}_bin.nii.gz atlases/MasksIndividualROIs/${roinum}/${roinum}_bin.mif
done

##### WITH FLIRT
flirt -in atlases/MNI152_T1_1mm.nii.gz -ref TEMPLATE/wmfod_template_long.nii.gz -omat atlases/JHU_to_template.mat
transformconvert atlases/JHU_to_template.mat atlases/MNI152_T1_1mm.nii.gz TEMPLATE/wmfod_template_long.nii.gz flirt_import atlases/atlas2image_mrtrix.txt
mrtransform atlases/JHU/JHU-ICBM-tracts-prob-1mm.nii.gz -linear atlases/atlas2image_mrtrix.txt atlases/JHU_in_template_space.nii.gz -force
mrconvert atlases/JHU_in_template_space.nii.gz atlases/JHU_in_template_space.mif -force 

for roinum in {1..48}
do
	echo ${roinum}
	mkdir atlases/MasksIndividualROIs/${roinum}
	fslmaths atlases/JHU/JHU-ICBM-labels-1mm.nii.gz -thr ${roinum} -uthr ${roinum} -bin atlases/MasksIndividualROIs/${roinum}/${roinum}_bin
	# fslstats -t  ${lps_image} -k ./results/VE_${roinum}.nii.gz -M > ./results/roi${roinum}.txt
	mrconvert atlases/MasksIndividualROIs/${roinum}/${roinum}_bin.nii.gz atlases/MasksIndividualROIs/${roinum}/${roinum}_bin.mif
	mrtransform atlases/MasksIndividualROIs/${roinum}/${roinum}_bin.mif -linear atlases/atlas2image_mrtrix.txt -template TEMPLATE/wmfod_template_long.mif atlases/MasksIndividualROIs/${roinum}/${roinum}_image_space.mif
done


