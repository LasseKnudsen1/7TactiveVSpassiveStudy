clear; clc; close all
subjects=[1 2 3 4 5 6 7 8 9 10];
sliceOfInterest=[19,17,20,15,16,20,17,16,1415,15]; %ROI slice
counter=0;
for subj=subjects
    counter=counter+1;
for condition=["active","passive"]
ROI='indexfingerROI';
clearvars -except subj condition ROI counter sliceOfInterest
%% Set path

analysisDir=['/Volumes/SeagateAPstudy/activeVSpassive_study/analyzed_VASO/VASO_AP_' sprintf('%04d',subj) '/results/analysis'];
cd(analysisDir)

%% Load files:
%Load deltas:
deltas_noNORDIC_VASO=single(spm_read_vols(spm_vol([analysisDir '/deltasAndtvals/deltas_noNORDIC_' sprintf('%s',condition) '_VASO_resample.nii'])));

deltas_noNORDIC_BOLD=single(spm_read_vols(spm_vol([analysisDir '/deltasAndtvals/deltas_noNORDIC_' sprintf('%s',condition) '_BOLD_resample.nii'])));

%Load trialAV:
trialAV_noNORDIC_VASO=single(spm_read_vols(spm_vol([analysisDir '/delta_noNORDIC_' sprintf('%s',condition) '_VASO_trialAV_resample.nii'])));

trialAV_noNORDIC_BOLD=single(spm_read_vols(spm_vol([analysisDir '/delta_noNORDIC_' sprintf('%s',condition) '_BOLD_trialAV_resample.nii'])));

%Load layers and mask:
depthmap=single(spm_read_vols(spm_vol([analysisDir '/segmentation_' num2str(sliceOfInterest(counter))  '_metric_equidist.nii'])));
mask=single(spm_read_vols(spm_vol([analysisDir '/' ROI '.nii'])));


%% Mask and reshape
%Reshape to vector format:
s=size(deltas_noNORDIC_VASO);
deltas_noNORDIC_VASO=reshape(deltas_noNORDIC_VASO,s(1)*s(2)*s(3),s(4));
deltas_noNORDIC_BOLD=reshape(deltas_noNORDIC_BOLD,s(1)*s(2)*s(3),s(4));

trialAV_noNORDIC_VASO=reshape(trialAV_noNORDIC_VASO,s(1)*s(2)*s(3),1);
trialAV_noNORDIC_BOLD=reshape(trialAV_noNORDIC_BOLD,s(1)*s(2)*s(3),1);

depthmap=reshape(depthmap,s(1)*s(2)*s(3),1);
mask=reshape(mask,s(1)*s(2)*s(3),1);

%Find indices of voxels within ROI and remove all voxels outside ROI:
idx=find(mask>0 & depthmap>0);
deltas_noNORDIC_VASO=deltas_noNORDIC_VASO(idx,:);
deltas_noNORDIC_BOLD=deltas_noNORDIC_BOLD(idx,:);

trialAV_noNORDIC_VASO=trialAV_noNORDIC_VASO(idx,1);
trialAV_noNORDIC_BOLD=trialAV_noNORDIC_BOLD(idx,1);
depthmap=depthmap(idx,1);
mask=mask(idx,1);

%% Save
outputDir='/Users/au686880/Desktop/VASO_APstudy/groupAnalysis';
outputName=[outputDir '/profiles_S' char(num2str(subj)) '_' char(condition) ROI '.mat'];
save(outputName,...
    's','idx','mask','depthmap',...
    'analysisDir','outputDir','outputName',...
    'deltas_noNORDIC_VASO','deltas_noNORDIC_BOLD', ...
    'trialAV_noNORDIC_VASO','trialAV_noNORDIC_BOLD')
end
end