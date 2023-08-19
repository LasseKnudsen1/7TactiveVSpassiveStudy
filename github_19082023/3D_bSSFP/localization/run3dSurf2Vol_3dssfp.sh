3dSurf2Vol  -spec ../SUMAhd/${subj}_lh.spec \
			-surf_A ../SUMAhd/lh.smoothwm \
	   	    -surf_B ../SUMAhd/lh.pial  \
			-sv  ./${subj}_SurfVol_Alnd_Exp.nii  \
			-gridparent ${outputDir}/T1_bssfp_al_resample.nii  \
			-map_func max  \
		    -f_index points  \
		    -f_steps 30      \
			-f_p1_fr -0.1 -f_pn_fr 0   \
		    -sdata indexfingerROI_ap.niml.dset   \
			-prefix indexfingerROI_ap.nii       \
			-overwrite


3dSurf2Vol  -spec ../SUMAhd/${subj}_lh.spec \
			-surf_A ../SUMAhd/lh.smoothwm \
	   	    -surf_B ../SUMAhd/lh.pial  \
			-sv  ./${subj}_SurfVol_Alnd_Exp.nii  \
			-gridparent ${outputDir}/T1_bssfp_al_resample.nii  \
			-map_func max  \
		    -f_index points  \
		    -f_steps 30      \
			-f_p1_fr -0.1 -f_pn_fr 0   \
		    -sdata indexfingerROI_active.niml.dset   \
			-prefix indexfingerROI_active.nii       \
			-overwrite