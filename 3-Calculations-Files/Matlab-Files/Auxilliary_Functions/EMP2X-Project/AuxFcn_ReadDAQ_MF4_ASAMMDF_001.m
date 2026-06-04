function daqData = AuxFcn_ReadDAQ_MF4_ASAMMDF_001(filePath, options)
% AuxFcn_ReadDAQ_MF4_ASAMMDF_001
% Read MDF4/MF4 files through Python asammdf and return standard daqData.
%
% This reader is intended for MATLAB installations without Vehicle Network
% Toolbox. It calls AuxPy_ConvertMF4_ASAMMDF_001.py using MATLAB's pyenv
% Python executable, converts MDF channels to a temporary CSV, and
% reads that CSV back into MATLAB.
%
% Requirements:
%   pyenv must point to a Python where asammdf is installed.
%   Example:
%     /Library/Developer/CommandLineTools/usr/bin/python3 -m pip install --user asammdf

arguments
    filePath (1,1) {mustBeTextScalar}
    options.DaqId (1,1) string = "MF4-ASAMMDF"
    options.ChannelGroupIdx (1,1) double = 1
    options.ChannelNames = []
    options.ResampleFs (1,1) double = 0
    options.PythonExecutable (1,1) string = ""
    options.KeepConvertedFiles (1,1) logical = false
end

filePath = char(strtrim(filePath));
assert(exist(filePath, 'file') == 2, 'MF4 file not found: %s', filePath);

[~, baseName, ext] = fileparts(filePath);
fileName = string([baseName, ext]);

scriptPath = fullfile(fileparts(mfilename('fullpath')), ...
    "AuxPy_ConvertMF4_ASAMMDF_001.py");
assert(exist(scriptPath, 'file') == 2, ...
    'Python helper not found: %s', scriptPath);

pythonExe = localResolvePythonExecutable(options.PythonExecutable);

workDir = tempname;
mkdir(workDir);
csvPath = fullfile(workDir, "mf4_export.csv");
jsonPath = fullfile(workDir, "mf4_export.json");

cleanupObj = [];
if ~options.KeepConvertedFiles
    cleanupObj = onCleanup(@() localRemoveTempDir(workDir)); %#ok<NASGU>
end

channelArg = "";
if ~isempty(options.ChannelNames)
    channelArg = strjoin(string(options.ChannelNames), ",");
end

raster_s = 0;
if options.ResampleFs > 0
    raster_s = 1 / options.ResampleFs;
end

cmd = strjoin([ ...
    localShellQuote(pythonExe), ...
    localShellQuote(scriptPath), ...
    "--input", localShellQuote(filePath), ...
    "--output-csv", localShellQuote(csvPath), ...
    "--output-json", localShellQuote(jsonPath), ...
    "--group-index", string(options.ChannelGroupIdx - 1), ...
    "--raster", string(raster_s), ...
    "--channels", localShellQuote(channelArg) ...
    ], " ");

[status, output] = system(cmd);
assert(status == 0, ...
    'asammdf MF4 conversion failed for "%s":\n%s', fileName, output);

tbl = readtable(csvPath, 'VariableNamingRule', 'preserve');
assert(width(tbl) >= 2, ...
    'asammdf export from "%s" did not contain signal channels.', fileName);

t = tbl{:, 1};
signalMat = tbl{:, 2:end};
channelNames = string(tbl.Properties.VariableNames(2:end));

[dt, fs, isNonUniform, dtStd] = localEstimateTiming(t);

daqData = struct();
daqData.fileName = fileName;
daqData.filePath = string(filePath);
daqData.daqId = string(options.DaqId);
daqData.dt = dt;
daqData.fs = fs;
daqData.t = t(:);
daqData.signal = signalMat;
daqData.nSamples = height(tbl);
daqData.nChannels = size(signalMat, 2);
daqData.channelNames = reshape(channelNames, 1, []);
daqData.units = repmat("raw", 1, daqData.nChannels);
daqData.channelType = repmat("unknown", 1, daqData.nChannels);
daqData.tbl = tbl;

daqData.meta = struct();
daqData.meta.reader = "asammdf";
daqData.meta.channelGroupIdx = options.ChannelGroupIdx;
daqData.meta.resampleFs = options.ResampleFs;
daqData.meta.isNonUniform = isNonUniform;
daqData.meta.dtStd = dtStd;
daqData.meta.convertedCsvPath = string(csvPath);
daqData.meta.convertedJsonPath = string(jsonPath);

if exist(jsonPath, 'file') == 2
    try
        daqData.meta.asammdf = jsondecode(fileread(jsonPath));
    catch
        daqData.meta.asammdf = struct();
    end
end

end

function pythonExe = localResolvePythonExecutable(pythonExe)
if strlength(pythonExe) > 0
    pythonExe = char(pythonExe);
    assert(exist(pythonExe, 'file') == 2, ...
        'Python executable not found: %s', pythonExe);
    return;
end

try
    pe = pyenv;
    pythonExe = char(pe.Executable);
catch
    pythonExe = "";
end

if isempty(pythonExe)
    pythonExe = "python3";
end
end

function quoted = localShellQuote(value)
value = string(value);
quoted = "'" + replace(value, "'", "'\''") + "'";
end

function localRemoveTempDir(pathToRemove)
if exist(pathToRemove, 'dir') == 7
    try
        rmdir(pathToRemove, 's');
    catch
    end
end
end

function [dt, fs, isNonUniform, dtStd] = localEstimateTiming(t)
t = t(:);
dtVec = diff(t);
dtVec = dtVec(isfinite(dtVec) & dtVec > 0);

if isempty(dtVec)
    dt = NaN;
    fs = NaN;
    dtStd = NaN;
    isNonUniform = true;
    return;
end

dt = mean(dtVec);
fs = 1 / dt;
dtStd = std(dtVec);
isNonUniform = (dtStd / dt) > 0.01;
end
