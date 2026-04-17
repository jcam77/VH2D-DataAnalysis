function helperFilterIntroductionPlot2(t,drift,v1,v2,a1,a2)
%helperFilterIntroductionPlot2 Helper function for FilterIntroductionExample.m example

% Copyright 2012 The MathWorks, Inc.

figure
plot(t,drift)
xlabel('Time in seconds')
ylabel('Displacement (cm)')
axis([120 122 -1 1])
grid on

% Plot a few data points to see the difference between the speed
% measurements
figure
plot(t,v1);
hold on
plot(t,v2,'r');
xlabel('Time in seconds')
ylabel('speed (cm/s)')
legend('Estimated speed using diff',...
  'Estimated speed using FIR filter','location','southwest')
axis([120 122 -50 50])
grid on

% Plot a few data points to see the difference between the acceleration
% measurements
figure
plot(t,a1);
hold on
plot(t,a2,'r');
xlabel('Time in seconds')
ylabel('acceleration (cm/s^2)')
legend('Estimated acceleration using diff',...
  'Estimated acceleration using FIR filter','location','southwest')
axis([120 122 -3000 2200])
grid on
