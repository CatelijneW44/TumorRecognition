%nibabel library not needed for niftiread

% opening files 
FLAIR = niftiread('UPENN-GBM-00003_11_FLAIR.nii.gz');
T1 = niftiread("UPENN-GBM-00003_11_T1.nii.gz");
T1GD = niftiread("UPENN-GBM-00003_11_T1GD.nii.gz");
T2 = niftiread("UPENN-GBM-00003_11_T2.nii.gz");
segm = niftiread("UPENN-GBM-00003_11_segm.nii.gz");

