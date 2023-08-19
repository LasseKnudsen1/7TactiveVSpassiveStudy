function checkMotionParameters(conditionNames,runsPerCondition,startCondition,subjID,numVolRun)
%Function to check motion parameters for INV1 and INV2 in same plot. 
%Present error if number of conditions is not 2:
if numel(conditionNames)~=2
    error('Number of conditions must be 2')
end

%Fix order of conditions. 
if startCondition~=conditionNames(1)
   temp=conditionNames;
   conditionNames(1)=temp(2);
   conditionNames(2)=temp(1);
end

%Load affine transformation matrices for each volume
INV1_mat=[];
INV2_mat=[];
counter=0;
for condition=1:numel(conditionNames)
for run=1:runsPerCondition
    temp_INV1=load(sprintf('./noNORDIC_%s_INV1_0%d.mat',conditionNames(condition),run));
    temp_INV2=load(sprintf('./noNORDIC_%s_INV2_0%d.mat',conditionNames(condition),run));
    for i=1:numVolRun
    INV1_mat(:,:,i+counter)=temp_INV1.mat(:,:,i);
    INV2_mat(:,:,i+counter)=temp_INV2.mat(:,:,i);
    end
    counter=counter+numVolRun;
end
end

%Transform to translation and rotation parameters (inspired by spm_realign script):
V_INV1=spm_vol(sprintf('noNORDIC_%s_INV1_01.nii',conditionNames(1))); %First run of first condition
V_INV2=spm_vol(sprintf('noNORDIC_%s_INV2_01.nii',conditionNames(1))); %First run of first condition
for i=2:size(INV1_mat,3)
    INV1_param(i,:)=spm_imatrix(INV1_mat(:,:,i)/V_INV1(1).mat);
    INV2_param(i,:)=spm_imatrix(INV2_mat(:,:,i)/V_INV2(1).mat);
end

%Convert radians to degrees:
INV1_param(:,4:6)=INV1_param(:,4:6)*57.2957795;
INV2_param(:,4:6)=INV2_param(:,4:6)*57.2957795;


%Plot INV1 and INV2 together
figure
subplot(2,1,1)
hold on
plot(INV1_param(:,1:3),'-')
plot(INV2_param(:,1:3),'--')
title('translation parameters')
ylabel('mm')
xlabel('TR')
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
legend('INV1 x','INV1 y','INV1 z','INV2 x','INV2 y','INV2 z')
grid
hold off

subplot(2,1,2)
hold on
plot(INV1_param(:,4:6),'-')
plot(INV2_param(:,4:6),'--')
title('Rotation parameters')
ylabel('degrees')
xlabel('TR')
set(gcf,'Color',[1 1 1])
set(gca,'FontSize',15)
set(gca,'XColor',[0 0 0])
set(gca,'YColor',[0 0 0])
legend('INV1 pitch','INV1 roll','INV1 yaw','INV2 pitch','INV2 roll','INV2 yaw')
grid
hold off
sgtitle(sprintf('Subject %d',subjID),'fontsize',25,'fontweight','bold')
end