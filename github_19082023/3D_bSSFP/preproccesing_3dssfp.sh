# # Specify:
root_dir=/Volumes/VERBATIM?HD/fmri_data/actpas_experiment/analyzed_3dssfp/S01
output_dir=$root_dir/results
raw_dir=$root_dir/raw_fmri
runs=(`count 1 4 -digits 2`)
T1num=(`count 1 11 -digits 2`)
func="bssfp"
n_dummys=2
TR=6


mkdir $output_dir


#================= DICOM to NIFTI =================#
cd $root_dir/raw_fmri
#Functional volumes:
for i in "active" "passive"; do
for run in ${runs[@]}; do 
  cd ${i}_${run}
  dcm2niix_afni .
  mv ./*.nii ${i}_${run}_raw.nii
  mv $root_dir/raw_fmri/${i}_${run}/${i}_${run}_raw.nii $root_dir/results
  trash ./*.IMA
  trash ./*.json
  cd ..
done
done

#Structural volumes:
cd $output_dir
cdAndDimon(){
  cd $1
  uniq_images *.IMA > uniq_image_list.txt
  Dimon -infile_list uniq_image_list.txt \
      -gert_create_dataset \
      -gert_outdir $2 \
      -gert_to3d_prefix $3 -overwrite \
      -dicom_org \
      -use_obl_origin \
      -save_details Dimon.details \
      -gert_quit_on_err
}

for num in ${T1num[@]} ; do 
  file=`ls ${raw_dir}/T1${num}/*IMA | sed -n '1p'`
  suffix=`dicom_hdr ${file} | grep 'ID Series Description' | awk -F // '{print $3}' | sed s/'t1w_mp2rage_0.70iso_'/''/g`
  cdAndDimon ${raw_dir}/T1${num} ${output_dir} T1_${suffix} &
done 
wait

#denoise T1:
cd $output_dir
3dSkullStrip -orig_vol -prefix T1_250V_INV2_ND_ns.nii -overwrite -input T1_250V_INV2_ND+orig -overwrite
3dAutomask -dilate 1 -prefix T1mask -overwrite T1_250V_INV2_ND_ns.nii
3dcalc -a T1mask+orig -b T1_250V_UNI_Images+orig -expr 'a*b' -prefix T1.nii -overwrite



## ==================== Remove dummy scans =================#
## Minimize the effects due to the scanner onset
cd $root_dir/results
for run in ${runs[@]} ; do
    # Note the special syntax to use shell variable and afni sub-brick selection together
    3dTcat -prefix active_${func}_${run}.nii -overwrite active_${run}_raw.nii'['$n_dummys'..$]' 
    3dTcat -prefix passive_${func}_${run}.nii -overwrite passive_${run}_raw.nii'['$n_dummys'..$]' 
done


## ==================== Deoblique T1 to EPI =================#
## (change ssfp as little as possible, because deoblique requiers resampling, we don't want to resample ssfp)
## So that T1 and ssfp will be more or less aligned without resampling ssfp data
## Deoblique is better done before further temporal or spatial processing to prevent "oblique dataset" warning
## Also, 3dvolreg requires that the volume has been deobliqued.
# Extract oblique ssfp template
cd $root_dir/results
3dTcat -prefix template.oblique_$func -overwrite active_${func}_${runs[0]}.nii'[0]'

3dWarp -oblique2card -prefix T1_${func} -overwrite T1.nii
  3dWarp -card2oblique template.oblique_${func}+orig -prefix T1_${func} -overwrite T1_${func}+orig
  3dAutobox -prefix T1_${func}.nii -overwrite T1_${func}+orig
  3drefit -deoblique T1_${func}.nii


for run in ${runs[@]} ; do
    # Drop rotational information in EPI header, and pretend it is plumb
    # Correct TR, for SSFP
	  3drefit -TR $TR -deoblique active_${func}_${run}.nii
    3drefit -TR $TR -deoblique passive_${func}_${run}.nii
done



## ==================== Count outliers =================#
cd $output_dir
warning_file=warning.pre_ss_epi.txt
# Create an empty file. Empty it if already exists
cat /dev/null >! $warning_file
for run in ${runs[@]} ; do
    # Compute outlier fraction for each volume
    3dToutcount -automask -fraction -polort 3 -legendre \
                active_${func}_${run}.nii > outcount.active_${run}.1D 
    3dToutcount -automask -fraction -polort 3 -legendre \
                passive_${func}_${run}.nii > outcount.passive_${run}.1D
done

for run in ${runs[@]} ; do
    # Censor outlier TRs per run
    # - censor when more than 0.1 of automask voxels are outliers
    # - 0 in the censor file means the volume is excluded from further analysis
    1deval -a outcount.active_${run}.1D -expr "1-step(a-0.1)" > out.cen.active_${run}.1D 
    1deval -a outcount.passive_${run}.1D -expr "1-step(a-0.1)" > out.cen.passive_${run}.1D 
done


# Concatenate outlier fraction of individual runs into a single time series
cat outcount.active*.1D > outcount_active.1D
cat outcount.passive*.1D > outcount_passive.1D
# Concatenate outlier censor files into a single time series
cat out.cen.active*.1D > outcount_censor_active.1D
cat out.cen.passive*.1D > outcount_censor_passive.1D
# Get TR count for each run
tr_counts=(`3dinfo -nt active_${func}_${run}.nii`)
# Get index of minimum outlier volume
# Note that for 1D files, each column is considered as a volume, and time is in
# the horizontal direction. Thus we need a transpose in the end.
minoutidx_a=`3dTstat -argmin -prefix - outcount_active.1D\'`
minoutidx_p=`3dTstat -argmin -prefix - outcount_passive.1D\'`
run_tr_a=( `1d_tool.py -set_run_lengths ${tr_counts[@]} -index_to_run_tr ${minoutidx_a}` )
run_tr_p=( `1d_tool.py -set_run_lengths ${tr_counts[@]} -index_to_run_tr ${minoutidx_p}` )
# Save run and TR indices for extraction of vr_base_min_outlier
minoutrun_a=${runs[`echo ${run_tr_a[0]}-1 | bc`]}
minoutrun_p=${runs[`echo ${run_tr_p[0]}-1 | bc`]}
minouttr_a=${run_tr_a[1]}
minouttr_p=${run_tr_p[1]}
echo "min outlier: run $minoutrun_a, TR $minouttr_a" | tee out.min_outlier_a.txt
echo "min outlier: run $minoutrun_p, TR $minouttr_p" | tee out.min_outlier_p.txt




## ==================== despike =================#
## 3dDespike uses a smooth-then-mad based time domaim method
## Might not by very helpful for k-space spikes.
## This should be done before ricor/tshift operation to prevent spikes to spread.
cd $output_dir
for run in ${runs[@]} ; do
    3dDespike -NEW -nomask -prefix active_despike_${run}.nii -overwrite active_${func}_${run}.nii
    3dDespike -NEW -nomask -prefix passive_despike_${run}.nii -overwrite passive_${func}_${run}.nii
done



## ==================== Motion correction =================#
cd $output_dir
# Estimate volreg parameters
for run in ${runs[@]} ; do
    # Register each volume to the base
    3dvolreg -verbose -zpad 2 -base active_despike_01.nii'[0]' \
        -prefix rm.active_volreg_${run}.nii -overwrite \
        -1Dfile dfile.active_${run}.1D \
        -1Dmatrix_save mat.active_$run.vr.aff12.1D \
        active_despike_${run}.nii
done
for run in ${runs[@]} ; do
    # Register each volume to the base
    3dvolreg -verbose -zpad 2 -base active_despike_01.nii'[0]' \
        -prefix rm.passive_volreg_${run}.nii -overwrite \
        -1Dfile dfile.passive_${run}.1D \
        -1Dmatrix_save mat.passive_$run.vr.aff12.1D \
        passive_despike_${run}.nii
done

# Tcat all runs and get a mean ssfp image
3dTstat -prefix rm.mean_active.nii -overwrite \
    -mean rm.active_volreg_'??'.nii
3dTstat -prefix rm.mean_passive.nii -overwrite \
    -mean rm.passive_volreg_'??'.nii
# Concatenate head motion parameters of individual runs into a single time series
cat dfile.active_*.1D > dfile_active.1D
cat dfile.passive_*.1D > dfile_passive.1D
1dplot -volreg -sepscl dfile_active.1D
1dplot -volreg -sepscl dfile_passive.1D

## ==================== align T1 to mean ssfp =================#
    # -orig_vol: don't normalize voxel intensity; -input is required
    # T1+orig vs T1_$func+orig
    align_src=T1_${func}.nii
    # Estimate coregister transform from anat without skull to EPI registration base
    align_epi_anat.py -anat2epi \
        -anat T1_${func}.nii -anat_has_skull no \
        -epi rm.mean_active.nii -epi_base 0 \
        -epi_strip 3dAutomask \
        -volreg off -tshift off \
        -suffix _al -overwrite
#Convert to nifti:
3dAFNItoNIFTI T1_${func}_al+orig.BRIK

## ==================== apply transforms all at once =================#
## Concatenate multiple transforms, and apply/resample once
## -nwarp 'MNI_WARP.nii volreg.aff12.1D blip_WARP.nii' is apply from right to left.
## That is, first blip, then volreg, finally MNI. See 3dNwarpApply for details.
for run in ${runs[@]} ; do
    # Concatenate blip/volreg
    # The transforms are applied in backward order: bottom to top, right to left2
    cat_matvec -ONELINE \
        mat.active_${run}.vr.aff12.1D > mat.active_${run}.warp.aff12.1D 
    cat_matvec -ONELINE \
        mat.passive_${run}.vr.aff12.1D > mat.passive_${run}.warp.aff12.1D
done

for run in ${runs[@]} ; do
      # Apply concatenated transform, and resample only once
    3dAllineate -input active_despike_${run}.nii \
        -1Dmatrix_apply mat.active_${run}.warp.aff12.1D \
        -prefix rm.nomask.active_${run}.nii -overwrite 
    3dAllineate -input passive_despike_${run}.nii \
        -1Dmatrix_apply mat.passive_${run}.warp.aff12.1D \
        -prefix rm.nomask.passive_${run}.nii -overwrite 
done


## ==================== mask =================#
# Create data extents mask of all runs
# This is a mask of voxels that have valid data after rotation at every TR
for run in ${runs[@]} ; do
    # Create a 3D+t all-1 dataset to mask the extents of the warp
    3dcalc -a active_despike_${run}.nii -expr 1 \
        -prefix rm.all1.active_$run.nii -overwrite 
    3dcalc -a passive_despike_${run}.nii -expr 1 \
        -prefix rm.all1.passive_$run.nii -overwrite 
done

for run in ${runs[@]} ; do
    # Register the all-1 dataset for extents masking
    # -nwarp "mat.$func$run.warp.aff12.1D  " is an error
        3dAllineate -input rm.all1.active_$run.nii \
            -1Dmatrix_apply mat.active_${run}.warp.aff12.1D \
            -interp NN -quiet \
            -prefix rm.all1.active_$run.nii -overwrite 
        3dAllineate -input rm.all1.passive_$run.nii \
            -1Dmatrix_apply mat.passive_${run}.warp.aff12.1D \
            -interp NN -quiet \
            -prefix rm.all1.passive_$run.nii -overwrite
done

# Compute intersection across runs
3dTstat -prefix mask.active_extents.nii -overwrite \
    -min rm.all1.active_'??'.nii
3dTstat -prefix mask.passive_extents.nii -overwrite \
    -min rm.all1.passive_'??'.nii
# Create brain mask of all runs
for run in ${runs[@]} ; do
    # Create a brain mask from ssfp time series
    3dAutomask -dilate 1 \
        -prefix rm.brain.active_$run.nii -overwrite \
        rm.nomask.active_${run}.nii 
    3dAutomask -dilate 1 \
        -prefix rm.brain.passive_$run.nii -overwrite \
        rm.nomask.passive_${run}.nii 
done

# Compute union across runs
3dTstat -prefix mask.active_brain.nii -overwrite \
    -max rm.brain.active_'??'.nii
3dTstat -prefix mask.passive_brain.nii -overwrite \
    -max rm.brain.passive_'??'.nii

# Apply extents mask to functional data
# Zero out any time series with missing data
for run in ${runs[@]} ; do
    3dcalc -a rm.nomask.active_${run}.nii  -b mask.active_extents.nii \
        -expr 'a*b' -prefix active_volreg_${run}.nii -overwrite
    3dcalc -a rm.nomask.passive_${run}.nii  -b mask.passive_extents.nii \
        -expr 'a*b' -prefix passive_volreg_${run}.nii -overwrite
done


# Tcat all runs and get a mean image with high SNR after motion correction
3dTstat -prefix mean_active.nii -overwrite \
    -mean active_volreg_'??'.nii
3dTstat -prefix mean_passive.nii -overwrite \
    -mean passive_volreg_'??'.nii

 

 #Now run statsjob on these preprocessed files.