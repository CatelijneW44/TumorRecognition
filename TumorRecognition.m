close all
clear 
clc

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

%% Extract voxel values corresponding to tumor regions
ET_mask = segm == 4; % Enhancing tumor mask
NC_mask = segm == 1; % Non-enhancing core mask
ED_mask = segm == 2; % Edematous region mask

% Sample voxels from each region
num_samples = size(FLAIR, 3);
ET_voxels = datasample(find(ET_mask), num_samples, 'Replace', false); %sampling without replacement
NC_voxels = datasample(find(NC_mask), num_samples, 'Replace', false);
ED_voxels = datasample(find(ED_mask), num_samples, 'Replace', false);

% Extract voxel values from MRI volumes

ET_values = [T1GD(ET_voxels), T2(ET_voxels), FLAIR(ET_voxels)];
NC_values = [T1GD(NC_voxels), T2(NC_voxels), FLAIR(NC_voxels)];
ED_values = [T1GD(ED_voxels), T2(ED_voxels), FLAIR(ED_voxels)];

% Create scatter plots
scatter3(ET_values(:,1), ET_values(:,2), ET_values(:,3), 'r', 'filled', 'DisplayName', 'Enhancing Tumor');
hold on;
scatter3(NC_values(:,1), NC_values(:,2), NC_values(:,3), 'g', 'filled', 'DisplayName', 'Non-enhancing Core');
hold on;
scatter3(ED_values(:,1), ED_values(:,2), ED_values(:,3), 'b', 'filled', 'DisplayName', 'Edematous Region');
hold on;

%not tumor regions
mask = segm == 0;

NotETVoxels = datasample(find(mask), num_samples, 'Replace', false);

NotETValues = [T1GD(NotETVoxels), T2(NotETVoxels), FLAIR(NotETVoxels)];

scatter3(NotETValues(:, 1), NotETValues(:, 2), NotETValues(:, 3),  'm', 'filled', 'DisplayName', 'NOT Tumor')


% Customize plot
xlabel('T1GD');
ylabel('T2');
zlabel('FLAIR');
title('Scatter Plot of Glioblastoma Tumor Regions');
legend;
hold off;

%% fitting SVM

%adding ET, NC and ED

doubleET = double(ET_values);
doubleNC = double(NC_values);
doubleED = double(ED_values);
doubleNot = double(NotETValues);


allTumor = [doubleET; doubleNC; doubleED];
all = [doubleET; doubleNC; doubleED; doubleNot]; %X values

labelOnes = ones(length(allTumor), 1);
labelZeros = zeros(length(NotETValues), 1);

label = [labelOnes; labelZeros]; % y actual values

SVMModel = fitcsvm(all, label, 'KernelFunction', 'linear');

% Make predictions
predictions = predict(SVMModel, all);

% Compute confusion matrix
confusion_mat = confusionmat(label, predictions);

% Evaluate model performance
accuracy = sum(diag(confusion_mat)) / sum(confusion_mat(:));

% Display confusion matrix and accuracy
disp('Confusion Matrix:');
disp(confusion_mat);
fprintf('Accuracy: %.2f%%\n', accuracy * 100);


%% 3D visualize 
%volshow(FLAIR);
% visualize all slices in one image
% figure;
% montage(FLAIR, 'DisplayRange', []);
% colormap gray;
% figure;
% sliceViewer(segm) %<- MIPAV visualize ONE image
%MIPAV visualize ALL images
num_slices = size(FLAIR, 3); % Get number of slices

% %  figure and subplots
% fig = figure('Name','MIPAV View', 'Position',[552,363,683.6666666666665,544]);
% hImg(1) = subplot(2, 2, 1); img1 = imshow(FLAIR(:, :, 1), []); title('FLAIR');
% hImg(2) = subplot(2, 2, 2); img2 = imshow(T1(:, :, 1), []); title('T1');
% hImg(3) = subplot(2, 2, 3); img3 = imshow(T1GD(:, :, 1), []); title('T1GD');
% hImg(4) = subplot(2, 2, 4); img4 = imshow(T2(:, :, 1), []); title('T2');
% 
% %  slice number label
% sliceLabel = uicontrol('Style', 'text', 'String', 'Slice: 1', ...
%     'Units', 'normalized', 'Position', [0.4 0.06 0.2 0.03], ...
%     'FontSize', 12, 'FontWeight', 'bold');
% 
% % Create slider
% uicontrol('Style', 'slider', 'Min', 1, 'Max', num_slices, 'Value', 1, ...
%     'SliderStep', [1/(num_slices-1), 10/(num_slices-1)], ...
%     'Units', 'normalized', 'Position', [0.2 0.02 0.6 0.03], ...
%     'Callback', @(src, ~) updateSlices(round(get(src, 'Value')), img1, img2, img3, img4, FLAIR, T1, T1GD, T2, sliceLabel));
% 
% 
% % Callback -  update slices
% function updateSlices(slice, img1, img2, img3, img4, FLAIR, T1, T1GD, T2, sliceLabel)
%     img1.CData = FLAIR(:, :, slice);
%     img2.CData = T1(:, :, slice);
%     img3.CData = T1GD(:, :, slice);
%     img4.CData = T2(:, :, slice);
%     sliceLabel.String = ['Slice: ', num2str(slice)];
% end

%checking correct size
%disp(size(FLAIR)); % [240 240 155] <- Z component (155) corresponds to
%amount of 'slices'/images, X/Y components correspond to amount of voxels
%("pixels") in X vs Y direction... essentially resolution

% %choosing a point
% value = FLAIR(146, 110, 100); %coordinates 113, 142 at each of the slices
% disp(value) %returns intensity
% 
% 
% %converting to mm [width - left to right, height - top to bottom, depth -
% %slice #]
% mm = voxelToReal(FLAIRInfo, 147, 110, 100);
% disp(mm + " mm");
% 
% % figure('Name','Completed Segment');
% % sliceViewer(segm, "SliceNumber",100);
% % hold on
% % % [x, y] = ginput(1); %get mouse coordinates - pick point (chosen: 146,
% % % 110)
% % % disp(x);
% % % disp(y);
% % plot(146, 110, 'g*');
% % hold off
% 
% function mm = voxelToReal(image, X, Y, Z)
%     voxelSize = image.PixelDimensions;
%     mm = [X, Y, Z] .* voxelSize;
% end


