function helperFilterIntroductionPlot3(t,drift,dest,v,vest)
%helperFilterIntroductionPlot3 Helper function for FilterIntroductionExample.m example

% Copyright 2012 The MathWorks, Inc.

figure
subplot(2,1,1)
plot(t,dest)
hold on
plot(t,drift,':','LineWidth',1.5)
ylabel('Displacement (cm)')
legend('Leaky integrator estimate',...
  'Original displacement','location','southeast')
axis([120 122 -1 1])
grid on
subplot(2,1,2)
plot(t,vest)
hold on
plot(t,v,':','LineWidth',1.5)
ylabel('Speed (cm/s)')
legend('Leaky integrator estimate',...
  'Original speed','location','southeast')
axis([120 122 -50 50])
grid on
xlabel('Time in seconds')
