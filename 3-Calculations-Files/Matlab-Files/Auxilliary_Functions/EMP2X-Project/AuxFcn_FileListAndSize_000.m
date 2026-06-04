function fileSizeTable = AuxFcn_FileListAndSize_000(folderName, varargin)
% AuxFcn_FileListAndSize_000  List files and sizes for a named folder.
%
%   T = AuxFcn_FileListAndSize_000() searches recursively from the current
%   working folder (pwd) for a directory named 'VH2D-Wk22', selects the
%   shallowest match, and returns a table T listing files (non-folders) in
%   that directory. By default the listing is non-recursive (files only in
%   the target folder).
%
%   T = AuxFcn_FileListAndSize_000(folderName) searches for folderName
%   instead of 'VH2D-Wk22'.
%
%   T = AuxFcn_FileListAndSize_000(..., 'Recursive', TF) when TF is true
%   performs a recursive listing of files inside the matched folder tree
%   (default: false).
%
%   T = AuxFcn_FileListAndSize_000(..., 'StartPath', P) begins the folder
%   search at path P instead of pwd.
%
%   Example usage:
%     % Search for 'VH2D-Wk22' starting at pwd, non-recursive
%     T = AuxFcn_FileListAndSize_000();
%
%     % Recursive listing of all files under the found folder
%     T = AuxFcn_FileListAndSize_000('VH2D-Wk22','Recursive',true);
%
%     % Search for a different folder name and start path
%     T = AuxFcn_FileListAndSize_000('MyDataFolder','StartPath','/Users/you/Data');
%
%   Output:
%     T is a table with variables:
%       - FullPath : full path to each file (string/cellstr)
%       - Bytes    : size in bytes (double)
%       - HumanSize: human-readable size (char)
%
%   Notes:
%     - If multiple folders with the requested name are found, the function
%       chooses the shallowest match (closest to StartPath) and issues a
%       warning. Change selection logic in the code if you prefer another rule.
%     - Hidden/system files (names beginning with '.') are included by
%       default. If you prefer to ignore dot-files, set 'Recursive' and
%       then filter the returned table, or modify the function to drop
%       entries whose names start with '.'.
%     - The function prints a short summary (table and total size) and
%       also returns the table for programmatic use.
%

% Defaults
if nargin < 1 || isempty(folderName)
    folderName = 'VH2D-Wk22';
end
p = inputParser;
addParameter(p, 'Recursive', false, @(x) islogical(x) || ismember(x,[0 1]));
addParameter(p, 'StartPath', pwd, @ischar);
parse(p, varargin{:});
isRecursive = p.Results.Recursive;
startPath = p.Results.StartPath;

% Find folders with the requested name (recursive)
searchPattern = fullfile(startPath, '**', folderName);
dirsFound = dir(searchPattern);
% Keep directories only
dirsFound = dirsFound([dirsFound.isdir]);

if isempty(dirsFound)
    error('Folder "%s" not found under start path: %s', folderName, startPath);
end

% If multiple matches, pick the one closest to startPath (shortest fullfile depth)
if numel(dirsFound) > 1
    fullPaths = arrayfun(@(d) fullfile(d.folder, d.name), dirsFound, 'UniformOutput', false);
    depths = cellfun(@(fp) numel(strfind(fp, filesep)), fullPaths);
    [~, idx] = min(depths); % shallowest match
    targetFolder = fullPaths{idx};
    warning('Multiple folders named "%s" found. Using: %s', folderName, targetFolder);
else
    targetFolder = fullfile(dirsFound.folder, dirsFound.name);
end

% List files (recursive if requested)
if isRecursive
    files = dir(fullfile(targetFolder, '**', '*'));
else
    files = dir(fullfile(targetFolder, '*'));
end
% Keep files only (drop directories)
files = files(~[files.isdir]);

if isempty(files)
    fprintf('No files found in folder: %s\n', targetFolder);
    fileSizeTable = table();
    return;
end

% Build table
fileNames = fullfile({files.folder}.', {files.name}.');
fileBytes = [files.bytes].';
fileSizeTable = table(fileNames, fileBytes, 'VariableNames', {'FullPath','Bytes'});

% Add human-readable sizes
fileSizeTable.HumanSize = arrayfun(@(b) AuxFcn_humanReadableBytes_000(b), fileSizeTable.Bytes, 'UniformOutput', false);

% Display summary
disp(fileSizeTable);
totalBytes = sum(fileSizeTable.Bytes);
fprintf('Total size of files (non-folders) in "%s": %s\n', targetFolder, AuxFcn_humanReadableBytes_000(totalBytes));

end

%% Helper function (kept local to the file)
function s = AuxFcn_humanReadableBytes_000(n)
if isempty(n) || isnan(n)
    s = 'N/A';
    return;
end
if n >= 1e9
    s = sprintf('%.2f GB', n/1e9);
elseif n >= 1e6
    s = sprintf('%.2f MB', n/1e6);
elseif n >= 1e3
    s = sprintf('%.2f kB', n/1e3);
else
    s = sprintf('%d B', n);
end
end
