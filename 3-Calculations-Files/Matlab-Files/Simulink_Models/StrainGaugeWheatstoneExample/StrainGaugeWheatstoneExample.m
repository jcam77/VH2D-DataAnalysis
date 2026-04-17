%% Strain Gauge and Wheatstone Bridge
% 
% This model shows how to model a strain gauge and measurement amplifier.
% The strain gauge forms one leg of a Wheatstone bridge, which is connected
% to a differential amplifier. A second op-amp is then used to both amplify
% and apply a low-pass filter to the measurement signal. The op-amps are
% modeled at a system level, with the user specifying parameters such as
% open-loop bandwidth, gain and maximum slew rate. In this circuit, the
% dynamics are primarily set by the low-pass filter. The op-amp bandwidth
% and maximum slew rate have little impact on the step response.
% 
% 

% Copyright 2008-2023 The MathWorks, Inc.



%% Model

open_system('StrainGaugeWheatstone')

set_param(find_system('StrainGaugeWheatstone','FindAll', 'on','type','annotation','Tag','ModelFeatures'),'Interpreter','off')

%% Simulation Results from Simscape Logging
%%
%
% This code plots the actual and measured strain from the model of
% StrainGaugeWheatstone resulting from two tests.  The first test sets the
% resistor and capacitor in the low pass filter to the maximum value of
% their tolerance ranges.  The second test sets the values for those
% components to the minimum of their tolerance ranges. The plot shows the
% effects this has on the strain measurement.
%


StrainGaugeWheatstonePlotTime;

%% Results from Real-Time Simulation
%%
%
% This example has been tested on a Speedgoat Performance real-time target 
% machine with an Intel(R) 3.5 GHz i7 multi-core CPU. This model can run 
% in real time with a step size of 50 microseconds.

%%

