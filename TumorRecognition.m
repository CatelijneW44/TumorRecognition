%nibabel library not needed for niftiread

% returns data type struct - used for converting to mm
FLAIRInfo = niftiinfo("UPENN-GBM-00003_11_FLAIR.nii.gz");
T1Info = niftiinfo("UPENN-GBM-00003_11_T1.nii.gz");
T1GDInfo = niftiinfo("UPENN-GBM-00003_11_T1GD.nii.gz");
T2Info = niftiinfo("UPENN-GBM-00003_11_T2.nii.gz");
segmInfo = niftiinfo("UPENN-GBM-00003_11_segm.nii.gz");


% opening files AND extracting/reading data <- return data type int16
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


%converting to mm [width - left to right, height - top to bottom, depth -
%slice #]
mm = voxelToReal(FLAIRInfo, 113, 142, 100);
disp("display mm " + mm);

function mm = voxelToReal(image, X, Y, Z)
    voxelSize = image.PixelDimensions;
    mm = [X, Y, Z] .* voxelSize;
end
