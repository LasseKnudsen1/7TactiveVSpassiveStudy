clear; clc; close all;
%% Load prepared variables into data structure
subjects=[1 2 3 4 5 6 7 8 9 10];
num_subjects=numel(subjects);
ROI='indexfingerROI';
counter=1;
for subject=subjects
%active
load([sprintf('/Users/au686880/Desktop/VASO_APstudy/groupAnalysis/equidist/profiles_S%d_active',subject) ROI '.mat'])

data(counter).active.VASO=trialAV_noNORDIC_VASO;
data(counter).active.BOLD=trialAV_noNORDIC_BOLD;

%passive
load([sprintf('/Users/au686880/Desktop/VASO_APstudy/groupAnalysis/equidist/profiles_S%d_passive',subject) ROI '.mat'])

data(counter).passive.VASO=trialAV_noNORDIC_VASO;
data(counter).passive.BOLD=trialAV_noNORDIC_BOLD;


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
    active_profiles_VASO(subjcount,layer)=mean(data(subjcount).active.VASO(temp_depths>=temp_lower & temp_depths<temp_upper));
    active_profiles_BOLD(subjcount,layer)=mean(data(subjcount).active.BOLD(temp_depths>=temp_lower & temp_depths<temp_upper));

    %Passive
    passive_profiles_VASO(subjcount,layer)=mean(data(subjcount).passive.VASO(temp_depths>=temp_lower & temp_depths<temp_upper));
    passive_profiles_BOLD(subjcount,layer)=mean(data(subjcount).passive.BOLD(temp_depths>=temp_lower & temp_depths<temp_upper));

    temp_lower=temp_lower+stepsize;
    temp_upper=temp_upper+stepsize;
end
end
    
num_layers=size(passive_profiles_VASO,2);
sampled_depths=lower_depth:stepsize:upper_depth;


%% Get mean and stdErr across subjects
%Active
mean_active_VASO=mean(active_profiles_VASO,1);
stdErr_active_VASO=std(active_profiles_VASO,[],1)./sqrt(num_subjects);

mean_active_BOLD=mean(active_profiles_BOLD,1);
stdErr_active_BOLD=std(active_profiles_BOLD,[],1)./sqrt(num_subjects);

%Passive
mean_passive_VASO=mean(passive_profiles_VASO,1);
stdErr_passive_VASO=std(passive_profiles_VASO,[],1)./sqrt(num_subjects);

mean_passive_BOLD=mean(passive_profiles_BOLD,1);
stdErr_passive_BOLD=std(passive_profiles_BOLD,[],1)./sqrt(num_subjects);


%% Plot group mean profiles
lw=4; %linewidth
verticalHeight=[-0.5 2]; %vertical bars to set borders
fontSize=25;
fontSize_subplots=15;
colorActive=[0.85 0 0];
colorPassive=[0 0 0.85];

WMbound=0.2;
CSFbound=0.9;
range=CSFbound-WMbound;

%Gallagher and Zilles:
VIbound=WMbound+0.33*range;
VBbound=VIbound+0.115*range;
VAbound=VBbound+0.115*range;
II_IIIbound=VAbound+0.39*range;
Ibound=II_IIIbound+0.05*range;

f=figure;
%VASO
subplot(2,1,1)
hold on
errorbar(sampled_depths,mean_active_VASO,stdErr_active_VASO,'color',colorActive,'linewidth',lw)
errorbar(sampled_depths,mean_passive_VASO,stdErr_passive_VASO,'color',colorPassive,'linewidth',lw)
plot([0 1],[0 0],'k--') %horisontal line at 0

plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([0 1])
%legend('active','passive')
%title('VASO')
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

%BOLD
verticalHeight=[0 6];
subplot(2,1,2)
hold on
errorbar(sampled_depths,mean_active_BOLD,stdErr_active_BOLD,'color',colorActive,'linewidth',lw)
errorbar(sampled_depths,mean_passive_BOLD,stdErr_passive_BOLD,'color',colorPassive,'linewidth',lw)
%plot([0 1],[0 0],'k--') %horisontal line at 0

plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([0 1])
%title('BOLD')
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


%% Plot individual profiles
figure 
for subjcount=1:num_subjects
subplot(5,2,subjcount)
hold on
plot(sampled_depths,active_profiles_VASO(subjcount,:),'color',colorActive)
plot(sampled_depths,passive_profiles_VASO(subjcount,:),'color',colorPassive)
ylabel('Signal change (%)')
xlim([0 1])
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',fontSize_subplots)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gcf,'Color',[1 1 1])
title(sprintf('Subject %d',subjcount))
end
set(gcf,'Color',[1 1 1])
sgtitle('Individual profiles - VASO','fontsize',fontSize_subplots,'fontweight','bold')
hold off

figure 
for subjcount=1:num_subjects
subplot(5,2,subjcount)
hold on
plot(sampled_depths,active_profiles_BOLD(subjcount,:),'color',colorActive)
plot(sampled_depths,passive_profiles_BOLD(subjcount,:),'color',colorPassive)
ylabel('Signal change (%)')
xlim([0 1])
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',fontSize_subplots)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gcf,'Color',[1 1 1])
title(sprintf('Subject %d',subjcount))
end
set(gcf,'Color',[1 1 1])
sgtitle('Individual profiles - BOLD','fontsize',fontSize_subplots,'fontweight','bold')
hold off
%% Run permutation of passive subject profiles to test for significant cluster of activation at group level
t_profile_VASO_active=mean_active_VASO./stdErr_active_VASO;
t_profile_VASO_passive=mean_passive_VASO./stdErr_passive_VASO;
%First visualize which individual clusters survives p<0.05 uncorrected:
dashLineValue=2.3;
verticalHeight=[-2 10];
figure
hold on
plot(sampled_depths,t_profile_VASO_active,'r*','linewidth',2)
plot(sampled_depths,t_profile_VASO_passive,'b*','linewidth',2)
plot([0 1],[dashLineValue dashLineValue],'k--')
plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw) %vertical line at WM boundary
plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw) %vertical line at Vb boundary
plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw) %vertical line at Va boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw) %vertical line at I boundary
xlabel('Cortical depth')
set(gca,'XTick',[WMbound/2 ... 
                 VBbound+(VAbound-VBbound)/2 ... 
                 Ibound+(1-Ibound)/2])
set(gca,'XTickLabel',{'WM','Va','CSF'})
xlabel('depth from WM to CSF')
ylabel('t-value')
xlim([0 1])
legend('active','passive')
title('t-values VASO')
hold off

%Now run permutation, length_permutation_test is the distribution:
num_permutations=100000; %see test_by_permutation_test.m
[P_test_final,length_permutation_test]=test_by_permutation_test(passive_profiles_VASO,zeros(size(passive_profiles_VASO)),num_permutations);

%Compute p-value for cluster of interest:
insideClusterLayers=6:9; %Check in t-profile plot
summed_tval_cluster=sum(t_profile_VASO_passive(insideClusterLayers));
p_clustOfInterest=sum(length_permutation_test>=summed_tval_cluster)./num_permutations


%% GE-BOLD deconvolution
%First interpolate num_layers to 100 to minimize layer edge effects. Then 
%for each bin, subtract contribution from bins below based on weights given in Marquadt 2018:
xInterped=linspace(min(sampled_depths),max(sampled_depths),100);
weights=[0*ones(1,42) 0.32/9*ones(1,9) 0.2/9*ones(1,9) 0.59/32*ones(1,32) 0.41/5*ones(1,5) 0*ones(1,3)];
for subjcount=1:num_subjects
    yInterped_active(subjcount,:)=interp1(sampled_depths,active_profiles_BOLD(subjcount,:),xInterped);
    yInterped_passive(subjcount,:)=interp1(sampled_depths,passive_profiles_BOLD(subjcount,:),xInterped);
    aSub=0;
    pSub=0;
    for i=1:100
    dy_active(subjcount,i)=yInterped_active(subjcount,i)-aSub;
    dy_passive(subjcount,i)=yInterped_passive(subjcount,i)-pSub;
    aSub=aSub+weights(i)*dy_active(subjcount,i);
    pSub=pSub+weights(i)*dy_passive(subjcount,i);
    end

end

mean_dy_active=mean(dy_active,1);
mean_dy_passive=mean(dy_passive,1);
stdErr_dy_active=std(dy_active,[],1)./sqrt(num_subjects);
stdErr_dy_passive=std(dy_passive,[],1)./sqrt(num_subjects);


%Plot
figure 
hold on
plot(xInterped,mean(yInterped_active,1),'r')
plot(xInterped,mean(yInterped_passive,1),'b')
errorbar(xInterped,mean_dy_active,stdErr_dy_active,'r--')
errorbar(xInterped,mean_dy_passive,stdErr_dy_passive,'b--')
plot(xInterped,interp1(sampled_depths,mean_active_VASO,xInterped),'r*')
plot(xInterped,interp1(sampled_depths,mean_passive_VASO,xInterped),'b*')
ylim([0 5])

plot([WMbound WMbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
% plot([VIbound VIbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
% plot([VBbound VBbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Vb boundary
% plot([VAbound VAbound],verticalHeight,'k--','linewidth',lw-2) %vertical line at Va boundary
% plot([II_IIIbound II_IIIbound],verticalHeight,'k-','linewidth',lw-2) %vertical line at WM boundary
plot([Ibound Ibound],verticalHeight,'k-','linewidth',lw-2) %vertical line at I boundary
ylabel('Signal change (%)')
xlim([0 1])
legend('active BOLD','passive BOLD','active BOLD corrected','passive BOLD corrected','active VASO','passive VASO')
title('Deconvolved BOLD profiles')
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







