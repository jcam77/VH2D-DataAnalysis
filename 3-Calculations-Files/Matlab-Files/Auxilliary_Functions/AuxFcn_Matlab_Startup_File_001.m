function [ProjectFolder,AuxFcn_GS] = AuxFcn_Matlab_Startup_File_001
% AuxFcn_Matlab_Startup_File_001
% Prepare startup context and load graphical settings.
%
% Inputs:
%   (none)
%
% Outputs:
%   ProjectFolder    root startup folder for current MATLAB project
%   AuxFcn_GS        loaded graphical settings struct
%% Matlab Startup File
%% Workspace Preparation
    proj = matlab.project.rootProject;
% %% Auxilliary Functions & Folder's Path
%     MainCodeFolder = fileparts(which(mfilename));% Determine where your m-file's folder is.
    ProjectFolder=convertStringsToChars(proj.ProjectStartupFolder); %ProjectStartupFolder
%     ProjectSubFolders=addpath(genpath(ProjectStartupFolder));% Add that folder plus all subfolders to the path.
    AuxFcn_GS = load('AuxFcn_Graphical_Settings.mat');

% %% Graphical Representation Settings
%     matlab.graphics.internal.setPrintPreferences('DefaultPaperPositionMode','manual')% Set the default value of "PaperPositionMode" to 'manual'. This preference will persist across MATLAB sessions.
%     set(groot,'defaultFigurePaperPositionMode','manual')% Set the default "FigurePaperPositionMode" to 'manual' before creating the figures.
    
    %Note: This will need to be executed again every time you open MATLAB. If you would like this to persist across MATLAB sessions, place the above line of code in your "startup.m" file.
    % If you do not have a startup.m file, create a "startup.m" file in a folder on the MATLAB search path.
end
