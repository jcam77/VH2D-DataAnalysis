% Code to plot simulation results from OpAmpCircuitInvertingAmplifier

% Copyright 2015 The MathWorks, Inc.

% Reuse figure if it exists, else create new figure
try
    figure(h1_OpAmpCircuitInvertingAmplifier)
catch
    h1_OpAmpCircuitInvertingAmplifier=figure('Name', 'OpAmpCircuitInvertingAmplifier');
end

% Generate simulation results if they don't exist
if(~exist('simlog_OpAmpCircuitInvertingAmplifier','var'))
    sim('OpAmpCircuitInvertingAmplifier')
end

% Get simulation results
temp_vin = simlog_OpAmpCircuitInvertingAmplifier.AC_Voltage.v.series;
temp_vout = simlog_OpAmpCircuitInvertingAmplifier.Sensor_Vout.Voltage_Sensor.V.series;

% Plot results
plot(temp_vin.time,temp_vin.values,'LineWidth',1);
hold on
plot(temp_vout.time,temp_vout.values,'LineWidth',1);
hold off
text(0.1e-3,0.9,'Gain of Circuit:');
text(0.1e-3,0.8,sprintf('%s %2.2f','-R2/R1 =',-max(temp_vout.values)/max(temp_vin.values)));
grid on
title('Inverting Op-Amp Circuit Voltages');
ylabel('Voltage (V)');
xlabel('Time (s)');
legend({'Input','Output'},'Location','Best');

% Remove temporary variables
clear temp_vin temp_vout