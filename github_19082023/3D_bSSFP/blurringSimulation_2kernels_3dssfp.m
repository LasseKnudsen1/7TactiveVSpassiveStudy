%% Simulation
clear; clc; close all
%% Set parameters:
mm_to_microns=1000;
N_GM=4*mm_to_microns; %Gray matter thickness
voxel_size=round(sqrt(3),2)*mm_to_microns;
FWHM1=1*mm_to_microns; %Pointspread function
FWHM2=2*mm_to_microns; %Pointspread function

kernel_x=-N_GM/2:N_GM/2;
sigma1=FWHM1/2.355;
sigma2=FWHM2/2.355;

%% Build blurring kernel and plot it:
gausskernel1=normpdf(kernel_x,0,sigma1);
gausskernel2=normpdf(kernel_x,0,sigma2);
figure
hold on
plot(kernel_x,gausskernel1)
plot(kernel_x,gausskernel2)
xlabel('Micrometer')
title('Gaussian kernels')
set(gca,'FontSize',15)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
legend('FWHM=1mm','FWHM=2mm')
hold off

%% Set up specified neural activation profiles
%Define relative size of each layer roughly determined from histology:
layer_I_rt=0.05; %rt is relative thickness
layer_II_III_rt=0.39;
layer_Va_rt=0.115;
layer_Vb_VI_rt=0.445;


%This is just number of 0's added in each end (WM and CSF) of GM. If too
%small the voxelsize cannot take very large values. 
N_pad=10000; 

%This is how much WM and CSF is desired on each side of GM in plots:
N_WM_CSF=1000;

%Define neural boxcar profile without deep layer signal:
scale_Vb_VI=0;
scale_Va=1;
scale_II_III=1;
scale_I=1;
scale_WM=0;
scale_CSF=0;
neural_profile=[zeros(1,N_pad),...
                 scale_WM*ones(1,N_WM_CSF),...
                 scale_Vb_VI*ones(1,round(layer_Vb_VI_rt*N_GM)),...
                 scale_Va*ones(1,round(layer_Va_rt*N_GM)),...
                 scale_II_III*ones(1,round(layer_II_III_rt*N_GM)),...
                 scale_I*ones(1,round(N_GM*layer_I_rt)),...
                 scale_CSF*ones(1,N_WM_CSF),...
                 zeros(1,N_pad)];


%% Plot neural activation profiles
lw=4;
color1=[0 0 0];
color2=[0.5 0.5 0.5];
verticalHeight=1.3;
N_total=numel(neural_profile);

depths=((1:N_total)-(N_pad+N_WM_CSF))./N_GM; %Get normalized depths (WM/GM boundary is 0 and WM/CSF boundary is 1):
xLimits=[-N_WM_CSF./N_GM 1+(N_WM_CSF./N_GM)]; %specify padding cutoff on left side of WM and right side of CSF

%Get boundaries:
WMbound=0;
CSFbound=1;

%Definitions based on Gallagher and Zilles:
VBbound=WMbound+layer_Vb_VI_rt;
VAbound=VBbound+layer_Va_rt;
II_IIIbound=VAbound+layer_II_III_rt;
Ibound=II_IIIbound+layer_I_rt;

f=figure;
hold on;
plot(depths,neural_profile,'color',color1,'linewidth',lw+1)
line([VBbound,VBbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([VAbound,VAbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([WMbound,WMbound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
%title('Neural profile without deep layer activation')
set(gca,'XTick',[xLimits(1)+(WMbound-xLimits(1))/2 ... 
                 WMbound+(VBbound-WMbound)/2 ...
                 VBbound+(VAbound-VBbound)/2 ...
                 VAbound+(II_IIIbound-VAbound)/2 ...
                 Ibound+(xLimits(2)-Ibound)/2])
set(gca,'XTickLabel',{'WM','Deep','Va','Superficial','CSF'})
xlabel('Depth')
ylabel('Neural activation')
xlim([xLimits(1) xLimits(2)])
set(gca,'FontSize',20)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off



%% Convolve the neural profile with the kernel and plot it:
BOLD_profile1=conv(neural_profile,gausskernel1,'same');
BOLD_profile2=conv(neural_profile,gausskernel2,'same');

f1=figure;
hold on
plot(depths,BOLD_profile1./max(BOLD_profile1),'color',color1,'linewidth',3);
plot(depths,BOLD_profile2./max(BOLD_profile2),'color',color2,'linewidth',3);
line([VBbound,VBbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([VAbound,VAbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([WMbound,WMbound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
%title('Simulated BOLD profiles with and without deep layer activation')
set(gca,'XTick',[xLimits(1)+(WMbound-xLimits(1))/2 ... 
                 WMbound+(VBbound-WMbound)/2 ...
                 VBbound+(VAbound-VBbound)/2 ...
                 VAbound+(II_IIIbound-VAbound)/2 ...
                 Ibound+(xLimits(2)-Ibound)/2])
set(gca,'XTickLabel',{'WM','Deep','Va','Superficial','CSF'})
xlabel('Depth')
ylabel('Simulated fMRI response (normalized to peak)')
xlim([xLimits(1) xLimits(2)])
legend('FWHM=1mm','FWHM=2mm')
set(gca,'FontSize',20)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off

%% Account for effect of partial voluming and plot
num_samples=100000;
%Now account for blurring due to partial voluming. Sample the signal with voxelsize windows randomly shifted
%across the BOLD profile
window_startpoint=randi([1,numel(neural_profile)-voxel_size],1,num_samples);

%Sample the signal by averaging the profile values within the window for each iteration
%and compute the relative depth for each window. 
%0 depth refers to voxel 50/50 WM GM and 1 is 50/50 GM/CSF.
%So negative or larger than 1 depths correspond to voxels with more than 50
%percent WM or CSF, respectively:
for k=1:numel(window_startpoint)
BOLD_PVcorrected_profile1(k)=mean(BOLD_profile1(window_startpoint(k):(window_startpoint(k)+voxel_size)));
BOLD_PVcorrected_profile2(k)=mean(BOLD_profile2(window_startpoint(k):(window_startpoint(k)+voxel_size)));
tmpDepths(k)=window_startpoint(k)+0.5*voxel_size;
end

simDepths=(tmpDepths-(N_pad+N_WM_CSF))./N_GM; %Normalize depths of the simulation

%plot final simulated profiles:
figure
hold on
scatter(simDepths,BOLD_PVcorrected_profile1./max(BOLD_PVcorrected_profile1),'MarkerEdgeColor',color1,'marker','.')
scatter(simDepths,BOLD_PVcorrected_profile2./max(BOLD_PVcorrected_profile2),'MarkerEdgeColor',color2,'marker','.')
line([VBbound,VBbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([VAbound,VAbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([WMbound,WMbound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
set(gca,'XTick',[xLimits(1)+(WMbound-xLimits(1))/2 ... 
                 WMbound+(VBbound-WMbound)/2 ...
                 VBbound+(VAbound-VBbound)/2 ...
                 VAbound+(II_IIIbound-VAbound)/2 ...
                 Ibound+(xLimits(2)-Ibound)/2])
set(gca,'XTickLabel',{'WM','Deep','Va','Superficial','CSF'})
xlim([xLimits(1) xLimits(2)])
xlabel('Depth')
ylabel('fMRI response (normalized to peak)')
title('Simulation of measured profiles')
set(gca,'FontSize',15)
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
legend('FWHM=1mm','FWHM=2mm')
hold off

%% Add measured (normalized) profiles to plot:
%First load profiles of measured data which is generated in
%'getProfiles-3dssfp_deltas.m'. 
load('/Users/au686880/Desktop/3dssfp_APstudy/groupAnalysis/profiles_3dssfp_forBlurringSimulation.mat');
%Normalize profiles with respect to peak signal:
normalized_active_profiles=active_profiles./max(active_profiles,[],2);
normalized_passive_profiles=passive_profiles./max(passive_profiles,[],2);

%Calculate mean and stderr across subjects:
mean_normalized_active_profiles=mean(normalized_active_profiles,1);
stdErr_normalized_active_profiles=std(normalized_active_profiles,[],1)./sqrt(size(active_profiles,1));

mean_normalized_passive_profiles=mean(normalized_passive_profiles,1);
stdErr_normalized_passive_profiles=std(normalized_passive_profiles,[],1)./sqrt(size(passive_profiles,1));

%Plot
verticalHeight=1;
f2=figure;
hold on
scatter(simDepths,BOLD_PVcorrected_profile1./max(BOLD_PVcorrected_profile1),'MarkerEdgeColor',color1,'marker','.','linewidth',lw)
scatter(simDepths,BOLD_PVcorrected_profile2./max(BOLD_PVcorrected_profile2),'MarkerEdgeColor',color2,'marker','.','linewidth',lw)
errorbar(sampled_depths,mean_normalized_active_profiles,stdErr_normalized_active_profiles,'r','linewidth',lw)
errorbar(sampled_depths,mean_normalized_passive_profiles,stdErr_normalized_passive_profiles,'b','linewidth',lw)

line([VBbound,VBbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([VAbound,VAbound],[0,verticalHeight],'Color','black','LineStyle','--','linewidth',lw)
line([WMbound,WMbound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
line([Ibound,Ibound],[0,verticalHeight],'Color','black','LineStyle','-','linewidth',lw-2)
xlim([xLimits(1) xLimits(2)])
%title('Simulated vs measured profiles - 3Dssfp')
set(gca,'XTick',[xLimits(1)+(WMbound-xLimits(1))/2 ... 
                 VBbound+(VAbound-VBbound)/2 ...
                 Ibound+(xLimits(2)-Ibound)/2])
ylabel('fMRI response (normalized to peak)')
legend('Simulated with FWHM=1mm','Simulated with FWHM=2mm','meassured active','measured passive')
set(gca,'XTickLabel',{'WM','Va','CSF'})
set(gca,'FontSize',20)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
set(gca,'fontname','times')
set(gca,'Color','none')
set(gcf,'Color',[1 1 1])
hold off
