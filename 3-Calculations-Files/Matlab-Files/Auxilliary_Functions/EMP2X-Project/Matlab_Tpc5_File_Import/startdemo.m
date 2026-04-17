% Matlab Example, read multiple traces from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2018-03-12, Thomas Berger
% Description:
% This example shows how to read and plot traces from a TPC5 file

% Filename and path to Elsys tpc5 file
filename = 'mytrace.tpc5';

% Read number of traces and channel information
nTraces= tpc5Info(filename);

% loop through each channel
for n = 1:nTraces
    % one single trace
    [x, y, traceInfo] = tpc5Trace(filename, n);
    
    % build an array with all Y values
    C(n,:)=y;
    opt(n,:)=traceInfo;
end

% plot all traces into one plot
tpc5Plot(x, C, opt, nTraces, 1, true);

% plot traces in areas
tpc5Plot(x, C, opt, nTraces, 2, false);
