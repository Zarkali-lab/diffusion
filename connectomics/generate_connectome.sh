#!/bin/bash

# Script to generate a structural connectome post DTI preprocessing
# Author: A. Zarkali
# Date: 16th May 2019


All=("VIPD_007" "VIPD_010" "VIPD_014" "VIPD_015" "VIPD_017" "VIPD_028" "VIPD_031" "VIPD_038" "VIPD_039" "VIPD_051" "VIPD_056" "VIPD_057" "VIPD_068" 
	"VIPD_069" "VIPD_070" "VIPD_073" "VIPD_078" "VIPD_087" "VIPD_088" "VIPD_091" "VIPD_092" "VIPD_093" "VIPD_099" "VIPD_104" "VIPD_108" "VIPD_111" "VIPD_117" 
	"VIPD_118" "VIPD_119" "VIPD_120" "VIPD_122" "VIPD_124" "VIPD_125" "VIPD_126" "VIPD_128" "VIPD_130" "VIPD_131" "VIPD_132" "VIPD_134" "VIPD_137" "VIPD_138" 
	"VIPD_142" "VIPD_143" "VIPD_145" "VIPD_146" "VIPD_148" "VIPD_149" "VIPD_150" "VIPD_152" "VIPD_156" "VIPD_157" "VIPD_158" "VIPD_159"  "VIPD_160" "VIPD_161" 
	"VIPD_162" "VIPD_163" "VIPD_167" "VIPD_168" "VIPD_169" "VIPD_172" "VIPD_175" "VIPD_177" "VIPD_178" "VIPD_179" "VIPD_180" "VIPD_181" "VIPD_182" "VIPD_184" 
	"VIPD_185" "VIPD_186" "VIPD_187" "VIPD_188" "VIPD_189" "VIPD_190" "VIPD_191" "VIPD_192" "VIPD_193" "VIPD_194" "VIPD_195" "VIPD_196" "VIPD_197" "VIPD_198" 
	"VIPD_199" "VIPD_200" "VIPD_201" "VIPD_208" "VIPD_209" "VIPD_210" "VIPD_214" "VIPD_215" "VIPD_216" "VIPD_219" "VIPD_220" "VIPD_222" "VIPD_223" "VIPD_227" 
	"VIPD_228" "VIPD_229" "VIPD_230" "VIPD_232" "VIPD_233" "VIPD_234" "VIPD_235" "VIPD_236" "VIPD_238" "VIPD_239" "VIPD_241" "VIPD_242" "VIPD_243" 
	"VIPD_244" "VIPD_245" "VIPD_246" "VIPD_247" "VIPD_248" "VIPD_249" "VIPD_250" "VIPD_251" "VIPD_256" "VIPD_257" "VIPD_264" "VIPD_266" "VIPD_268" 
	"VIPD_272" "VIPD_273" "VIPD_274" "VIPD_275" "VIPD_276" "VIPD_277" "VIPD_279" "VIPD_280" "VIPD_281" "VIPD_282" "VIPD_283" "VIPD_284" "VIPD_309" "VIPD_311" 
	"VIPD_377" "VIPD_404" "VIPD_406" "VIPD_504" "VIPD_601")

Redo=("VIPD_038" "VIPD_124" "VIPD_125" "VIPD_137" "VIPD_146" "VIPD_148" "VIPD_150" "VIPD_015" "VIPD_028" "VIPD_070")

# Create 5tt image from raw T1 (fsl)
for t in ${All[@]}
do
	cd /home/skgtaza/Scratch/MRI_data_1/T1
	tar -xvf *.tar
	cd ..
	mrconvert /T1/ T1_raw.mif
	5ttgen fsl T1_raw.mif 5tt_nocoreg.mif
done

# QC step view 5tt images 
# Now can remove T1 folders

for t in ${All[@]}
do
	cd ~/Scratch/MRI_data_1/${t}/NODDI/FINAL/
	dwiextract dwi_den_unr_preproc_unbiased.mif - -bzero | mrmath – mean mean_b0_preprocessed.mif –axis 3
	mrconvert mean_b0_preprocessed.mif mean_b0_preprocessed.nii.gz
	cd ../../
	mrconvert 5tt_nocoreg.mif 5tt_nocoreg.nii.gz
	fslsplit 5tt_nocoreg.nii.gz myprefix -t
	cd NODDI/FINAL/
	flirt –in mean_b0_preprocessed.nii.gz –ref ../../myprefix0000.nii.gz –dof 6 –omat diff2struct_fsl.mat
	transformconvert diff2struct_fsl.mat mean_b0_preprocessed.nii.gz ../../5tt_nocoreg.nii.gz flirt_import diff2struct_mrtrix.txt
	transformcalc diff2struct_mrtrix.txt invert struct2diff.txt
	mrtransform ../../5tt_nocoreg.mif –linear struct2diff.txt ../../5tt_coreg.mif
done

# QC step - check that images are aligned
# mrview dwi_den_unr_preproc_unbiased.mif –overlay.load 5tt_nocoreg.mif –overlay.colourmap 2 -overlay.load 5tt_coreg.mif –overlay.colourmap 1

for t in ${All[@]}
do
# Create mask for seeding
	5tt2gmwmi 5tt_coreg.mif gmwmSeed_coreg.mif
done 

# QC step - check seeding mask
# mrview dwi_den_unr_preproc_unbiased.mif –overlay.load gmwmSeed_coreg.mif


# for t in ${All[@]}
# do
# 	# Recalculate FOD with the individual response functions
# 	dwi2fod msmt_csd dwi_den_unr_preproc_unbiased.mif -mask new_dwi_mask_upsampled wm.txt wmfod_individual.mif gm.txt gmfod.mif csf.txt csffod.mif
# 	mtnormalise wmfod_individual.mif wmfod_norm_individual.mif gmfod.mif gmfod_norm.mif csffod.mif csffod_norm.mif -mask new_dwi_mask_upsampled.mif
# done


for t in ${All[@]}
do
	#Run tractography
	tckgen wmfod_norm.mif 10M.tck -act 5tt_coreg.mif -backtrack -crop_at_gmwmi -seed_dynamic wmfod_norm.mif -maxlength 250 -select 10M -cutoff 0.06 -force 
	#Reduce size of tracks file for visualisation
	tckedit 10M.tck 200k.tck -number 200000
done 

# QC step - visualise tract
# mrview dwi_den_unr_preproc_unbiased.mif –tractography.load 200k.tck

for t in ${All[@]}
do
	#Run sift2
	tcksift2 -act 5tt_coreg.mif 10M.tck ${t}wmfod_norm.mif sift_weights.txt -force
	#Generate connectome - need to run T1 through freesurfer first
	tck2connectome 10M.tck -symmetric -zero_diagonal -tck_weights_in sift_weights.txt hcpmmp1_parcels_coreg.mif connectome.csv -force
done


# Visualise connectome in mrtrix
# mrview hcpmmp1_parcels_coreg.mif –connectome.init hcpmmp1_parcels_coreg.mif –connectome.load hcpmmp1.csv
