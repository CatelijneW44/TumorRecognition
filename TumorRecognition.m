%nibabel library not needed for niftiread

% opening files AND extracting/reading data
FLAIR = niftiread('UPENN-GBM-00003_11_FLAIR.nii.gz');
T1 = niftiread("UPENN-GBM-00003_11_T1.nii.gz");
T1GD = niftiread("UPENN-GBM-00003_11_T1GD.nii.gz");
T2 = niftiread("UPENN-GBM-00003_11_T2.nii.gz");
segm = niftiread("UPENN-GBM-00003_11_segm.nii.gz");


%checking correct size
%disp(size(FLAIR)); % [240 240 155] <- Z component (155) corresponds to
%amount of 'slices'/images, X/Y components correspond to amount of voxels
%("pixels") in X vs Y direction... essentially resolation\

%choosing a point
value = FLAIR(113, 142, :); %coordinates 113, 142 at each of the slices
%disp(value) %returns intensity
