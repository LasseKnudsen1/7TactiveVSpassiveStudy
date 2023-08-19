#register MP2RAGE to T1weighted. 
subject=(8)

for subj in ${subject[@]} ; do 

#set path and move to proper folder
printf -v root_dir "${HOME}/Desktop/VASO_AP_%04d" ${subj}
output_dir=${root_dir}/results
cd $output_dir 


## ==================== Coregister T1 to EPI (ANTS) =================#

# Call ANTS registration after manually making the initial parameter file called initial_matrix.txt using ITK-snap. This is the estimation step:
#https://github.com/ANTsX/ANTs/wiki/Anatomy-of-an-antsRegistration-call
antsRegistration \
--verbose 1 \
--dimensionality 3 \
--float 1 \
--output [registered_,registered_Warped.nii.gz,registered_InverseWarped.nii.gz] \
--interpolation BSpline[5] \
--use-histogram-matching 0 \
--initial-moving-transform ./initial_matrix.txt \
--winsorize-image-intensities [0.005,0.995] \
--transform Rigid[0.05] \
--metric MI[T1_weighted.nii,./T1/T1_VASO.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x coma.nii \
--transform Affine[0.1] \
--metric MI[T1_weighted.nii,./T1/T1_VASO.nii,0.7,32,Regular,0.1] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x coma.nii \
--transform SyN[0.1,2,0] \
--metric CC[T1_weighted.nii,./T1/T1_VASO.nii,1,2] \
--convergence [1000x500,1e-6,10] \
--shrink-factors 2x1 \
--smoothing-sigmas 1x0vox \
-x coma.nii


#Apply the transforms and reslice:
antsApplyTransforms \
--interpolation BSpline[5] \
-d 3 -i ./T1/T1_VASO.nii \
-r T1_weighted.nii \
-t registered_1Warp.nii.gz \
-t registered_0GenericAffine.mat \
-o ./T1_VASO_al.nii


#Move files
mkdir ./coregParam
mkdir ./analysis
mv ./registered*.gz ./coregParam
mv ./registered*.mat ./coregParam
mv ./initial_matrix.txt ./coregParam
mv ./T1_VASO_al.nii ./analysis
mv ./T1_weighted.nii ./analysis
done