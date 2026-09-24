# PIPELINE FOR FBA 
As used in VIPD and MMPD

## Prerequisites
Mrtrix 3.0.4
FSL
Niftyreg
HPC environment (i.e. myriad)

## STEP 0
### Copy data to HPC Example
$ mkdir /home/<user id>/Scratch/<FBA folder>
$ xargs -I {} mkdir -p "<FBA folder>/{}" < Allparticipants.txt
$ scp -r ssh.rd.ucl.ac.uk:/rd/live/ritd-ag-project-rd00hy-rswei70/home_study_2017_data/MRI_data_3/*/*/*S4.tar FBA/tars/
$ scp -r ssh.rd.ucl.ac.uk:/rd/live/ritd-ag-project-rd00hy-rswei70/home_study_2017_data/MRI_data_3/*/*/*S6.tar FBA/tars/

## STEP 1
### Run the preprocessing script (may need to alter the tar numbers in the script to fit the protocol)
$ DWI_Preprocess.sh <subject id> <FBA folder>
### Example serial job submission script in folder

## STEP 2 
### Copy data back across to y-drive and QC 
$ QC_DWIPreprocess.sh <subject id>

## STEP 3
### Calculate group average response function - need to have a lot but not all the subjects to do this
responsemean */response_wm.txt ../group_average_response_wm.txt
responsemean */response_gm.txt ../group_average_response_gm.txt
responsemean */response_csf.txt ../group_average_response_csf.txt

## STEP 4
### Calculate fods
$ DWI_FOD <subject id> <FBA folder>

## STEP 5
### Calculate group template and register everyong to template
### Example using random subjects in Longitudinal template.sh

## STEP 6
### Run statistical analysis
$ fixelcfestats fd_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_fd/
$ fixelcfestats log_fc_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_log_fc/
$ fixelcfestats fdc_smooth/ files.txt design_matrix.txt contrast_matrix.txt matrix/ stats_fdc/
