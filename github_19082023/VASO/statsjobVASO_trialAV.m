function statsjobVASO_trialAV(condition,runsPerCondition,discardFirstVols,num_TRperBlock)
%This function computes delta (percent signal change) maps for VASO and BOLD

%Load data into cell containing all runs of current condition, both for VASO and BOLD:
counter=0;
for run=1:runsPerCondition
    counter=counter+1;
    info_VASO_temp=niftiinfo(sprintf('./trialAV/%s_VASO_trialAV_0%d.nii',condition,run));
    Y_VASO_temp=niftiread(sprintf('./trialAV/%s_VASO_trialAV_0%d.nii',condition,run));
    
    info_BOLD_temp=niftiinfo(sprintf('./trialAV/%s_BOLD_trialAV_0%d.nii',condition,run));
    Y_BOLD_temp=niftiread(sprintf('./trialAV/%s_BOLD_trialAV_0%d.nii',condition,run));
    
    %Reshape
    s=size(Y_VASO_temp);
    Y_VASO(counter,:,:)=reshape(Y_VASO_temp,s(1)*s(2)*s(3),s(4));
    Y_BOLD(counter,:,:)=reshape(Y_BOLD_temp,s(1)*s(2)*s(3),s(4));
end


%Average across runs before computing percent change:
Y_VASO_avg=squeeze(mean(Y_VASO,1));
Y_BOLD_avg=squeeze(mean(Y_BOLD,1));

%First get mean of each block (no matter if on or off block) where 
%transition vols have been removed: 
lower=discardFirstVols+1;
upper=num_TRperBlock;
for i=1:2
    block_mean_VASO(:,i)=mean(Y_VASO_avg(:,lower:upper),2);
    block_mean_BOLD(:,i)=mean(Y_BOLD_avg(:,lower:upper),2);
    lower=lower+num_TRperBlock;
    upper=upper+num_TRperBlock;
end

%Divide into on and off(rest) blocks assuming that paradigm started by
%rest:
rest_blocks_VASO=block_mean_VASO(:,1);
ON_blocks_VASO=block_mean_VASO(:,2);

rest_blocks_BOLD=block_mean_BOLD(:,1);
ON_blocks_BOLD=block_mean_BOLD(:,2);


%Get percent change:
delta_VASO=(ON_blocks_VASO-rest_blocks_VASO)./rest_blocks_VASO;
delta_VASO=-1*delta_VASO;

delta_BOLD=(ON_blocks_BOLD-rest_blocks_BOLD)./rest_blocks_BOLD;

%Multiply by 100
delta_VASO=delta_VASO*100;
delta_BOLD=delta_BOLD*100;


%Reshape back:
delta_VASO=reshape(delta_VASO,s(1),s(2),s(3),1);
delta_BOLD=reshape(delta_BOLD,s(1),s(2),s(3),1);



%Write files:
V_VASO=spm_vol(sprintf('./trialAV/%s_VASO_trialAV_01.nii',condition));
V_VASO=V_VASO(1);
V_VASO.fname=sprintf('delta_%s_VASO_trialAV.nii',condition);
spm_write_vol(V_VASO,delta_VASO);

V_BOLD=spm_vol(sprintf('./trialAV/%s_BOLD_trialAV_01.nii',condition));
V_BOLD=V_BOLD(1);
V_BOLD.fname=sprintf('delta_%s_BOLD_trialAV.nii',condition);
spm_write_vol(V_BOLD,delta_BOLD);
end