clear; clc; close all
subjects=["S01" "S02_ap1"];
counter=0;
for subj=subjects
    counter=counter+1;
for condition=["active","passive"]
ROI='indexfingerROI';
clearvars -except subj condition ROI counter sliceOfInterest
%% Set path

analysisDir=['/Users/au686880/Desktop/2dssfp_APstudy/analyzed/' sprintf('%s',subj)];
cd(analysisDir)

%% Load files:
%Load deltas:
deltas=single(spm_read_vols(spm_vol([analysisDir '/deltas_' sprintf('%s',condition) '.nii'])));
delta_ap=single(spm_read_vols(spm_vol([analysisDir '/mean_delta_ap.nii'])));

%Load layers and mask:
depthmap=single(spm_read_vols(spm_vol([analysisDir '/segmentation_metric_equidist.nii'])));
mask=single(spm_read_vols(spm_vol([analysisDir '/' ROI '.nii'])));


%% Mask and reshape
%Reshape to vector format:
s=size(deltas);
deltas=reshape(deltas,s(1)*s(2)*s(3),s(4));
delta_ap=reshape(delta_ap,s(1)*s(2)*s(3),1);
depthmap=reshape(depthmap,s(1)*s(2)*s(3),1);
mask=reshape(mask,s(1)*s(2)*s(3),1);

%Find indices of voxels within ROI and remove all voxels outside ROI:
idx=find(mask>0 & depthmap>0 & abs(delta_ap)<4);
deltas=deltas(idx,:);
depthmap=depthmap(idx,1);
mask=mask(idx,1);

%% Save
outputDir='/Users/au686880/Desktop/2dssfp_APstudy/groupAnalysis';
outputName=[outputDir '/profiles_' char(num2str(subj)) '_' char(condition) '_' ROI '.mat'];
save(outputName)
end
end