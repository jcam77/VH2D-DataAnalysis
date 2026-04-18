function Results = AuxFcn_H2_MFC_FillCalculator_000(V_chamber_m3, T_local_K, P_final_Pa, H2_volPct, fillMode, P0_Pa, T_std_K, P_std_Pa, MFC_setpoint_std_m3_s, makePlot)
% AuxFcn_H2_MFC_FillCalculator_000
% Estimate the hydrogen amount required to reach target chamber
% concentrations and, optionally, estimate filling time from the Alicat MFC
% setpoint expressed in standardized cubic meters per second.
%
% Inputs
%   V_chamber_m3          chamber free volume [m^3], scalar or per-test vector
%   T_local_K             local gas temperature [K], scalar or per-test vector
%   P_final_Pa            final absolute pressure [Pa], scalar or per-test vector
%   H2_volPct             target hydrogen concentration(s) [vol%]
%   fillMode              "vented" or "sealed"
%   P0_Pa                 initial chamber pressure [Pa], scalar or per-test vector
%   T_std_K               standard temperature [K]
%   P_std_Pa              standard absolute pressure [Pa]
%   MFC_setpoint_std_m3_s MFC setpoint [m^3/s at standard conditions], scalar
%                         or per-test vector, use NaN to skip fill time
%   makePlot              logical flag, true to generate a plot
%
% Output
%   Results               struct with inputs, vectors, and optional table

if nargin < 10 || isempty(makePlot)
    makePlot = true;
end
if nargin < 9 || isempty(MFC_setpoint_std_m3_s)
    MFC_setpoint_std_m3_s = NaN;
end
if nargin < 8 || isempty(P_std_Pa)
    P_std_Pa = 101325;
end
if nargin < 7 || isempty(T_std_K)
    T_std_K = 298.15;
end
if nargin < 6 || isempty(P0_Pa)
    P0_Pa = 101325;
end
if nargin < 5 || isempty(fillMode)
    fillMode = 'vented';
end

Ru = 8.314462618;                        % universal gas constant [J/(mol*K)]
M_H2 = 2.01588e-3;                       % hydrogen molar mass [kg/mol]

H2_volPct = H2_volPct(:);
nCases = numel(H2_volPct);

V_chamber_m3 = i_expandToCases(V_chamber_m3, nCases, 'V_chamber_m3');
T_local_K = i_expandToCases(T_local_K, nCases, 'T_local_K');
P_final_Pa = i_expandToCases(P_final_Pa, nCases, 'P_final_Pa');
P0_Pa = i_expandToCases(P0_Pa, nCases, 'P0_Pa');
MFC_setpoint_std_m3_s = i_expandToCases(MFC_setpoint_std_m3_s, nCases, 'MFC_setpoint_std_m3_s');

x_H2 = H2_volPct / 100;

assert(all(V_chamber_m3 > 0), 'V_chamber_m3 must be greater than zero.');
assert(all(T_local_K > 0), 'T_local_K must be greater than zero.');
assert(T_std_K > 0, 'T_std_K must be greater than zero.');
assert(all(P_final_Pa > 0), 'P_final_Pa must be greater than zero.');
assert(P_std_Pa > 0, 'P_std_Pa must be greater than zero.');
assert(all(x_H2 > 0 & x_H2 < 1), 'All hydrogen concentrations must be between 0 and 100 vol%%.');
assert(all(P0_Pa > 0), 'P0_Pa must be greater than zero.');

switch lower(char(fillMode))
    case 'vented'
        n_total_final_mol = (P_final_Pa .* V_chamber_m3) ./ (Ru .* T_local_K);
        n_H2_mol = x_H2 .* n_total_final_mol;
        finalPressure_Pa = P_final_Pa;

    case 'sealed'
        n_air_initial_mol = (P0_Pa .* V_chamber_m3) ./ (Ru .* T_local_K);
        n_H2_mol = (x_H2 ./ (1 - x_H2)) .* n_air_initial_mol;
        finalPressure_Pa = P0_Pa ./ (1 - x_H2);

    otherwise
        error('Unknown fillMode. Use "vented" or "sealed".');
end

m_H2_kg = n_H2_mol * M_H2;

V_H2_local_m3 = (n_H2_mol .* Ru .* T_local_K) ./ P_final_Pa;
V_H2_std_m3 = (n_H2_mol .* Ru .* T_std_K) ./ P_std_Pa;
MFC_setpoint_SLPM = MFC_setpoint_std_m3_s * 60 * 1e3;

injectionTime_min = nan(size(x_H2));
injectionTime_s = 60 * injectionTime_min;
validSetpoint = isfinite(MFC_setpoint_std_m3_s) & MFC_setpoint_std_m3_s > 0;
injectionTime_s(validSetpoint) = V_H2_std_m3(validSetpoint) ./ MFC_setpoint_std_m3_s(validSetpoint);
injectionTime_min(validSetpoint) = injectionTime_s(validSetpoint) / 60;

resultHeaders = { ...
    'V_chamber_m3', ...
    'T_local_K', ...
    'P_final_Pa', ...
    'H2_volPct', ...
    'H2_fraction', ...
    'n_H2_mol', ...
    'm_H2_kg', ...
    'V_H2_local_m3', ...
    'V_H2_std_m3', ...
    'MFC_setpoint_std_m3_s', ...
    'MFC_setpoint_SLPM', ...
    'InjectionTime_s', ...
    'InjectionTime_min', ...
    'FinalPressure_Pa'};

resultMatrix = [ ...
    V_chamber_m3(:), ...
    T_local_K(:), ...
    P_final_Pa(:), ...
    H2_volPct(:), ...
    x_H2(:), ...
    n_H2_mol(:), ...
    m_H2_kg(:), ...
    V_H2_local_m3(:), ...
    V_H2_std_m3(:), ...
    MFC_setpoint_std_m3_s(:), ...
    MFC_setpoint_SLPM(:), ...
    injectionTime_s(:), ...
    injectionTime_min(:), ...
    finalPressure_Pa(:)];

Results = struct();
Results.inputs = struct( ...
    'V_chamber_m3', V_chamber_m3, ...
    'T_local_K', T_local_K, ...
    'P_final_Pa', P_final_Pa, ...
    'H2_volPct', H2_volPct, ...
    'fillMode', char(fillMode), ...
    'P0_Pa', P0_Pa, ...
    'T_std_K', T_std_K, ...
    'P_std_Pa', P_std_Pa, ...
    'MFC_setpoint_std_m3_s', MFC_setpoint_std_m3_s);
Results.headers = resultHeaders;
Results.data = resultMatrix;
Results.V_chamber_m3 = V_chamber_m3(:);
Results.T_local_K = T_local_K(:);
Results.P_final_Pa = P_final_Pa(:);
Results.H2_volPct = H2_volPct(:);
Results.H2_fraction = x_H2(:);
Results.n_H2_mol = n_H2_mol(:);
Results.m_H2_kg = m_H2_kg(:);
Results.V_H2_local_m3 = V_H2_local_m3(:);
Results.V_H2_std_m3 = V_H2_std_m3(:);
Results.MFC_setpoint_std_m3_s = MFC_setpoint_std_m3_s(:);
Results.MFC_setpoint_SLPM = MFC_setpoint_SLPM(:);
Results.InjectionTime_s = injectionTime_s(:);
Results.InjectionTime_min = injectionTime_min(:);
Results.FillTime_s = injectionTime_s(:);
Results.FillTime_min = injectionTime_min(:);
Results.FinalPressure_Pa = finalPressure_Pa(:);

if exist('table', 'builtin') || exist('table', 'file')
    Results.table = table( ...
        Results.V_chamber_m3, ...
        Results.T_local_K, ...
        Results.P_final_Pa, ...
        Results.H2_volPct, ...
        Results.H2_fraction, ...
        Results.n_H2_mol, ...
        Results.m_H2_kg, ...
        Results.V_H2_local_m3, ...
        Results.V_H2_std_m3, ...
        Results.MFC_setpoint_std_m3_s, ...
        Results.MFC_setpoint_SLPM, ...
        Results.InjectionTime_s, ...
        Results.InjectionTime_min, ...
        Results.FinalPressure_Pa, ...
        'VariableNames', resultHeaders);
end

if makePlot
    canPlot = true;
    if exist('available_graphics_toolkits', 'builtin') || exist('available_graphics_toolkits', 'file')
        canPlot = ~isempty(available_graphics_toolkits());
    end

    if canPlot
        figure('Color', 'w');
        plot(H2_volPct, m_H2_kg, 'o-', 'LineWidth', 1.5, 'MarkerSize', 7);
        grid on
        xlabel('Hydrogen concentration [vol%]')
        ylabel('Required hydrogen mass [kg]')
        title(sprintf('Required H2 Mass (%s mode)', fillMode))
    end
end

end

function values = i_expandToCases(values, nCases, varName)
values = values(:);
assert(isnumeric(values), '%s must be numeric.', varName);

if isscalar(values)
    values = repmat(values, nCases, 1);
elseif numel(values) ~= nCases
    error('%s must be a scalar or have the same length as H2_volPct.', varName);
end
end
