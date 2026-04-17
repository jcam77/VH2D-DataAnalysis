%% Op-Amp Circuit - Inverting Amplifier
% 
% This model shows a standard inverting op-amp circuit. The gain is given
% by -R2/R1, and with the values set to R1=1K Ohm and R2=10K Ohm, the 0.1V
% peak-to-peak input voltage is amplified to 1V peak-to-peak. As the Op-Amp
% block implements an ideal (i.e. infinite gain) device, this gain is
% achieved regardless of output load.
% 
% 
% Copyright 2008-2015 The MathWorks, Inc.



%% Model

open_system('OpAmpCircuitInvertingAmplifier')

set_param(find_system(bdroot,'FindAll','on','type','annotation','Tag','ModelFeatures'),'Interpreter','off');

%% Simulation Results from Simscape Logging

OpAmpCircuitInvertingAmplifierPlotV;

%%

