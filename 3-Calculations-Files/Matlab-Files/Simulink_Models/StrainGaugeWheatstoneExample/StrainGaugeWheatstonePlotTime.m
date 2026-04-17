% Code to plot simulation results from StrainGaugeWheatstone
%% Plot Description:
%
% This code plots the actual and measured strain from the model of
% StrainGaugeWheatstone resulting from two tests.  The first test sets the
% resistor and capacitor in the low pass filter to the maximum value of
% their tolerance ranges.  The second test sets the values for those
% components to the minimum of their tolerance ranges. The plot shows the
% effects this has on the strain measurement.

% Copyright 2016-2023 The MathWorks, Inc.

% Generate new simulation results if they don't exist or if they need to be updated
if ~exist('simlog_StrainGaugeWheatstone', 'var') || ...
        simlogNeedsUpdate(simlog_StrainGaugeWheatstone, 'StrainGaugeWheatstone') 
    sim('StrainGaugeWheatstone')
    % Model StopFcn callback adds a timestamp to the Simscape simulation data log
end

% Reuse figure if it exists, else create new figure
if ~exist('h1_StrainGaugeWheatstone', 'var') || ...
        ~isgraphics(h1_StrainGaugeWheatstone, 'figure')
    h1_StrainGaugeWheatstone = figure('Name', 'StrainGaugeWheatstone');
end
figure(h1_StrainGaugeWheatstone)
clf(h1_StrainGaugeWheatstone)

% Get simulation results
% Max Tolerance
set_param([bdroot '/Capacitor'],'enable_C_tol','2');
set_param([bdroot '/R9'],'enable_R_tol','2');
sim(bdroot);
simlog_prSensorMaxTol = logsout_StrainGaugeWheatstone.get('Pr_Signal');

% Min Tolerance
set_param([bdroot '/Capacitor'],'enable_C_tol','3');
set_param([bdroot '/R9'],'enable_R_tol','3');
sim(bdroot);
simlog_prSensorMinTol = logsout_StrainGaugeWheatstone.get('Pr_Signal');

% Nominal Value
set_param([bdroot '/Capacitor'],'enable_C_tol','0');
set_param([bdroot '/R9'],'enable_R_tol','0');

% Plot results
plot(simlog_prSensorMinTol.Values.Time, simlog_prSensorMinTol.Values.Data(:,1), 'k','LineWidth', 1)
hold on
plot(simlog_prSensorMaxTol.Values.Time, simlog_prSensorMaxTol.Values.Data(:,2), 'LineWidth', 1)
plot(simlog_prSensorMinTol.Values.Time, simlog_prSensorMinTol.Values.Data(:,2), 'LineWidth', 1)
hold off
grid on
title('Actual and Sensed Strain')
ylabel('Strain')
legend({'Actual Strain', 'Max Tolerance','Min Tolerance'},'Location','Best');

xlabel('Time (s)');

% Remove temporary variables
clear simlog_t simlog_handles
clear simlog_prSensorMinTol simlog_prSensorMaxTol
