Analysis code used in "The laminar pattern of proprioceptive activation in human primary motor cortex" (uploaded on git 19082023,and updated on 18-08-2024.).

Preprocessing code is in files named by "preprocessing" or "pipeline". getProfile scripts contain code to generate figures and statistics. 

Note, code to run blurring simulation (3d-bssfp) is in "blurringSimulation_2kernels.m", and code to run BOLD draining correction with spatial deconvolution is embedded in getProfilesVASO.m. (18082024: 3d-bssfp refers to older version of the manuscript. It is not included in recent version as it was used to address a different research question).

Note that our naming convention of inversions is weird here: INV1 refers to not-blood-nulled, and INV2 refers to blood-nulled volumes. This is because an extra nulled-volume was discarded so the first volume in our time series is not-nulled. This is relevant, e.g., in the BOLD correction step. 

If questions or similar, please feel free to contact Lasse Knudsen at lasse.knudsen96@gmail.com
