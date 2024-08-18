
%% Load prepared variables into data structure
clear; clc; close all;
subjects=["S01" "S02_ap1"];
runsPerCondition=[4 4];
num_trialsPerRun=6;
num_subjects=numel(subjects);
num_trials=runsPerCondition*num_trialsPerRun;
ROI='indexfingerROI';
counter=1;
for subject=subjects
%active
load(sprintf('/Users/au686880/Desktop/2dssfp_APstudy/groupAnalysis/profiles_%s_active_%s.mat',subject,ROI))

data(counter).active.deltas=deltas;

%passive
load(sprintf('/Users/au686880/Desktop/2dssfp_APstudy/groupAnalysis/profiles_%s_passive_%s.mat',subject,ROI))

data(counter).passive.deltas=deltas;


%Common for active and passive:
data(counter).idx=idx;
data(counter).analysisDir=analysisDir;
data(counter).mask=mask;
data(counter).depthmap=depthmap;
data(counter).s=s;

counter=counter+1;
end

clearvars -except data subjects num_trials num_subjects


%% get profiles
stepsize=0.05;
lower_depth=0.075;
upper_depth=1-lower_depth;
if lower_depth-stepsize/2<0 || upper_depth+stepsize/2>1
    error('make sure desired upper and lower depths match stepsize') 
end

for subjcount=1:numel(subjects)
temp_lower=lower_depth-stepsize/2;
temp_upper=temp_lower+stepsize;
temp_depths=data(subjcount).depthmap;
for layer=1:numel(lower_depth:stepsize:upper_depth)
    
    %Active
    profiles(subjcount).active(layer,:)=mean(data(subjcount).active.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1);
    
    %Passive
    profiles(subjcount).passive(layer,:)=mean(data(subjcount).passive.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1);

    temp_lower=temp_lower+stepsize;
    temp_upper=temp_upper+stepsize;
end
end
    
num_layers=size(profiles(1).active,1);
sampled_depths=lower_depth:stepsize:upper_depth;

%Make same format as 3dssf and VASO (first num subjects/trials then
%layers):
for subjcount=1:num_subjects
profiles(subjcount).active=profiles(subjcount).active';
profiles(subjcount).passive=profiles(subjcount).passive';
end
%% Get mean and standard error across trials for each subject:
for subjcount=1:numel(subjects)
acrossTrialMean_active(subjcount,:)=mean(profiles(subjcount).active,1);
acrossTrialMean_passive(subjcount,:)=mean(profiles(subjcount).passive,1);

acrossTrialStdErr_active(subjcount,:)=std(profiles(subjcount).active,[],1)./sqrt(num_trials(subjcount));
acrossTrialStdErr_passive(subjcount,:)=std(profiles(subjcount).passive,[],1)./sqrt(num_trials(subjcount));
end
%% Plot Individual profiles 
%Plot layerprofile of each subject
lw=4;
fontSize=20;
verticalHeight=[-1 3];
colorActive=[0.85 0 0];
colorPassive=[0 0 0.85];

%Set boundaries:
WMbound=0.15;
CSFbound=0.9;
range=CSFbound-WMbound;

%Definitions based on Gallagher and Zilles:
layer_I_rt=0.05; %rt is relative thickness
layer_II_III_rt=0.39;
layer_Va_rt=0.115;
layer_Vb_VI_rt=0.445;

%get boundaries
VBbound=WMbound+layer_Vb_VI_rt*range;
VAbound=VBbound+layer_Va_rt*range;
II_IIIbound=VAbound+layer_II_III_rt*range;
Ibound=II_IIIbound+layer_I_rt*range;



f=figure;
subplot(2,1,1)
hold on
errorbar(sampled_depths,acrossTrialMean_active(1,:),acrossTrialStdErr_active(1,:),'color',colorActive,'linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive(1,:),acrossTrialStdErr_passive(1,:),'color',colorPassive,'linewidth',lw)
line([VBbound,VBbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','--','linewidth',lw)
line([VAbound,VAbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','--','linewidth',lw)
line([WMbound,WMbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','-','linewidth',lw-2)
plot([0,1],[0,0],'--k')
ylabel('Signal change (%)')
%legend('active','passive')
% title('Laminar profile S1 - 2Dssfp')
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off 

subplot(2,1,2)
hold on
errorbar(sampled_depths,acrossTrialMean_active(2,:),acrossTrialStdErr_active(2,:),'color',colorActive,'linewidth',lw)
errorbar(sampled_depths,acrossTrialMean_passive(2,:),acrossTrialStdErr_passive(2,:),'color',colorPassive,'linewidth',lw)
line([VBbound,VBbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','--','linewidth',lw-2)
line([VAbound,VAbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','--','linewidth',lw-2)
line([WMbound,WMbound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[verticalHeight(1),verticalHeight(2)],'Color','black','LineStyle','-','linewidth',lw-2)
plot([0,1],[0,0],'--k')
ylabel('Signal change (%)')
% title('Laminar profile S2 session 1 - 2Dssfp')
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off 

%Change background color
set(gcf,'Color',[1 1 1])


%% Run permutation on passive trial profiles to test for significant cluster(s) of activation:

%First visualize which layers exceeds p=0.05 uncorrected:
dashLineValue=2.07;

figure
for subjcount=1:num_subjects
subplot(2,1,subjcount)
hold on
t_profiles_active(subjcount,:)=acrossTrialMean_active(subjcount,:)./acrossTrialStdErr_active(subjcount,:);
t_profiles_passive(subjcount,:)=acrossTrialMean_passive(subjcount,:)./acrossTrialStdErr_passive(subjcount,:);
plot(sampled_depths,t_profiles_active(subjcount,:),'r*','linewidth',2)
plot(sampled_depths,t_profiles_passive(subjcount,:),'b*','linewidth',2)
plot([0 1],[dashLineValue dashLineValue],'k--')
xlabel('depth from WM to CSF')
ylabel('t-value')
xlim([0 1])
legend('active','passive')
title('t-value profiles')
hold off
end

%Use function located in VASO folder:
cd('/Users/au686880/Desktop/VASO_APstudy/afterPreprocessing')

%Set subject of interest:
subjcount=1;

% Obtain permuted distribution of maximum tSums (each permutation records both maxPosTsum and maxNegTsum)
num_permutations=100000;
gm_bins=4:17;
maxSums_permDistribution = test_by_permutation_test.m(profiles(subjcount).passive(:,gm_bins),zeros(size(profiles(subjcount).passive(:,gm_bins))), num_permutations);

%Compute p-value for cluster of interest:
insideClusterLayers=6:9; %Check in t-profile plot
observed_tSum=sum(t_profiles_passive(subjcount,insideClusterLayers));

if observed_tSum > 0
p_COI = sum(maxSums_permDistribution(:,1) >= observed_tSum) / num_permutations
elseif observed_tSum < 0
p_COI = sum(maxSums_permDistribution(:,2) <= observed_tSum) / num_permutations
end
