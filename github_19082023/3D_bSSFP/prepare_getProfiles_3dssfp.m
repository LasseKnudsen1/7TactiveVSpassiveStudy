clear; clc; close all
subjects=[1];
counter=0;
for subj=subjects
    counter=counter+1;
for condition=["active","passive"]
ROI='indexfingerROI_ap_corrected';
clearvars -except subj condition ROI counter sliceOfInterest
%% Set path

analysisDir=['/Users/au686880/Desktop/3dssfp_APstudy/analyzed/S' sprintf('%02d',subj)];
cd(analysisDir)

%% Load files:
%Load deltas:
deltas=single(spm_read_vols(spm_vol([analysisDir '/deltas_' sprintf('%s',condition) '_resample.nii'])));

%Load layers and mask:
depthmap=single(spm_read_vols(spm_vol([analysisDir '/depth_map_resample_equidist.nii'])));
mask=single(spm_read_vols(spm_vol([analysisDir '/' ROI '.nii'])));


%% Mask and reshape
%Reshape to vector format:
s=size(deltas);
deltas=reshape(deltas,s(1)*s(2)*s(3),s(4));
depthmap=reshape(depthmap,s(1)*s(2)*s(3),1);
mask=reshape(mask,s(1)*s(2)*s(3),1);

%Find indices of voxels within ROI and remove all voxels outside ROI 
%(we only use depth values 0-1, negative is more wm than gray and above 1 is more csf than gray):
idx=find(mask>0 & depthmap>0 & depthmap<=1);
deltas=deltas(idx,:);
depthmap=depthmap(idx,1);
mask=mask(idx,1);

%% Save
outputDir='/Users/au686880/Desktop/3dssfp_APstudy/groupAnalysis';
outputName=[outputDir '/profiles_S' char(num2str(subj)) '_' char(condition) '_' ROI '.mat'];
save(outputName)
end
end