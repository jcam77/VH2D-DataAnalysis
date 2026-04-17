function out = AuxFcn_BuildTensorFromTests_000(tests, fieldName)
% AuxFcn_BuildTensorFromTests_000
% Build a NaN-padded tensor for one DAQ stream across tests.
%
% fieldName: "DAQ1" or "DAQ2"
%
% Output:
%   out.testSignalTensor   [nTests x (1+maxCh) x maxSamples]  (time + channels)
%   out.validNSamples      [nTests x 1]
%   out.validNChannels     [nTests x 1]
%   out.fsByTest           [nTests x 1]
%   out.testNames          [nTests x 1] string
%   out.channelNamesByTest {nTests x 1} string arrays (actual channel names)
%   out.unitsByTest        {nTests x 1} string arrays (units per channel)

nTests = numel(tests);

nSamplesPerTest  = zeros(nTests,1);
nChannelsPerTest = zeros(nTests,1);
fsByTest = nan(nTests,1);
testNames = strings(nTests,1);

channelNamesByTest = cell(nTests,1);
unitsByTest        = cell(nTests,1);

for i = 1:nTests
    daq = tests(i).(fieldName);
    if isempty(daq)
        channelNamesByTest{i} = strings(1,0);
        unitsByTest{i}        = strings(1,0);
        continue;
    end

    nSamplesPerTest(i)  = daq.nSamples;
    nChannelsPerTest(i) = daq.nChannels;
    fsByTest(i)         = daq.fs;
    testNames(i)        = string(daq.name);

    channelNamesByTest{i} = string(daq.channelNames);
    if isfield(daq,'units')
        unitsByTest{i} = string(daq.units);
    else
        unitsByTest{i} = repmat("raw", 1, daq.nChannels);
    end
end

maxSamples  = max(nSamplesPerTest);
maxChannels = max(nChannelsPerTest);

testSignalTensor = nan(nTests, 1+maxChannels, maxSamples);

for i = 1:nTests
    daq = tests(i).(fieldName);
    if isempty(daq) || daq.nSamples==0 || daq.nChannels==0
        continue;
    end
    nS = daq.nSamples;
    nC = daq.nChannels;

    testSignalTensor(i, 1, 1:nS) = daq.t(:).';                 % time
    testSignalTensor(i, 2:(1+nC), 1:nS) = daq.signal(:,1:nC).'; % channels
end

out = struct();
out.testSignalTensor   = testSignalTensor;
out.validNSamples      = nSamplesPerTest;
out.validNChannels     = nChannelsPerTest;
out.fsByTest           = fsByTest;
out.testNames          = testNames;
out.channelNamesByTest = channelNamesByTest;
out.unitsByTest        = unitsByTest;
end
