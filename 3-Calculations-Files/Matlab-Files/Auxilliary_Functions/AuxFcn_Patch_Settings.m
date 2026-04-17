function [Patch_1,Patch_2,Patch_3,varargout] = AuxFcn_Patch_Settings(x,y,AuxFcn_GS,Execute,ExtaPatch,varargin)
% AuxFcn_Patch_Settings
% Create shaded interval patches for segmented time-series visualization.
%
% Inputs:
%   x, y             vectors defining plot extents
%   AuxFcn_GS        graphical settings struct
%   Execute          execution flag ('Execute' to run)
%   ExtaPatch        toggle for optional extra patch
%   varargin         boundary indices for patch intervals
%
% Outputs:
%   Patch_1..Patch_3 handles to primary patch objects
%   varargout        optional extra patch handle or placeholder
% [ProjectFolder,AuxFcn_GS] = AuxFcn_Matlab_Startup_File_001
switch Execute
    case 'Execute'
        %% Patch
        f = [1 2 3 4];
        % v = [v1x v1y; v2x v2y;v3x v3y;v4x v4y];
        v1 = [x(varargin{1}) min(y)-5; x(1) min(y)-5; x(1) max(y)+5; x(varargin{1}) max(y)+5];
        Patch_1 = patch('Faces',f,'Vertices',v1,'FaceColor',AuxFcn_GS.grey_light,'FaceAlpha',.40,'EdgeColor',AuxFcn_GS.grey_x);

        % Test Interval #2
        hold on
        v2 = [x(varargin{2}) min(y)-5; x(varargin{1}) min(y)-5; x(varargin{1}) max(y)+5; x(varargin{2}) max(y)+5];
        Patch_2 = patch('Faces',f,'Vertices',v2,'FaceColor',AuxFcn_GS.darkred,'FaceAlpha',.30,'EdgeColor',AuxFcn_GS.darkred_x);

        % Test Interval #3
        hold on
        v3 = [x(end) min(y)-5; x(varargin{2}) min(y)-5; x(varargin{2}) max(y)+5; x(end) max(y)+5];
        Patch_3 = patch('Faces',f,'Vertices',v3,'FaceColor',AuxFcn_GS.skyblue,'FaceAlpha',.30,'EdgeColor',AuxFcn_GS.skyblue_x);
        varargout{1} = 'DummyPatch';
        switch ExtaPatch
            case 'NoExtaPatch'
%                 OutputPatch = [Patch_1;Patch_2;Patch_3];
            case 'ExtaPatch'
                try
                    % Test Interval #4
                    hold on
                    v4 = [x(end) min(y)-5; x(varargin{3}) min(y)-5; x(varargin{3}) max(y)+5; x(end) max(y)+5];
                    Patch_4 = patch('Faces',f,'Vertices',v4,'FaceColor',AuxFcn_GS.lightblue,'FaceAlpha',.30,'EdgeColor',AuxFcn_GS.lightblue_x);
                    varargout{1} = Patch_4;
                catch
                end
        end
    case 'Not Execute'
end
end
