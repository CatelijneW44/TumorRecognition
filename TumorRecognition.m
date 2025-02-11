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

% 3D visualize 
%volshow(FLAIR);

% visualize all slices in one image
% figure;
% montage(FLAIR, 'DisplayRange', []);
% colormap gray;

%figure;
%sliceViewer(segm) %<- MIPAV visualize ONE image

%MIPAV visualize ALL images
num_slices = size(FLAIR, 3); % Get number of slices

%  figure and subplots
fig = figure('Name','MIPAV View', 'Position',[552,363,683.6666666666665,544]);
hImg(1) = subplot(2, 2, 1); img1 = imshow(FLAIR(:, :, 1), []); title('FLAIR');
hImg(2) = subplot(2, 2, 2); img2 = imshow(T1(:, :, 1), []); title('T1');
hImg(3) = subplot(2, 2, 3); img3 = imshow(T1GD(:, :, 1), []); title('T1GD');
hImg(4) = subplot(2, 2, 4); img4 = imshow(T2(:, :, 1), []); title('T2');

%  slice number label
sliceLabel = uicontrol('Style', 'text', 'String', 'Slice: 1', ...
    'Units', 'normalized', 'Position', [0.4 0.06 0.2 0.03], ...
    'FontSize', 12, 'FontWeight', 'bold');

% Create slider
uicontrol('Style', 'slider', 'Min', 1, 'Max', num_slices, 'Value', 1, ...
    'SliderStep', [1/(num_slices-1), 10/(num_slices-1)], ...
    'Units', 'normalized', 'Position', [0.2 0.02 0.6 0.03], ...
    'Callback', @(src, ~) updateSlices(round(get(src, 'Value')), img1, img2, img3, img4, FLAIR, T1, T1GD, T2));


% Callback -  update slices
function updateSlices(slice, img1, img2, img3, img4, FLAIR, T1, T1GD, T2)
    img1.CData = FLAIR(:, :, slice);
    img2.CData = T1(:, :, slice);
    img3.CData = T1GD(:, :, slice);
    img4.CData = T2(:, :, slice);
    sliceLabel.String = ['Slice: ', num2str(slice)];
end


%checking correct size
%disp(size(FLAIR)); % [240 240 155] <- Z component (155) corresponds to
%amount of 'slices'/images, X/Y components correspond to amount of voxels
%("pixels") in X vs Y direction... essentially resolution

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
