#########========= setup parameters ==============############
root_dir=/Volumes/VERBATIM\?HD/fmri_data/actpas_experiment/analyzed_2dssfp/S02_2dssfp
output_dir=$root_dir/results_ap1
raw_dir=${root_dir}/raw_fmri_ap1
runs=(`count 1 8 -digits 2`)
T1num=(`count 1 11 -digits 2`)
func="ssfp"
n_dummys=4
TR=3

mkdir -p $output_dir


########=========create T1 ==========############
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
  file=`ls $raw_dir/T1${num}/*IMA | sed -n '1p'`
  suffix=`dicom_hdr ${file} | grep 'ID Series Description' | awk -F // '{print $3}' | sed s/'t1w_mp2rage_0.70iso_'/''/g`
  cdAndDimon ${raw_dir}/T1${num} ${output_dir} T1_${suffix} &
done 
wait

#denoise T1:
cd $output_dir
3dSkullStrip -orig_vol -prefix T1_250V_INV2_ND_ns.nii -overwrite -input T1_250V_INV2_ND+orig -overwrite
3dAutomask -dilate 1 -prefix T1mask -overwrite T1_250V_INV2_ND_ns.nii
3dcalc -a T1mask+orig -b T1_250V_UNI_Images+orig -expr 'a*b' -prefix T1.nii -overwrite


#########=========create ssfp========== ##########
for run in ${runs[@]} ; do 
cd ${raw_dir}/ssfp$run
uniq_images *.IMA > uniq_image_list.txt
Dimon -infile_list uniq_image_list.txt          \
      -gert_create_dataset                   \
      -gert_to3d_prefix ssfp$run               \
      -gert_outdir $output_dir                \
      -dicom_org     \
      -use_obl_origin       \
      -save_details Dimon.details      
done      


cd $output_dir



######========= deoblique the T1 to ssfp ==============#####

3dTcat -prefix ssfp -overwrite ssfp01+orig'[0]'
3dwarp -oblique2card -prefix T1.nii -overwrite T1.nii
3dwarp -card2oblique ssfp+orig -prefix T1.nii -overwrite  T1.nii
3dAutobox -prefix T1.nii -input T1.nii -overwrite
3drefit -deoblique T1.nii


##deoblique the ssfp data.
for run in ${runs[@]} ; do 
	3drefit -deoblique ssfp${run}+orig 
done


##### ======tcat remove the dummy scan###### 
#minimize the effects due to the scanner onset.###
for run in ${runs[@]} ; do 
	3dTcat -prefix pb00.ssfp$run.tcat ssfp${run}+orig'['$n_dummys'..$]' -overwrite
done
    
  
# =============== auto block: outcount ================
# data check: compute outlier fraction for each volume
touch out.pre_ss_ssfp_warn.txt
for run in ${runs[@]} ; do 
 
    3dToutcount -automask -fraction -polort 3 -legendre                     \
                pb00.ssfp$run.tcat+orig > outcount.ssfp$run.1D            
    
    # outliers at TR 0 might suggest pre-steady state TRs
    if [ `1deval -a outcount.ssfp$run.1D"{0}" -expr "step(a-0.4)"` ] ; then
        echo "** TR #0 outliers: possible pre-steady state TRs in run $run" \
            >> out.pre_ss_ssfp_warn.txt
    fi

done

# catenate outlier counts into a single time series
cat outcount.ssfp*.1D > outcount_ssfpall.1D

# get run number and TR index for minimum outlier volume
tr_counts=(120 120 120 120 120 120 120 120)
minindex=`3dTstat -argmin -prefix - outcount_ssfpall.1D\'`
ovals=( `1d_tool.py -set_run_lengths $tr_counts                       \
                          -index_to_run_tr $minindex` )
# save run and TR indices for extraction of vr_base_min_outlier
minoutrun=$ovals[1]
minouttr=$ovals[2]
echo "min outlier: run $minoutrun, TR $minouttr" | tee out.min_outlier.txt


# ================================= tshift =================================
# time shift data so all slice timing is the same (not needed for single-slice data)
for run in ${runs[@]} ; do 
    3dTcat -prefix pb01.ssfp$run.tshift -overwrite pb00.ssfp$run.tcat+orig
    # 3dTshift -tzero 0 -quintic -prefix pb01.ssfp$run.tshift \
    #          pb00.ssfp$run.tcat+orig -overwrite            
done
#x smaller than 55 and larger than 22
#y smaller than 20 and larger han -10
for run in ${runs[@]} ; do 
    3dcalc -prefix pb01.ssfp$run.tshift -a pb01.ssfp$run.tshift+orig -expr "a*step(45-x)*step(x-18)" -overwrite 
  	3dcalc -prefix pb01.ssfp$run.tshift -a pb01.ssfp$run.tshift+orig -expr "a*step(y+18)*step(5-y)" -overwrite
done 


3dTcat -prefix mask_volreg -overwrite pb01.ssfp01.tshift+orig"[0]"

# ======extract volreg registration base=============##################
3dbucket -prefix vr_base pb01.ssfp01.tshift+orig"[0]" -overwrite

3dcopy vr_base vr_base_re


######============== Volreg =======================#####
# register and warp
for run in ${runs[@]} ; do 
     3dAllineate -base vr_base+orig. \
            -cost lpa -warp shift_rotate -parfix 3 0 -parfix 5 0 -parfix 6 0 \
            -prefix rm.volreg.ssfp$run -overwrite \
            -1Dfile dfile.ssfp$run.1D \
            -1Dmatrix_save mat.ssfp$run.vr.aff12.1D \
            -input  pb01.ssfp$run.tshift+orig.



	# create an all-1 dataset to mask the extents of the warp
	3dcalc -overwrite -a pb01.ssfp$run.tshift+orig -expr 1   \
	-prefix rm.ssfp.all1  -overwrite

	# catenate xforms
	cat_matvec -ONELINE                                 \
	mat.ssfp$run.vr.aff12.1D > mat.r$run.warp.aff12.1D

	3dAllineate -base vr_base+orig                              \
	-input pb01.ssfp$run.tshift+orig                 \
	-1Dmatrix_apply mat.r$run.warp.aff12.1D             \
	-master vr_base_re+orig.                           \
	-prefix rm.ssfp.nomask.ssfp$run

	3dAllineate -base vr_base+orig                             \
	-input rm.ssfp.all1+orig                             \
	-1Dmatrix_apply mat.r$run.warp.aff12.1D            \
	-master vr_base_re+orig.                   \
	-prefix rm.ssfp.1.ssfp$run

	# make an extents intersection mask of this run 3d＋t dataset all1 mask
	3dTstat -overwrite -min -prefix rm.ssfp.min.ssfp$run rm.ssfp.1.ssfp$run+orig

done

3dTcat -prefix ssfp_All.rm rm.ssfp.nomask.ssfp*+orig.HEAD -overwrite
3dTstat -prefix ssfp.mean -mean  ssfp_All.rm+orig -overwrite
rm ssfp_All.rm+orig*
3dAutomask -prefix brainMask ssfp.mean+orig  -overwrite

# make a single file of registration params
cat dfile.*.1D > dfile.ssfp.1D

# ------------------- mask（voxels）----------------
# create the extents mask: mask_ssfp_extents+tlrc
# (this is a mask of voxels that have valid data at every TR)
3dMean -datum short -prefix rm.ssfp.mean  rm.ssfp.min.ssfp*.HEAD -overwrite
3dcalc -a rm.ssfp.mean+orig -expr 'step(a-0.999)' -prefix mask_ssfp_extents -overwrite


# and apply the extents mask to the ssfp data 
# (delete any time series with missing data)
for run in ${runs[@]} ; do 
    3dcalc -a rm.ssfp.nomask.ssfp$run+orig -b mask_ssfp_extents+orig \
          -expr 'a*b' -prefix ssfp${run}_volreg.nii -overwrite
           
done


# =================================align T1 to ssfp.mean==================================
align_epi_anat.py -cost lpc \
     -dset1to2 -dset1 T1.nii -dset2 ssfp.mean_3layers.nii \
     -dset1_strip None -dset2_strip None \
     -volreg_method 3dvolreg \
     -suffix _al_ssfp -overwrite

align_epi_anat.py -cost lpc -master_anat ssfp.mean.nii   \
     -dset1to2 -dset1 T1.nii -dset2 ssfp.mean_3layers.nii \
     -dset1_strip None -dset2_strip None \
     -volreg_method 3dvolreg \
     -suffix _al_ssfp_resample -overwrite


#Now run statsjob on these preprocessed files. 








