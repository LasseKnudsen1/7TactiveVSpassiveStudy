
%% Load prepared variables into data structure
clear; clc; close all;
subjects=[1 2 3 4 5 6 7];
runsPerCondition=[3 4 4 4 4 3 3];
num_trialsPerRun=6;
num_subjects=numel(subjects);
num_trials=runsPerCondition*num_trialsPerRun;
ROI="indexfingerROI_active_corrected"; %Some code applies to active and some to ap ROI. 
counter=1;
for subject=subjects
%active
load(sprintf('/Users/au686880/Desktop/3dssfp_APstudy/groupAnalysis/profiles_S%d_active_%s.mat',subject,ROI))

data(counter).active.deltas=deltas;

%passive
load(sprintf('/Users/au686880/Desktop/3dssfp_APstudy/groupAnalysis/profiles_S%d_passive_%s.mat',subject,ROI))

data(counter).passive.deltas=deltas;


%Common for active and passive:
data(counter).idx=idx;
data(counter).analysisDir=analysisDir;
data(counter).mask=mask;
data(counter).depthmap=depthmap;
data(counter).s=s;

counter=counter+1;
end

clearvars -except data subjects num_trials num_subjects ROI


%% get profiles
stepsize=0.055;
lower_depth=0.0275;
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
    active_profiles(subjcount,layer)=mean(mean(data(subjcount).active.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1));
    active_profiles_stdErr(subjcount,layer)=std(mean(data(subjcount).active.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1))/sqrt(num_trials(subjcount));
    
    %Passive
    passive_profiles(subjcount,layer)=mean(mean(data(subjcount).passive.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1));
    passive_profiles_stdErr(subjcount,layer)=std(mean(data(subjcount).passive.deltas(temp_depths>=temp_lower & temp_depths<temp_upper,:),1))/sqrt(num_trials(subjcount));


    temp_lower=temp_lower+stepsize;
    temp_upper=temp_upper+stepsize;
end
end
    
num_layers=size(passive_profiles,2);
sampled_depths=lower_depth:stepsize:upper_depth;

if ROI=="indexfingerROI_active_corrected"
save('/Users/au686880/Desktop/3dssfp_APstudy/groupAnalysis/profiles_3dssfp_forBlurringSimulation.mat','active_profiles','passive_profiles','sampled_depths','num_layers')
end
%% Get mean and stdErr across subjects
%Active
acrossSubjMean_active=mean(active_profiles,1);
acrossSubjStdErr_active=std(active_profiles,[],1)./sqrt(num_subjects);

%Passive
acrossSubjMean_passive=mean(passive_profiles,1);
acrossSubjStdErr_passive=std(passive_profiles,[],1)./sqrt(num_subjects);


%% Plot Group profiles
lw=4;
fontSize=25;
colorActive=[0.85 0 0];
colorPassive=[0 0 0.85];
verticalHeight=[0 2];

WMbound=0;
CSFbound=1;
range=CSFbound-WMbound;

%Gallagher and Zilles:
VIbound=WMbound+0.33*range;
VBbound=VIbound+0.115*range;
VAbound=VBbound+0.115*range;
II_IIIbound=VAbound+0.39*range;
Ibound=II_IIIbound+0.05*range;

%Plot mean layerprofiles of each condition
f=figure;
hold on
errorbar(sampled_depths,acrossSubjMean_active,acrossSubjStdErr_active,'color',colorActive,'linewidth',lw);
errorbar(sampled_depths,acrossSubjMean_passive,acrossSubjStdErr_passive,'color',colorPassive,'linewidth',lw);
plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([-0.1 1.1])
ylim([0 2])
%legend('active','passive')
%title('Group laminar profiles - 3Dssfp')
set(gca,'XTick',[-0.05 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 1.05])
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

%% Plot Binned group profiles
deep=1:8;
superficial=9:18;
%Create and plot 2 bin profiles:
bin_active(:,1)=mean(active_profiles(:,deep),2);
bin_active(:,2)=mean(active_profiles(:,superficial),2);
bin_passive(:,1)=mean(passive_profiles(:,deep),2);
bin_passive(:,2)=mean(passive_profiles(:,superficial),2);

bin_active_mean=mean(bin_active,1);
bin_passive_mean=mean(bin_passive,1);

bin_stderr_active = std(bin_active,[],1) / sqrt(size(bin_active,1));
bin_stderr_passive = std(bin_passive,[],1) / sqrt(size(bin_passive,1));

figure
hold on
errorbar([1,2],bin_active_mean,bin_stderr_active,'color',colorActive,'linewidth',lw)
errorbar([1,2],bin_passive_mean,bin_stderr_passive,'color',colorPassive,'linewidth',lw)
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Deep','Superficial'})
ylabel('Signal change (%)')
%title('Group 2-bin profiles - 3Dssfp')
xlim([0.5 2.5])
ylim([0 2])
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'Color','none')
set(gca,'fontname','times')
%legend('active','passive','location','northwest')
hold off

%Change background color
set(gcf,'Color',[1 1 1])
hold off

%% Plot Binned individual differences
figure
hold on
plot([1,2],[bin_active(:,1)-bin_passive(:,1),bin_active(:,2)-bin_passive(:,2)],'linewidth',lw)
plot([0 3],[0 0],'k--')
ylabel('Signal change (%)')
xlim([0.5,2.5])
title('Binned differences (active minus passive) - 3Dssfp')
legend('S1','S2','S6','S7','S9','S10','S14','location','northwest')
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Deep','Middle/Superficial'})
hold off

%Change background color
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])

%% Two way repeated measures ANOVA

%Perform 2-way repeated measures ANOVA
Y=[bin_active(:,1) bin_active(:,2) bin_passive(:,1) bin_passive(:,2)]; %a_deep, a_sup, p_deep, p_sup
Y=reshape(Y,num_subjects*4,1); %Reshape to column vector
%Specify task for each observation (1=active, 2=passive):
F1=[ones(1,num_subjects) ones(1,num_subjects) 2*ones(1,num_subjects) 2*ones(1,num_subjects)]'; 
 %Specify layer for each observation (1=deep, 2=superficial)
F2=[ones(1,num_subjects) 2*ones(1,num_subjects) ones(1,num_subjects) 2*ones(1,num_subjects)]';
S=reshape([1:num_subjects,1:num_subjects,1:num_subjects,1:num_subjects],num_subjects*4,1); %Specify subject for each observation
FACTNAMES={'Task', 'Layer'}; %Specify name of each factor, F1 and F2

%call function (code found in fMRI_analysis/effectsizetoolbox):
stats=mes2way(Y,[F1,F2],{'eta2'},'isDep',[1,1],'nBoot',10000); %isDep specifies that both factors are dependent. 

%% Test for differences in noise across active and passive conditions
%We do this to make sure one condition is not more noisy than the other
%which could bias the selection towards that condition.

%We consider the standard deviation across trials. 

%Find std across trials for each voxel in each subject, then average std across voxels;
for subjcount=1:num_subjects
    tmp_std_active(subjcount)=mean(std(data(subjcount).active.deltas,[],2));
    tmp_std_passive(subjcount)=mean(std(data(subjcount).passive.deltas,[],2));
end

%Find across-subject mean and stdErr of the standard deviation:
acrossSubjMean_std_active=mean(tmp_std_active);
acrossSubjMean_std_passive=mean(tmp_std_passive);

acrossSubjStdErr_std_active=std(tmp_std_active)./sqrt(num_subjects); 
acrossSubjStdErr_std_passive=std(tmp_std_passive)./sqrt(num_subjects); 

%plot:
scatterSize=60;
x1=1*ones(1,num_subjects)+randn(1,num_subjects)*0.07;
x2=2*ones(1,num_subjects)+randn(1,num_subjects)*0.07;
figure
hold on
plot([0.9 1.1],[acrossSubjMean_std_active,acrossSubjMean_std_active],'color',[0 0 0],'linewidth',2)
plot([1.9 2.1],[acrossSubjMean_std_passive,acrossSubjMean_std_passive],'color',[0 0 0],'linewidth',2)
%errorbar(1,acrossSubjMean_std_active,acrossSubjStdErr_std_active,'color',[0 0 0],'linewidth',3)
%errorbar(2,acrossSubjMean_std_passive,acrossSubjStdErr_std_passive,'color',[0 0 0],'linewidth',3)
scatter(x1,tmp_std_active,scatterSize,'MarkerEdgeColor',colorActive,'MarkerFaceColor','none')
scatter(x2,tmp_std_passive,scatterSize,'MarkerEdgeColor',colorPassive,'MarkerFaceColor','none')
set(gca,'XTick',[1,2])
set(gca,'XTickLabel',{'Active','Passive'})
ylabel('Standard deviation')
%title('Evaluation of across-trial variance for each condition')
xlim([0 3])
ylim([0 1.8])
set(gca,'FontSize',20)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
%legend('Active','Passive','location','northwest')
hold off

%Change background color
set(gcf,'Color',[1 1 1])

%% From below here is figures used for activeROI, so remember to switch in beginning of script. 

%% Plot Individual profiles 
%Plot layerprofile of each subject
f1=figure;
subplot(2,1,1)
hold on
plot(sampled_depths,active_profiles,'linewidth',lw-1)
plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([-0.1 1.1])
ylim([0 2])
%title('Individual active profiles - 3Dssfp')
set(gca,'XTick',[-0.05 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 1.05])
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',fontSize)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
%legend('S1','S2','S6','S7','S9','S10','S14','location','northwest')
hold off 

subplot(2,1,2)
hold on
plot(sampled_depths,passive_profiles,'linewidth',lw-1)
plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([-0.1 1.1])
ylim([0 2])
%title('Individual passive profiles - 3Dssfp')
set(gca,'XTick',[-0.05 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 1.05])
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

 
%% Run permutation on passive subject profiles to test for significant cluster(s) of activation at group level:
%ONLY valid for ROI defined by active contrast, not combined
%active/passive. 
t_profile_active=acrossSubjMean_active./acrossSubjStdErr_active;
t_profile_passive=acrossSubjMean_passive./acrossSubjStdErr_passive;

%First visualize which individual clusters survives p<0.05 uncorrected:
dashLineValue=2.45;

figure
hold on
plot(sampled_depths,t_profile_active,'r*','linewidth',2)
plot(sampled_depths,t_profile_passive,'b*','linewidth',2)
plot([0 1],[dashLineValue dashLineValue],'k--')
xlabel('depth from WM to CSF')
ylabel('t-value')
xlim([0 1])
legend('active','passive')
title('t-value profiles')
hold off

%Use function (test_by_permutation_test) located in VASO folder:
cd('/Users/au686880/Desktop/VASO_APstudy/afterPreprocessing')

%Now run permutation, length_permutation_test is the distribution:
num_permutations=100000; %see test_by_permutation_test.m
[P_test_final,length_permutation_test]=test_by_permutation_test(passive_profiles,zeros(size(passive_profiles)),num_permutations);

%Compute p-value for cluster of interest:
insideClusterLayers=1:8; %Check in t-profile plot
summed_tval_cluster=sum(t_profile_passive(insideClusterLayers));
p_clustOfInterest=sum(length_permutation_test>=summed_tval_cluster)./num_permutations

