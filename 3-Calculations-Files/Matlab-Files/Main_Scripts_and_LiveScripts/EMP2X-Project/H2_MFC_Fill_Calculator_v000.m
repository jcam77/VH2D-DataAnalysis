%% Hydrogen MFC Fill Calculator
%% Objective
% Estimate the hydrogen amount required to reach target chamber
% concentrations and, optionally, estimate the filling time from the Alicat
% MFC setpoint expressed in standard liters per minute.
%
% Assumptions
% 1. Ideal gas behavior.
% 2. Hydrogen volume fraction equals hydrogen mole fraction.
% 3. Use absolute pressure, not gauge pressure.
% 4. "vented" mode is the usual case for concentration-controlled filling.

clearvars; clc; close all;
format short eng

%% User Inputs
V_chamber_m3 = 0.729;                    % chamber free volume [m^3]
T_local_C = 20.0;                        % local gas temperature [degC]
P_final_barAbs = 1.01325;                % final absolute pressure [bar]
H2_volPct = [4 5 10 15 18 20 25 30];     % target hydrogen concentration [vol%]

fillMode = "vented";                     % "vented" or "sealed"
P0_barAbs = 1.01325;                     % initial chamber pressure [bar], sealed mode only

% Standard reference used by the MFC / totalizer for SLPM or standard liters.
T_std_C = 0.0;                           % standard temperature [degC]
P_std_barAbs = 1.01325;                  % standard absolute pressure [bar]

% Optional MFC setpoint for filling-time estimate.
% Set to NaN if you only want mass / mole / volume calculations.
MFC_setpoint_std_LPM = NaN;              % standard liters per minute [SLPM]

%% Constants
Ru = 8.314462618;                        % universal gas constant [J/(mol*K)]
M_H2 = 2.01588e-3;                       % hydrogen molar mass [kg/mol]

%% Unit Conversions
T_local_K = T_local_C + 273.15;
T_std_K = T_std_C + 273.15;

P_final_Pa = P_final_barAbs * 1e5;
P0_Pa = P0_barAbs * 1e5;
P_std_Pa = P_std_barAbs * 1e5;

x_H2 = H2_volPct / 100;

%% Input Checks
assert(V_chamber_m3 > 0, 'V_chamber_m3 must be greater than zero.');
assert(T_local_K > 0, 'T_local_C leads to an invalid absolute temperature.');
assert(T_std_K > 0, 'T_std_C leads to an invalid absolute temperature.');
assert(P_final_Pa > 0, 'P_final_barAbs must be greater than zero.');
assert(P_std_Pa > 0, 'P_std_barAbs must be greater than zero.');
assert(all(x_H2 > 0 & x_H2 < 1), 'All hydrogen concentrations must be between 0 and 100 vol%%.');
assert(isnumeric(MFC_setpoint_std_LPM) && isscalar(MFC_setpoint_std_LPM), ...
    'MFC_setpoint_std_LPM must be a numeric scalar.');

%% Main Calculation
switch lower(char(fillMode))
    case 'vented'
        n_total_final_mol = P_final_Pa * V_chamber_m3 / (Ru * T_local_K);
        n_H2_mol = x_H2 .* n_total_final_mol;
        finalPressure_barAbs = P_final_barAbs * ones(size(x_H2));

    case 'sealed'
        n_air_initial_mol = P0_Pa * V_chamber_m3 / (Ru * T_local_K);
        n_H2_mol = (x_H2 ./ (1 - x_H2)) .* n_air_initial_mol;
        finalPressure_barAbs = P0_barAbs ./ (1 - x_H2);

    otherwise
        error('Unknown fillMode. Use "vented" or "sealed".');
end

%% Derived Quantities
m_H2_kg = n_H2_mol * M_H2;
m_H2_g = 1e3 * m_H2_kg;

V_H2_local_m3 = n_H2_mol * Ru * T_local_K ./ P_final_Pa;
V_H2_local_L = 1e3 * V_H2_local_m3;

V_H2_std_m3 = n_H2_mol * Ru * T_std_K ./ P_std_Pa;
V_H2_std_L = 1e3 * V_H2_std_m3;

if isfinite(MFC_setpoint_std_LPM) && MFC_setpoint_std_LPM > 0
    fillTime_min = V_H2_std_L ./ MFC_setpoint_std_LPM;
    fillTime_s = 60 * fillTime_min;
else
    fillTime_min = nan(size(x_H2));
    fillTime_s = nan(size(x_H2));
end

%% Results Table
resultHeaders = { ...
    'H2_volPct', ...
    'H2_fraction', ...
    'n_H2_mol', ...
    'm_H2_g', ...
    'V_H2_local_L', ...
    'V_H2_std_L', ...
    'FillTime_min', ...
    'FillTime_s', ...
    'FinalPressure_barAbs'};

resultMatrix = [ ...
    H2_volPct(:), ...
    x_H2(:), ...
    n_H2_mol(:), ...
    m_H2_g(:), ...
    V_H2_local_L(:), ...
    V_H2_std_L(:), ...
    fillTime_min(:), ...
    fillTime_s(:), ...
    finalPressure_barAbs(:)];

disp(' ');
disp('Hydrogen MFC fill calculation results:')

if exist('table', 'builtin') || exist('table', 'file')
    Results = table( ...
        H2_volPct(:), ...
        x_H2(:), ...
        n_H2_mol(:), ...
        m_H2_g(:), ...
        V_H2_local_L(:), ...
        V_H2_std_L(:), ...
        fillTime_min(:), ...
        fillTime_s(:), ...
        finalPressure_barAbs(:), ...
        'VariableNames', resultHeaders);
    disp(Results)
else
    Results.headers = resultHeaders;
    Results.data = resultMatrix;
    disp(strjoin(resultHeaders, ' | '))
    disp(resultMatrix)
end

%% Summary Messages
fprintf('\nInputs used:\n');
fprintf('  Chamber volume      : %.5f m^3\n', V_chamber_m3);
fprintf('  Local temperature   : %.2f degC\n', T_local_C);
fprintf('  Final pressure      : %.5f bar(a)\n', P_final_barAbs);
fprintf('  Fill mode           : %s\n', fillMode);
fprintf('  Standard reference  : %.2f degC and %.5f bar(a)\n', T_std_C, P_std_barAbs);

if isfinite(MFC_setpoint_std_LPM) && MFC_setpoint_std_LPM > 0
    fprintf('  MFC setpoint        : %.3f SLPM\n', MFC_setpoint_std_LPM);
    fprintf(['\nNote: filling time is based on the standard reference above. ', ...
        'Match it to the Alicat totalizer / SLPM convention before using it.\n']);
else
    fprintf('\nFill time not calculated because MFC_setpoint_std_LPM is NaN or <= 0.\n');
end

%% Plot
canPlot = true;

if exist('available_graphics_toolkits', 'builtin') || exist('available_graphics_toolkits', 'file')
    canPlot = ~isempty(available_graphics_toolkits());
end

if canPlot
    figure('Color', 'w');
    plot(H2_volPct, m_H2_g, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7);
    grid on
    xlabel('Hydrogen concentration [vol%]')
    ylabel('Required hydrogen mass [g]')
    title(sprintf('Required H2 Mass (%s mode)', fillMode))
else
    disp(' ');
    disp('Plot skipped because no graphics toolkit is available in this environment.')
end

%% Optional Export
% Uncomment if you want to save the result table next to this script.
% writetable(Results, 'H2_MFC_Fill_Calculator_Results.csv');
