% Matlab Example, read data from tpc5 file
% Copyright: 2018 Elsys AG
% Author: 2011-01-18, R. Bertschi
% Rev. 2018-03-12, Thomas Berger
% Description:
% This example shows how to read one trace from a TPC5 file
% and the conversion to physical values

function [timeAxis, dataPhysical, traceInfo] = tpc5Trace(filename, nr)

% clear data arrays
clear timeAxis;
clear dataPhysical;
clear traceInfo;

% strings to hd5 path, access data
StrTpc5Chn = strcat('/measurements/00000001/channels/', sprintf('%08d',nr));
StrTpc5Blk = strcat(StrTpc5Chn, '/blocks/00000001/');
tpc5ChnRaw = strcat(StrTpc5Chn, '/blocks/00000001/raw');

% Read out channel settings for the first channel
% Digital marker signals are a part of the binary measurement values.
% For separating digital from analog values the following two
% bit masks are needed
analogMask = uint16( h5readatt(filename,StrTpc5Chn, 'analogMask'));
markerMask = uint16( h5readatt(filename,StrTpc5Chn, 'markerMask'));


% Measurement values are stored as they are coming from the A/D converter.
% For getting voltage values or scaled physical values the corresponding
% conversion values must be read out.
% Conversion factor for scaling to voltage values
binToVoltFactor         = h5readatt(filename,StrTpc5Chn, 'binToVoltFactor');
binToVoltConstant       = h5readatt(filename,StrTpc5Chn, 'binToVoltConstant');
% Conversion factor for scaling to physical values
voltToPhysicalFactor    = h5readatt(filename,StrTpc5Chn, 'voltToPhysicalFactor');
voltToPhysicalConstant  = h5readatt(filename,StrTpc5Chn, 'voltToPhysicalConstant');

% Read out the data from the first channel, first block
data = h5read(filename, tpc5ChnRaw);
% Mask out the digital marker bits
analogData = bitand(data,analogMask);

% Scale data to voltage values
dbData = cast(analogData,'double');
dataScaled = cast((dbData * binToVoltFactor) + binToVoltConstant,'double');

% Scale data to physical values
dataPhysical = (dataScaled * voltToPhysicalFactor) + voltToPhysicalConstant;



% Recording parameters
sampleRate  = h5readatt(filename,StrTpc5Blk, 'sampleRateHertz');
triggerSample = h5readatt(filename,StrTpc5Blk, 'triggerSample');

% number of samples
nSamples = length(dataPhysical);
% time between each sample
tSample = double(1/sampleRate);

% Trigger position
tTrigger = double (triggerSample) * double(tSample);

% Recording length
tRecord = nSamples * tSample;
tBegin = -tTrigger;
tEnd = tRecord - tTrigger;

% X-axis (time)
timeAxis = linspace(tBegin, tEnd, nSamples)';

% create struct with trace information
traceInfo.name = readAttributeAsString(filename,StrTpc5Chn, 'name');  % returns name of channel as string
traceInfo.physicalUnit = readAttributeAsString(filename,StrTpc5Chn, 'physicalUnit');  % returns physicalUnit as string
traceInfo.sampleRateHertz  = h5readatt(filename,StrTpc5Blk, 'sampleRateHertz');
traceInfo.triggerSample = h5readatt(filename,StrTpc5Blk, 'triggerSample');
traceInfo.nSamples = nSamples;

return

function attrValue = readAttributeAsString(filename, loc, attr)
    tmp = h5readatt(filename, loc, attr); % returns type 'cell' before R2020a
    if iscell(tmp)
        attrValue = tmp{1};
    else
        attrValue = tmp;
    end
return 

