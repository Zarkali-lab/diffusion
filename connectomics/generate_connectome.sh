#!/bin/bash

# Script to generate a structural connectome post DTI preprocessing
# Author: A. Zarkali
# Date: 16th May 2019
#
# Usage:
#   ./generate_connectome.sh [participants.txt]
#   Place one participant pseudocode per line; skip blank lines and # comments.

set -e

PARTICIPANTS_FILE="${1:-participants.txt}"
if [[ ! -f "$PARTICIPANTS_FILE" ]]; then
    echo "Missing participant list: $PARTICIPANTS_FILE" >&2
    exit 1
fi
mapfile -t PARTICIPANTS < <(awk 'NF && $1 !~ /^#/ {print $1}' "$PARTICIPANTS_FILE")
if (( ${#PARTICIPANTS[@]} == 0 )); then
    echo "No participant IDs found in $PARTICIPANTS_FILE" >&2
    exit 1
fi

# HARD-CODED MYRIAD PATH: replace with your own MRI_data_1 location.
DATA_ROOT="/home/skgtaza/Scratch/MRI_data_1"

for t in "${PARTICIPANTS[@]}"; do
BASE="${DATA_ROOT}/${t}"

echo "Processing ${t}"

# -------------------------------------------------------------------------
# Create 5tt image from raw T1 (FSL)
# -------------------------------------------------------------------------

cd "${BASE}/T1"

tar -xvf ./*.tar

cd "${BASE}"

mrconvert T1/ T1_raw.mif
5ttgen fsl T1_raw.mif 5tt_nocoreg.mif


# -------------------------------------------------------------------------
# Register 5tt image to diffusion space
# -------------------------------------------------------------------------

cd "${BASE}/NODDI/FINAL"

dwiextract dwi_den_unr_preproc_unbiased.mif - -bzero \
    | mrmath - mean mean_b0_preprocessed.mif -axis 3

mrconvert mean_b0_preprocessed.mif mean_b0_preprocessed.nii.gz

cd "${BASE}"

mrconvert 5tt_nocoreg.mif 5tt_nocoreg.nii.gz
fslsplit 5tt_nocoreg.nii.gz myprefix -t

cd "${BASE}/NODDI/FINAL"

flirt \
    -in mean_b0_preprocessed.nii.gz \
    -ref "${BASE}/myprefix0000.nii.gz" \
    -dof 6 \
    -omat diff2struct_fsl.mat

transformconvert \
    diff2struct_fsl.mat \
    mean_b0_preprocessed.nii.gz \
    "${BASE}/5tt_nocoreg.nii.gz" \
    flirt_import \
    diff2struct_mrtrix.txt

transformcalc \
    diff2struct_mrtrix.txt \
    invert \
    struct2diff.txt

mrtransform \
    "${BASE}/5tt_nocoreg.mif" \
    -linear struct2diff.txt \
    "${BASE}/NODDI/FINAL/5tt_coreg.mif"


# -------------------------------------------------------------------------
# Create GMWMI seeding mask
# -------------------------------------------------------------------------

cd "${BASE}/NODDI/FINAL"

5tt2gmwmi \
    5tt_coreg.mif \
    gmwmSeed_coreg.mif


# -------------------------------------------------------------------------
# Tractography
# -------------------------------------------------------------------------

tckgen \
    wmfod_norm.mif \
    10M.tck \
    -act 5tt_coreg.mif \
    -backtrack \
    -crop_at_gmwmi \
    -seed_dynamic wmfod_norm.mif \
    -maxlength 250 \
    -select 10M \
    -cutoff 0.06 \
    -force

# Smaller tractogram for visualisation
tckedit \
    10M.tck \
    200k.tck \
    -number 200000


# -------------------------------------------------------------------------
# SIFT2
# -------------------------------------------------------------------------

tcksift2 \
    -act 5tt_coreg.mif \
    10M.tck \
    wmfod_norm.mif \
    sift_weights.txt \
    -force


# -------------------------------------------------------------------------
# Generate connectome
# -------------------------------------------------------------------------

tck2connectome \
    10M.tck \
    -symmetric \
    -zero_diagonal \
    -tck_weights_in sift_weights.txt \
    hcpmmp1_parcels_coreg.mif \
    connectome.csv \
    -force

echo "Finished ${t}"
done
