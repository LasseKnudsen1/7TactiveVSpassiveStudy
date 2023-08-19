#Create T1_weighted.nii
subject=(8)

for subj in ${subject[@]} ; do 

#set path and move to proper folder
printf -v root_dir "${HOME}/Desktop/VASO_AP_%04d" ${subj}
output_dir=${root_dir}/results
cd $output_dir 


## ==================== Create EPI T1 =================#
#First make combined volume of all functional runs (both INV1 and INV2) (order does not matter when we use cvarinvNOD).
3dTcat -prefix combined.nii rnoNORDIC_passive_INV?_0?.nii rnoNORDIC_active_INV?_0?.nii -overwrite
3dTstat -cvarinvNOD -prefix T1_weighted.nii combined.nii 
trash ./combined.nii
done