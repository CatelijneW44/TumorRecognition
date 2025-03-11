close all
clear 
clc

%% get all content
%folder
folderPath = "C:\Users\catelijne\Downloads\Pre-operative_TCGA_GBM_NIfTI_and_Segmentations\Pre-operative_TCGA_GBM_NIfTI_and_Segmentations";

%get NIfTI files from folder
files = dir(folderPath);

allFiles = files(~startsWith({files.name}, '.'));

% subject names
subjectID = {allFiles.name};

%% Split into train (first 15)
trainingNumber = 20; 
trainingData = subjectID(:, 1:trainingNumber);

%% split into testing (30)
testingNumber = trainingNumber + 30;
testingData = subjectID(:, trainingNumber+1:testingNumber);

%% make training data

allFeature = [];
allLabel = [];

for i = 1:length(trainingData)
    %select file
    subject = trainingData{i};
    subjectPath = fullfile(folderPath, subject);

    %unzip
    [FLAIR, T1GD, T2, segm] = unzipFiles(subjectPath, subject);

    %from img to tumor vs not tumor doubles
    [allTumor, allNot] = processData(FLAIR, T1GD, T2, segm);

    %add to training dataset
    allFeature = [allFeature; allTumor; allNot]; 
    allLabel = [allLabel; ones(size(allTumor, 1), 1); zeros(size(allNot, 1), 1)];
end 

%% train model
mdl = fitcsvm(allFeature, allLabel, 'KernelFunction', 'gaussian');

%% test data
allTumorRegion = [];
actualLabel = [];

for i = 1:length(testingData)
    %select file
    subject = testingData{i};
    subjectPath = fullfile(folderPath, subject);

    %unzip
    [FLAIR, T1GD, T2, segm] = unzipFiles(subjectPath, subject);

    %from img to doubles
    [allTumor, allNot] = processData(FLAIR, T1GD, T2, segm); 

    %create labels
    labelOnes = ones(length(allTumor), 1);
    labelZeros = zeros(length(allNot), 1);

    label = [labelOnes; labelZeros]; % y actual values  

    all = [allTumor; allNot];

    % Make predictions (of labels)
    predictions = predict(mdl, all);

    %append to testing dataset
    allTumorRegion = [allTumorRegion; predictions];
    actualLabel = [actualLabel; label];
end

% confusion matrix
confusion_mat = confusionmat(actualLabel, allTumorRegion);

%eval model performance
accuracy = sum(diag(confusion_mat)) / sum(confusion_mat(:));

%confusion matrix and accuracy
disp('Confusion Matrix:');
disp(confusion_mat);
fprintf('Accuracy: %.2f%%\n', accuracy * 100);

% %% 3D Visualize
%
% subject = trainingData{4};
% subjectPath = fullfile(folderPath, subject);
% 
% [FLAIR, T1GD, T2, segm] = unzipFiles(subjectPath, subject);
% 
% %sliceViewer(segm) %<- MIPAV visualize ONE image
% 
% %MIPAV visualize ALL images
% num_slices = size(FLAIR, 3); % Get number of slices
% 
% %  figure and subplots
% fig = figure('Name','MIPAV View', 'Position',[552,363,683.6666666666665,544]);
% hImg(1) = subplot(2, 2, 1); img1 = imshow(FLAIR(:, :, 1), []); title('FLAIR');
% hImg(2) = subplot(2, 2, 2); img2 = imshow(segm(:, :, 1), [0 4]); title('Segm'); %enhance
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
%     'Callback', @(src, ~) updateSlices(round(get(src, 'Value')), img1, img2, img3, img4, FLAIR, segm, T1GD, T2, sliceLabel));
% 
% 
% % Callback -  update slices
% function updateSlices(slice, img1, img2, img3, img4, FLAIR, segm, T1GD, T2, sliceLabel)
%     img1.CData = FLAIR(:, :, slice);
%     img2.CData = segm(:, :, slice);
%     img3.CData = T1GD(:, :, slice);
%     img4.CData = T2(:, :, slice);
%     sliceLabel.String = ['Slice: ', num2str(slice)];
% end

%% unzipping function

function [FLAIR, T1GD, T2, segm] = unzipFiles(subjectPath, subject)
    %unzip the nii files
    zipFiles = dir(fullfile(subjectPath, '*.nii.gz'));

    % Unzip each file temporarily for reading
    tempFolder = fullfile(subjectPath, 'unzipped');
    %check whether temp folder already exists
    if ~exist(tempFolder, 'dir')
        mkdir(tempFolder);
        
        %unzip files
        for c = 1:length(zipFiles)
            gunzip(fullfile(subjectPath, zipFiles(c).name), tempFolder);
        end
    end
    
    % Define file patterns
    flair_file = dir(fullfile(tempFolder, subject + "*_flair.nii"));
    t1gd_file = dir(fullfile(tempFolder, subject + "*_t1Gd.nii"));
    t2_file = dir(fullfile(tempFolder, subject + "*_t2.nii"));
    segm_file = dir(fullfile(tempFolder, subject + "*_GlistrBoost_ManuallyCorrected.nii"));

    %troubleshooting
    if isempty(segm_file)
        segm_file = dir(fullfile(tempFolder, subject + "*_GlistrBoost.nii"));
    end

    % not empty? -> opening files AND extracting/reading data <- return data type int16
    if ~isempty(flair_file) && ~isempty(t1gd_file) && ~isempty(t2_file) && ~isempty(segm_file)
        FLAIR = niftiread(fullfile(tempFolder, flair_file.name));
        T1GD = niftiread(fullfile(tempFolder, t1gd_file.name));
        T2 = niftiread(fullfile(tempFolder, t2_file.name));
        segm = niftiread(fullfile(tempFolder, segm_file.name));
    else
        disp("missing file in "+ subject);
    end
end

%% processing data function
function [allTumor, allNot] = processData(FLAIR, T1GD, T2, segm)
    % Extract voxel values corresponding to tumor regions
    ET_mask = segm == 4; % Enhancing tumor mask
    NC_mask = segm == 1; % Non-enhancing core mask
    ED_mask = segm == 2; % Edematous region mask
    mask = segm == 0; % Not tumor mask
    
    % Sample voxels from each region
    num_samples = size(FLAIR, 3);
    if length(find(NC_mask)) < num_samples
        num_samples = length(find(NC_mask));
    end
    ET_voxels = datasample(find(ET_mask), num_samples, 'Replace', false); %sampling without replacement
    NC_voxels = datasample(find(NC_mask), num_samples, 'Replace', false);
    ED_voxels = datasample(find(ED_mask), num_samples, 'Replace', false);
    NotETVoxels = datasample(find(mask), num_samples, 'Replace', false);

    % Extract voxel values from MRI volumes
    ET_values = [T1GD(ET_voxels), T2(ET_voxels), FLAIR(ET_voxels)];
    NC_values = [T1GD(NC_voxels), T2(NC_voxels), FLAIR(NC_voxels)];
    ED_values = [T1GD(ED_voxels), T2(ED_voxels), FLAIR(ED_voxels)];
    Not_values = [T1GD(NotETVoxels), T2(NotETVoxels), FLAIR(NotETVoxels)];

    % Convert to double
    allTumor = double([ET_values; NC_values; ED_values]);
    allNot = double(Not_values);
end
