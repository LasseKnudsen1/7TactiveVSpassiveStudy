%Pipeline for 7T VASO AP L-fMRI study, writing start 06-04-2022.
%This is heavily inspired by Renzo Hubers pipeline in: https://www.youtube.com/watch?v=VUDi2Iskzz4&t=614s&ab_channel=LayerfMRI
%% Set, check and move to path
clc; clear; close all
%Input subject information:
SOI=[8]; %Subject of interest
SC(8)="passive"; %start condition

%Create structure with path for current subject and sessions:
counter=1;
for i=SOI
    
    current_study=sprintf('VASO_AP_%04d',SOI(counter));
    subjstruc(i).rootDir=['/Users/au686880/Desktop/' current_study];
    subjstruc(i).resultsDir=['/Users/au686880/Desktop/' current_study '/results'];
    subjstruc(i).analysisDir=['/Users/au686880/Desktop/' current_study '/results/analysis'];
    subjstruc(i).startCondition=SC(i);
    
    counter=counter+1;
end 

%% Write starting condition to text file
%This is needed in some cases when using scripts outside matlab, first time used in
%prelude script for spatial unwrapping of phase. 
for i=SOI
cd(subjstruc(i).rootDir)

file_id=fopen('startCondition.txt','w+t');
fprintf(file_id,sprintf('%s',subjstruc(i).startCondition));
fclose(file_id); %Close file when done. 
end

%% DICOM Conversion
%Use convertjob which is saved in each subjects folder, and run createT1.sh
%to get NIFTI files. 

%% Deoblique files
%FIRST CREATE MOMA FOR SOI
%Then run deoblique.sh
%% Set origin of MP2RAGE
%use SPM checkreg to set origin of MP2RAGE to AC and change this for all
% other images as well, which is needed for cat12 to work properly. 

%Then run:
for i=SOI
cd(subjstruc(i).resultsDir)
mkdir ./originMatricies
movefile ./*.mat ./originMatricies
movefile ./T1/*.mat ./originMatricies
end

%% get separate INV1 and INV2 files
clc; close all
clearvars -except subjstruc SOI

for i=SOI
cd(subjstruc(i).resultsDir)
getSeparateINV1INV2('active',1)
getSeparateINV1INV2('active',2)
getSeparateINV1INV2('passive',1)
getSeparateINV1INV2('passive',2)
end
%% motion correction
clc; close all
clearvars -except subjstruc SOI
spm_figure('GetWin','Graphics');

%Set whether subject starts active or passive:
%Set path to file that should be motion corrected and moma.nii
for i=SOI
cd(subjstruc(i).resultsDir)
if subjstruc(i).startCondition=="active"
    moma_file='moma.nii';
    run1_INV1='noNORDIC_active_INV1_01.nii';
    run2_INV1='noNORDIC_active_INV1_02.nii';
    run3_INV1='noNORDIC_passive_INV1_01.nii';
    run4_INV1='noNORDIC_passive_INV1_02.nii';
    
    run1_INV2='noNORDIC_active_INV2_01.nii';
    run2_INV2='noNORDIC_active_INV2_02.nii';
    run3_INV2='noNORDIC_passive_INV2_01.nii';
    run4_INV2='noNORDIC_passive_INV2_02.nii';
elseif subjstruc(i).startCondition=="passive"
    moma_file='moma.nii';
    run1_INV1='noNORDIC_passive_INV1_01.nii';
    run2_INV1='noNORDIC_passive_INV1_02.nii';
    run3_INV1='noNORDIC_active_INV1_01.nii';
    run4_INV1='noNORDIC_active_INV1_02.nii';
    
    run1_INV2='noNORDIC_passive_INV2_01.nii';
    run2_INV2='noNORDIC_passive_INV2_02.nii';
    run3_INV2='noNORDIC_active_INV2_01.nii';
    run4_INV2='noNORDIC_active_INV2_02.nii';
end

jobfile = {'/Users/au686880/Desktop/fMRI_analysis/scripts/ActiveVsPassive/VASO_AP_scripts/realignfunc_job.m'};
jobs = repmat(jobfile,1,1);
inputs = cell(9,1);
inputs{1,1} = cellstr(moma_file);

inputs{2,1} = cellstr(run1_INV1);
inputs{3,1} = cellstr(run2_INV1);
inputs{4,1} = cellstr(run3_INV1);
inputs{5,1} = cellstr(run4_INV1);

inputs{6,1} = cellstr(run1_INV2);
inputs{7,1} = cellstr(run2_INV2);
inputs{8,1} = cellstr(run3_INV2);
inputs{9,1} = cellstr(run4_INV2);

spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
end

%% Check motion parameters INV1 and INV2
%If the parameters for INV1 and INV2 are not similar then we need to change
%moco mask or try aligning to mean instead of first image. 
clc; close all
clearvars -except subjstruc SOI

%Set whether subject starts active or passive:
%Set path to file that should be motion corrected and moma.nii
for i=SOI
cd(subjstruc(i).resultsDir)
conditionNames=["active","passive"];
runsPerCondition=2;
startCondition=subjstruc(i).startCondition;
subjID=i;
numVolRun=144;

checkMotionParameters(conditionNames,runsPerCondition,startCondition,subjID,numVolRun)
end


%% Compute T1_weighted from functional images and coreg MP2RAGE to this
%Use getT1weighted.sh first

%Then use: coregMP2RAGEtoEPI.sh

%% Make BOLD corrected VASO timeseries
%Use BOCOfinal.sh. 


%% Statsjob trialAV
clc; close all
clearvars -except subjstruc SOI
for i=SOI
cd(subjstruc(i).resultsDir)
runsPerCondition=2;
discardFirstVols=2;
num_TRperBlock=6;

statsjobVASO_trialAV("noNORDIC_active",runsPerCondition,discardFirstVols,num_TRperBlock)
statsjobVASO_trialAV("noNORDIC_passive",runsPerCondition,discardFirstVols,num_TRperBlock)

%Move files
movefile ./delta*.nii ./analysis
end
