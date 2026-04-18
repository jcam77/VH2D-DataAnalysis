%% Hydrogen MFC Fill Calculator
%% Objective
% Example wrapper for the reusable hydrogen fill calculator function.
% Edit the inputs for one test, run the script, and the function returns the
% required hydrogen amount and optional filling time estimate.

clearvars; clc; close all;
format short eng

%% Add Auxiliary Functions
thisFileDir = fileparts(mfilename('fullpath'));
projectRootDir = fileparts(fileparts(thisFileDir));
auxDir = fullfile(projectRootDir, 'Auxilliary_Functions', 'EMP2X-Project');
addpath(auxDir);

%% Example Test Inputs
% Scalars are applied to all rows. Vectors must have the same length as
% H2_volPct so each concentration can use its own test conditions.
L = 0.9;                                                                    % Length (L)
W = 0.9;                                                                    % Width (W)
H = 0.9;                                                                    % Height (H)
V_chamber_m3 = L * W * H;                                                   % chamber free volume [m^3]
Vol_Pipes = 0;                                                              % pipes added free volume [m^3]
WeldedParts = 0;                                                            % Welded Parts substracted volume [m^3]
V_chamberCorrected_m3 = V_chamber_m3 + Vol_Pipes - WeldedParts;             % chamber free volume corrected [m^3]

T_chamber_K = [292.95 293.25 293.55 293.15 294.35 294.15 293.85 294.05];    % per-test chamber gas temperature [K]
P_chamber_Pa = [101325 101325 101280 101310 101420 101390 101340 101360];   % per-test chamber absolute pressure [Pa]
H2_volPct = [4 8 10 12 16 18 19 20];                                        % target hydrogen concentration [vol%]

T_std_K = 298.15;                                                           % Alicat default standard temperature [K]
P_std_Pa = 101325;                                                          % standard absolute pressure [Pa]
MFC_capacity_SLPM = 50.0;                                                   % MFC full-scale capacity [SLPM]
MFC_setpoint_SLPM = [40 40 25 35 35 40 40 40];                              % per-test Alicat setpoint [SLPM]

makePlot = true;                                                            % true to generate the mass plot

%% Run Calculator
Results = AuxFcn_H2_MFC_FillCalculator_000( ...
    V_chamberCorrected_m3, ...
    T_chamber_K, ...
    P_chamber_Pa, ...
    H2_volPct, ...
    T_std_K, ...
    P_std_Pa, ...
    MFC_setpoint_SLPM, ...
    makePlot);

%% Display Results
if isfield(Results, 'table')
    disp(Results.table)
else
    disp(strjoin(Results.headers, ' | '))
    disp(Results.data)
end

%% Example for Multiple Tests
% testTemperatures_K = [291.65 294.15 297.15];
% for iTest = 1:numel(testTemperatures_K)
%     testResult = AuxFcn_H2_MFC_FillCalculator_000( ...
%         V_chamberCorrected_m3, testTemperatures_K(iTest), P_chamber_Pa(iTest), ...
%         18, T_std_K, P_std_Pa, ...
%         MFC_setpoint_SLPM(iTest), false);
%     fprintf('Test %d -> T = %.2f K, injected H2 = %.3f g, estimated injection time = %.2f s\n', ...
%         iTest, testTemperatures_K(iTest), testResult.m_H2_injected_g, testResult.InjectionTime_s);
% end
