#This script (27-02-2023) is to localize ROIs in 3dssfp. I do it both using AP contrast and active contrast alone. 
subj=S01
rootDir="/Volumes/SeagateAPstudy/activeVSpassive_study/analyzed_3dssfp/${subj}"
surfDir="${rootDir}/fs_surface/${subj}/SUMAhd"
analysisDir="${rootDir}/fs_surface/${subj}/${subj}" 
outputDir="${HOME}/Desktop/3dssfp_APstudy/analyzed/${subj}"

#==================== Prepare files for localization ======================#
#Average across conditions to get localizer:
3dmean -prefix ${outputDir}/mean_delta_ap.nii ${outputDir}/mean_delta_active.nii ${outputDir}/mean_delta_passive.nii
3dresample -master ${outputDir}/T1_bssfp_al_resample.nii -rmode Cu -prefix ${outputDir}/mean_delta_ap_resample.nii -input ${outputDir}/mean_delta_ap.nii


#Make projection to surface:
3dVol2Surf -spec ${surfDir}/${subj}_lh.spec \
           -surf_A ${surfDir}/lh.smoothwm \
           -surf_B ${surfDir}/lh.pial  \
           -sv  ${analysisDir}/${subj}_SurfVol_Alnd_Exp.nii  \
           -gridparent  ${outputDir}/mean_delta_ap_resample.nii  \
           -map_func ave  \
           -f_p1_fr 0 -f_pn_fr 0 \
           -f_steps 30 \
           -out_niml ${analysisDir}/mean_delta_ap.niml.dset

3dVol2Surf -spec ${surfDir}/${subj}_lh.spec \
           -surf_A ${surfDir}/lh.smoothwm \
           -surf_B ${surfDir}/lh.pial  \
           -sv  ${analysisDir}/${subj}_SurfVol_Alnd_Exp.nii  \
           -gridparent  ${outputDir}/mean_delta_active_resample.nii  \
           -map_func ave  \
           -f_p1_fr 0 -f_pn_fr 0 \
           -f_steps 30 \
           -out_niml ${analysisDir}/mean_delta_active.niml.dset


#==================== Run suma ======================#
cd ${analysisDir}
afni -niml & suma -spec ../SUMAhd/${subj}_lh.spec -sv ${subj}_SurfVol_Alnd_Exp.nii -input mean_delta_ap.niml.dset
afni -niml & suma -spec ../SUMAhd/${subj}_lh.spec -sv ${subj}_SurfVol_Alnd_Exp.nii -input mean_delta_active.niml.dset


#Transform the ROI to a node dataset (.roi and .niml.dset are both surface datasets but different formats)
ROI2dataset  -prefix indexfingerROI_ap -keep_separate -input indexfingerROI_ap.niml.roi  -overwrite
ROI2dataset  -prefix indexfingerROI_active -keep_separate -input indexfingerROI_active.niml.roi  -overwrite


#Project ROI from surface to volume:
source "${HOME}/Desktop/3dssfp_APstudy/afterPreprocessing/run3dSurf2Vol_3dssfp.sh"

#Copy to analyzed directory:
cp ${analysisDir}/indexfingerROI_ap*nii ${outputDir}
cp ${analysisDir}/indexfingerROI_active*nii ${outputDir}

