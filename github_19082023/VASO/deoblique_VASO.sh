#Deoblique files. This changes files to float format so i change back to short (except for NORDIC which are in float format already 
#and for some reason doing the 3dcalc trick has no effect)
subject=(8)

for subj in ${subject[@]} ; do 

#set path and move to proper folder
printf -v root_dir "${HOME}/Desktop/VASO_AP_%04d" ${subj}
output_dir=${root_dir}/results
cd $output_dir

3drefit -deoblique ./T1/T1_VASO.nii
3drefit -deoblique moma.nii
3drefit -deoblique EPI_localizer.nii
3drefit -deoblique EPI_localizer_phase.nii
3drefit -deoblique reverse_VASO.nii
3drefit -deoblique reverse_VASO_phase.nii
3drefit -deoblique reverse_localizer.nii
3drefit -deoblique reverse_localizer_phase.nii

3dcalc -a ./T1/T1_VASO.nii -prefix ./T1/T1_VASO.nii -expr 'a' -overwrite -datum short
3dcalc -a moma.nii -prefix moma.nii -expr 'a' -overwrite -datum short
3dcalc -a EPI_localizer.nii -prefix EPI_localizer.nii -expr 'a' -overwrite -datum short
3dcalc -a EPI_localizer_phase.nii -prefix EPI_localizer_phase.nii -expr 'a' -overwrite -datum short
3dcalc -a reverse_VASO.nii -prefix reverse_VASO.nii -expr 'a' -overwrite -datum short
3dcalc -a reverse_VASO_phase.nii -prefix reverse_VASO_phase.nii -expr 'a' -overwrite -datum short
3dcalc -a reverse_localizer.nii -prefix reverse_localizer.nii -expr 'a' -overwrite -datum short
3dcalc -a reverse_localizer_phase.nii -prefix reverse_localizer_phase.nii -expr 'a' -overwrite -datum short

for condition in active passive; do
for run in 01 02; do
3drefit -deoblique ${condition}_VASO_${run}.nii
3drefit -deoblique ${condition}_VASO_${run}_phase.nii

3dcalc -a ${condition}_VASO_${run}.nii -prefix ${condition}_VASO_${run}.nii -expr 'a' -overwrite -datum short
3dcalc -a ${condition}_VASO_${run}_phase.nii -prefix ${condition}_VASO_${run}_phase.nii -expr 'a' -overwrite -datum short
done 
done


done