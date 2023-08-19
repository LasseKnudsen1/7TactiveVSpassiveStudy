#Get BOLD corrected VASO timeseries and compute tSNR maps

subject=(8)
runs=(`count 1 2 -digits 2`)
num_timepoints=12 #per trial
num_trials=12 #per run
num_vol_upsample=288

for subj in ${subject[@]} ; do 

#set path and move to proper folder
printf -v root_dir "${HOME}/Desktop/VASO_AP_%04d" ${subj}
output_dir=${root_dir}/results
cd $output_dir 


## ==================== Temporal upsampling =================#
	for run in ${runs[@]}; do
	for condition in "active" "passive"; do
	3dupsample -linear -n 2 -prefix rm.rnoNORDIC_${condition}_INV1_${run}_upsample.nii -input rnoNORDIC_${condition}_INV1_${run}.nii
	3dupsample -linear -n 2 -prefix rm.rnoNORDIC_${condition}_INV2_${run}_upsample.nii -input rnoNORDIC_${condition}_INV2_${run}.nii

	#Shift nulled timeseries:
	3dtcat -overwrite -prefix rm.rnoNORDIC_${condition}_INV2_${run}_upsample.nii rm.rnoNORDIC_${condition}_INV2_${run}_upsample.nii"[0]" rm.rnoNORDIC_${condition}_INV2_${run}_upsample.nii"[0..$(echo "${num_vol_upsample}-2" | bc)]" 
	done
	done

## ==================== BOLD correction =================#
#BOLD correction:
	for run in ${runs[@]}; do
	for condition in "active" "passive"; do
	LN_BOCO -Nulled rm.rnoNORDIC_${condition}_INV2_${run}_upsample.nii -BOLD rm.rnoNORDIC_${condition}_INV1_${run}_upsample.nii -trialBOCO 24

	#Downsample so we get rid of all interpolated volumes:
	3dtcat -prefix ./noNORDIC_${condition}_VASO_LN_${run}.nii rm_VASO_LN.rnoNORDIC_${condition}_INV2_${run}_upsample.nii'[1..$(2)]' -overwrite
	3dtcat -prefix ./noNORDIC_${condition}_VASO_trialAV_${run}.nii rm_VASO_trialAV_LN.rnoNORDIC_${condition}_INV2_${run}_upsample.nii'[1..$(2)]' -overwrite
	3dtcat -prefix ./noNORDIC_${condition}_BOLD_trialAV_${run}.nii rm_BOLD_trialAV_LN.rnoNORDIC_${condition}_INV2_${run}_upsample.nii'[0..$(2)]' -overwrite

	done
	done


trash ./rm*.nii
## ==================== Compute tSNR maps =================#
	for run in ${runs[@]} ; do
	3dTstat -overwrite -cvarinv -prefix tSNR_noNORDIC_active_VASO_${run}.nii noNORDIC_active_VASO_LN_${run}.nii
	3dTstat -overwrite -cvarinv -prefix tSNR_noNORDIC_passive_VASO_${run}.nii noNORDIC_passive_VASO_LN_${run}.nii

	3dTstat -overwrite -cvarinv -prefix tSNR_noNORDIC_active_BOLD_${run}.nii rnoNORDIC_active_INV1_${run}.nii
	3dTstat -overwrite -cvarinv -prefix tSNR_noNORDIC_passive_BOLD_${run}.nii rnoNORDIC_passive_INV1_${run}.nii
	done

#Average tSNR maps across all runs for VASO and BOLD:
3dmean -prefix tSNR_noNORDIC_VASO.nii tSNR_noNORDIC_active_VASO_01.nii tSNR_noNORDIC_active_VASO_02.nii tSNR_noNORDIC_passive_VASO_01.nii tSNR_noNORDIC_passive_VASO_02.nii
3dmean -prefix tSNR_noNORDIC_BOLD.nii tSNR_noNORDIC_active_BOLD_01.nii tSNR_noNORDIC_active_BOLD_02.nii tSNR_noNORDIC_passive_BOLD_01.nii tSNR_noNORDIC_passive_BOLD_02.nii 


#Move files
mkdir ./tSNR 
mkdir ./trialAV
mv ./tSNR*.nii ./tSNR
mv ./tSNR ./analysis
mv ./*trialAV*.nii ./trialAV
done

