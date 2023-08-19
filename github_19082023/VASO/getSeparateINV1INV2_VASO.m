function getSeparateINV1INV2(condition,run)
%Separate INV1INV2
%Load data
V=niftiinfo(sprintf('%s_VASO_0%d.nii',condition,run));
Y_alternating=niftiread(sprintf('%s_VASO_0%d.nii',condition,run));

%Reshape
s=size(Y_alternating);
Y_alternating=reshape(Y_alternating,s(1)*s(2)*s(3),s(4));

%Generate separated INV1 and INV2 timeseries:
Y_INV1=Y_alternating(:,1:2:s(4));
Y_INV2=Y_alternating(:,2:2:s(4));

%Reshape back
Y_INV1=reshape(Y_INV1,s(1),s(2),s(3),s(4)/2);
Y_INV2=reshape(Y_INV2,s(1),s(2),s(3),s(4)/2);

%Write timeseries:
V.ImageSize(4)=V.ImageSize(4)/2;

niftiwrite(Y_INV1,sprintf('noNORDIC_%s_INV1_0%d.nii',condition,run),V)
niftiwrite(Y_INV2,sprintf('noNORDIC_%s_INV2_0%d.nii',condition,run),V)
end