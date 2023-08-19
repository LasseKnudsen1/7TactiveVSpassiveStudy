clear; clc; close all
%This script takes the preprocessed files and computes file containing delta per trial. 
%1 block refers to 1 ON or 1 rest block, so for every trial we have 2
%blocks. Num Blocks corresponds to 1 run.
%discardFirstVols refers to how many transition volumes should be
%removed. If the value is 2 and TR=6 then it
%corresponds to removing the first 12 seconds of each block.
%num_blocks refers to number of blocks in 1 run. 
subjects=["S01", "S02_ap1"];
runsPerCondition=[4 4];
startCondition=["passive", "active"];
suffix='';
discardFirstVols=4;
num_TRperBlock=10;
num_blocks=12;
rootDir='/Users/au686880/Desktop/2dssfp_APstudy/analyzed';

%% Load files:
subjcount=1;
for subj=subjects
    direc=[rootDir '/' sprintf('%s',subj) '/'];
    %Get size of data:
    tmp_info=niftiinfo([direc 'ssfp01_volreg.nii']);
    s=tmp_info.ImageSize;
    %Load data into variable containing all runs for each condition:
    for run=1:runsPerCondition(subjcount)*2
        %Full timeseries:
        info=niftiinfo([direc sprintf('ssfp%02d_volreg%s.nii',run,suffix)]);
        Y_temp=niftiread([direc sprintf('ssfp%02d_volreg%s.nii',run,suffix)]);
        
        %Reshape and store runs in same data matrix
        s=size(Y_temp);
        Y(run,:,:)=single(reshape(Y_temp,s(1)*s(2)*s(3),s(4)));
    end

if startCondition(subjcount)=="active"
    Y_active=Y(1:runsPerCondition(subjcount),:,:);
    Y_passive=Y(runsPerCondition(subjcount)+1:runsPerCondition(subjcount)*2,:,:);
elseif startCondition(subjcount)=="passive"
    Y_passive=Y(1:runsPerCondition(subjcount),:,:);
    Y_active=Y(runsPerCondition(subjcount)+1:runsPerCondition(subjcount)*2,:,:);
end

%First get mean of each block (no matter if on or off block) where 
%transition vols have been removed: 
for run=1:runsPerCondition(subjcount)
lower=discardFirstVols+1;
upper=num_TRperBlock;
for i=1:num_blocks
    block_mean_active(run,:,i)=mean(Y_active(run,:,lower:upper),3);
    block_mean_passive(run,:,i)=mean(Y_passive(run,:,lower:upper),3);
    lower=lower+num_TRperBlock;
    upper=upper+num_TRperBlock;
end
end

%Divide into on and off(rest) blocks assuming that paradigm started by
%rest:
rest_blocks_active=[];
ON_blocks_active=[];
rest_blocks_passive=[];
ON_blocks_passive=[];

for run=1:runsPerCondition(subjcount)
rest_blocks_active=[rest_blocks_active squeeze(block_mean_active(run,:,1:2:end))];
rest_blocks_passive=[rest_blocks_passive squeeze(block_mean_passive(run,:,1:2:end))];

ON_blocks_active=[ON_blocks_active squeeze(block_mean_active(run,:,2:2:end))];
ON_blocks_passive=[ON_blocks_passive squeeze(block_mean_passive(run,:,2:2:end))];
end


%Get percent change for each block:
deltas_active=(ON_blocks_active-rest_blocks_active)./rest_blocks_active;
deltas_passive=(ON_blocks_passive-rest_blocks_passive)./rest_blocks_passive;

%Multiply by 100
deltas_active=deltas_active*100;
deltas_passive=deltas_passive*100;

%Get mean delta and t-value across blocks:
num_totalTrials=(num_blocks/2)*runsPerCondition(subjcount); %Total number of trials across runs

mean_delta_active=mean(deltas_active,2);
mean_delta_passive=mean(deltas_passive,2);

tval_active=mean(deltas_active,2) ./ (std(deltas_active,[],2)/sqrt(num_totalTrials));
tval_passive=mean(deltas_passive,2) ./ (std(deltas_passive,[],2)/sqrt(num_totalTrials));

%Reshape back:
deltas_active=reshape(deltas_active,s(1),s(2),s(3),num_totalTrials);
deltas_passive=reshape(deltas_passive,s(1),s(2),s(3),num_totalTrials);

mean_delta_active=reshape(mean_delta_active,s(1),s(2),s(3),1);
mean_delta_passive=reshape(mean_delta_passive,s(1),s(2),s(3),1);

tval_active=reshape(tval_active,s(1),s(2),s(3),1);
tval_passive=reshape(tval_passive,s(1),s(2),s(3),1);

%Write files:
%deltas:
info_deltas_active=info;
info_deltas_active.ImageSize(4)=size(deltas_active,4);
info_deltas_active.Datatype='single';
niftiwrite(deltas_active,[direc '/deltas_active' suffix '.nii'],info_deltas_active)

info_deltas_passive=info;
info_deltas_passive.ImageSize(4)=size(deltas_passive,4);
info_deltas_passive.Datatype='single';
niftiwrite(deltas_passive,[direc '/deltas_passive' suffix '.nii'],info_deltas_passive)


%mean_delta and tval:
V_active=spm_vol([direc 'deltas_active' suffix '.nii']);
V_active=V_active(1);
V_active.fname=[direc '/mean_delta_active' suffix '.nii'];
spm_write_vol(V_active,mean_delta_active);

V_active.fname=[direc '/t_active' suffix '.nii'];
spm_write_vol(V_active,tval_active);

V_passive=spm_vol([direc 'deltas_passive' suffix '.nii']);
V_passive=V_passive(1);
V_passive.fname=[direc '/mean_delta_passive' suffix '.nii'];
spm_write_vol(V_passive,mean_delta_passive);

V_passive.fname=[direc '/t_passive' suffix '.nii'];
spm_write_vol(V_passive,tval_passive);



subjcount=subjcount+1;
end