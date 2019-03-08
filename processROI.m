%% DKE-Mouse Extraction Script
%   This is a script written specifically to perform ROI extraction from
%   DKE maps of mice brains. This script includes ReadImageJROI from MATLAB
%   FX to read images annotated in ImageJ.

%% Workspace Cleansing
clc; clear all; close all;
addpath('ReadImageJROI/');

%% Processing Variables
Drange = [0 1.5];
Krange = [0 3];
Frange = [0 1];
relMetrics = {'dmean','drad','dax','kmean','krad','kax','fa'};

%% Choose Directory
studyPath = uigetdir(pwd);
imagePath = fullfile(studyPath,'Images');
roiPath = fullfile(studyPath,'ROIs');

%% Create Subject Listing
imageDir = dir(imagePath);
%   Clean up listing
imageDir = imageDir(~startsWith({imageDir.name},'.'));
for i = 1:length(imageDir)
    subList{i} = imageDir(i).name;
end

%   Clean up dates from subList
for i = 1:length(subList)
    nm = split(subList{i},'_');
    subNames(i) = nm(1);
end

%% Create ROI Region Listing
roiDir = dir(roiPath);
%   Clean up listing
roiDir = roiDir(~startsWith({roiDir.name},'.'));
for i = 1:length(roiDir)
    roiList{i} = roiDir(i).name;
end

%% Create Output Directory
outPath = fullfile(studyPath,'Anaytical_Outputs');
mkdir(outPath);

%% Run ROI Analysis
%   Find every possible ImageJ ROI
allROIs = dir(fullfile(roiPath,'**/*.zip'));
cntA = 0;
for i = 1:length(subNames);
    %   List ROI file names
    metricNames = dir(fullfile(imagePath,subList{i},'dke','*.nii'));
    %   Remove non-metric files
    metricNames = metricNames(contains({metricNames.name},relMetrics));
    %   Open each file
    for j = 1:length(metricNames)
        curName = metricNames(j).name;
        %   Open a metric file
        V = niftiread(fullfile(metricNames(j).folder,metricNames(j).name));
        
        if contains(curName,{'dmean','drad','dax'});
            range = Drange;
        elseif contains(curName,{'kmean','krad','kax'});
            range = Krange;
        else
            range = Frange;
        end
        
        %   Match ROI with subjects name
        idxROI = find(contains({allROIs.name},subNames{i}));
        
        for k = 1:length(idxROI)
            nROI = idxROI(k);
            try
                %   Locate ROI
                [~,roiLoc,~] = fileparts(allROIs(nROI).folder);
                
                %   Open each ROI
                tmpExtract = tempname(roiPath);
                unzip(fullfile(allROIs(nROI).folder,allROIs(nROI).name),...
                    tmpExtract);
                rRegions = dir(fullfile(tmpExtract,'*.roi'));
            catch
                continue
            end
            
            %   Convert every labelled region to a mask and concatenate along 4th
            %   dimension
            for iReg = 1:length(rRegions)
                
                [sROI] = ReadImageJROI(fullfile(rRegions(iReg).folder,...
                    rRegions(iReg).name));
                
                %%%%%%%%%%%%%%%%%%%%
                fidROI = fopen(fullfile(rRegions(iReg).folder,...
                    rRegions(iReg).name),'r','ieee-be');
                
                %   Create mask from information about nROI
                
                %%%%%%%%%%%%%%%%%%%%
                
                cntA = cntA + 1;    %   Loop counter
                roiMask = lRegions == iReg;
                maskedV = V(roiMask);
                %   Apply ranged filter
                maskedV = maskedV(find(maskedV >= range(1) & maskedV <= range(2)));
                roiMetrics(cntA).subject = subNames{i};
                roiMetrics(cntA).metric = curName;
                
                roiMetrics(cntA).location = roiLoc;
                roiMetrics(cntA).index = cntA;
                roiMetrics(cntA).roi_index = iReg;
                roiMetrics(cntA).roi_title = allROIs(idxROI(k)).name;
                roiMetrics(cntA).area = nnz(roiMask);
                roiMetrics(cntA).mean = mean(maskedV(find(maskedV)));
                roiMetrics(cntA).stdev = std(maskedV(find(maskedV)));
                roiMetrics(cntA).min = min(maskedV(find(maskedV)));
                roiMetrics(cntA).max = max(maskedV(find(maskedV)));
                roiMetrics(cntA).median = median(maskedV(find(maskedV)));
                clear roiMask maskedV
            end
        end
        clear V
    end
end




