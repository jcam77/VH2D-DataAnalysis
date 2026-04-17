function daqData = AuxFcn_ReadTPC5_001(fileName, varargin)
% AuxFcn_ReadTPC5_001
% Read all channels from a TPC5 (HDF5) file and return a standardized DAQ struct.
%
% Output fields:
%   daqData.fileName, daqData.filePath, daqData.daqId
%   daqData.dt, daqData.fs
%   daqData.t         (Nx1) time [s]
%   daqData.signal    (NxM) channels (physical units using scaling attributes)
%   daqData.nSamples, daqData.nChannels
%   daqData.channelNames (1xM)
%   daqData.units        (1xM)
%   daqData.meta         (struct)
%
% Options:
%   'MeasurementId'        : e.g. "00000001" (default: first measurement group)
%   'DaqId'                : string label, e.g. "DAQ2"
%   'UseTriggerTimeZero'   : true => time zero at triggerSample (default)
%
% USAGE / EXAMPLES:
%   % Basic read (first measurement group)
% daq2 = AuxFcn_ReadTPC5_001('mytrace.tpc5', 'DaqId',"DAQ2");
% plot(daq2.t, daq2.signal(:,1)); grid on;
% title(char(daq2.channelNames(1)), 'Interpreter','none');
%
%   % Specify measurement id explicitly
%   daq2 = AuxFcn_ReadTPC5_001('Test_001_DAQ2.tpc5', ...
%       'MeasurementId',"00000001", 'DaqId',"DAQ2");
%
%   % Keep time starting at 0 instead of trigger-aligned
%   daq2 = AuxFcn_ReadTPC5_001('Test_001_DAQ2.tpc5', ...
%       'UseTriggerTimeZero', false, 'DaqId',"DAQ2");

% UPDATES in _001:
% - Renamed input argument to 'fileName'.
% - Standardized output fields: 'fileName' (input name) and 'filePath' (resolved absolute path).

p = inputParser;
p.addRequired('fileName', @(x) ischar(x) || isstring(x));
p.addParameter('MeasurementId', "", @(x) ischar(x) || isstring(x));
p.addParameter('DaqId', "", @(x) ischar(x) || isstring(x));
p.addParameter('UseTriggerTimeZero', true, @(x) islogical(x) && isscalar(x));
p.parse(fileName, varargin{:});
opt = p.Results;

fileName = string(fileName);
thisFile = which(fileName);
if isempty(thisFile)
    thisFile = char(fileName);
    assert(exist(thisFile,'file')==2, 'TPC5 file not found: %s', fileName);
end

% Resolve measurement group
measRoot = "/measurements";
measInfo = h5info(thisFile, measRoot);
assert(~isempty(measInfo.Groups), 'No measurements found in %s', thisFile);

if strlength(string(opt.MeasurementId)) > 0
    measPath = measRoot + "/" + string(opt.MeasurementId);
else
    measPath = string(measInfo.Groups(1).Name);
end

channelsPath = measPath + "/channels";
chInfo = h5info(thisFile, channelsPath);
nCh = numel(chInfo.Groups);
assert(nCh >= 1, 'No channels found in %s', channelsPath);

channelNames = strings(1,nCh);
units = strings(1,nCh);

Ycell = cell(1,nCh);
Fs_vec = nan(1,nCh);
tCell = cell(1,nCh);

for iCh = 1:nCh
    chPath = string(chInfo.Groups(iCh).Name);

    analogMask = uint16(h5readatt(thisFile, chPath, 'analogMask'));

    binToVoltFactor         = double(h5readatt(thisFile, chPath, 'binToVoltFactor'));
    binToVoltConstant       = double(h5readatt(thisFile, chPath, 'binToVoltConstant'));
    voltToPhysicalFactor    = double(h5readatt(thisFile, chPath, 'voltToPhysicalFactor'));
    voltToPhysicalConstant  = double(h5readatt(thisFile, chPath, 'voltToPhysicalConstant'));

    channelNames(iCh) = string(readAttrAsString(thisFile, chPath, 'name'));
    units(iCh)        = string(readAttrAsString(thisFile, chPath, 'physicalUnit'));

    blkPathRoot = chPath + "/blocks";
    blkInfo = h5info(thisFile, blkPathRoot);
    blkGroups = blkInfo.Groups;
    assert(~isempty(blkGroups), 'No blocks found for channel %s', chPath);

    yAll = [];
    tAll = [];
    sampleCursor = 0;
    Fs_here = [];
    triggerSample_first = [];

    for iBlk = 1:numel(blkGroups)
        blkPath = string(blkGroups(iBlk).Name);

        Fs_blk = double(h5readatt(thisFile, blkPath, 'sampleRateHertz'));
        Fs_here(end+1) = Fs_blk; %#ok<AGROW>

        if isempty(triggerSample_first)
            try
                triggerSample_first = double(h5readatt(thisFile, blkPath, 'triggerSample'));
            catch
                triggerSample_first = 0;
            end
        end

        rawPath = blkPath + "/raw";
        data = h5read(thisFile, rawPath);

        analogData = bitand(uint16(data), analogMask);
        dbData = double(analogData);

        volts = (dbData .* binToVoltFactor) + binToVoltConstant;
        phys  = (volts .* voltToPhysicalFactor) + voltToPhysicalConstant;

        nS = numel(phys);

        if opt.UseTriggerTimeZero
            tBlk = ((0:nS-1)' + sampleCursor - triggerSample_first) ./ Fs_blk;
        else
            tBlk = ((0:nS-1)' + sampleCursor) ./ Fs_blk;
        end

        yAll = [yAll; phys(:)]; %#ok<AGROW>
        tAll = [tAll; tBlk];    %#ok<AGROW>
        sampleCursor = sampleCursor + nS;
    end

    if max(Fs_here) - min(Fs_here) > 0
        warning('TPC5: channel %d has varying Fs across blocks. Using Fs from first block.', iCh);
    end

    Fs_vec(iCh) = Fs_here(1);
    Ycell{iCh} = yAll;
    tCell{iCh} = tAll;
end

nSmin = min(cellfun(@numel, Ycell));
if any(cellfun(@numel, Ycell) ~= nSmin)
    warning('TPC5: channels have different sample counts. Truncating to min length = %d.', nSmin);
end

Y = nan(nSmin, nCh);
for iCh = 1:nCh
    Y(:,iCh) = Ycell{iCh}(1:nSmin);
end
t = tCell{1}(1:nSmin);

fs_i = Fs_vec(1);
dt_i = 1/fs_i;

% ---------- Outputs ----------
daqData = struct();

% Renamed fields for readability and transparency
[~, fName, fExt] = fileparts(fileName);
daqData.fileName = string(fName) + string(fExt); % e.g., "mytrace.tpc5"
daqData.filePath = string(thisFile);             % The full absolute path
daqData.daqId = string(opt.DaqId);

daqData.dt = dt_i;
daqData.fs = fs_i;

daqData.t = t(:);
daqData.signal = Y;
daqData.nSamples = nSmin;
daqData.nChannels = nCh;

daqData.channelNames = channelNames;
daqData.units = units;

daqData.meta = struct();
daqData.meta.measurementPath = measPath;
daqData.meta.useTriggerTimeZero = opt.UseTriggerTimeZero;

end

function attrValue = readAttrAsString(filename, loc, attr)
tmp = h5readatt(filename, loc, attr);
if iscell(tmp)
    attrValue = tmp{1};
else
    attrValue = tmp;
end
end
